import { parseEther as eth, MaxUint256 } from 'ethers';
import { MintableERC20, MockV3Aggregator, Pool } from '../../../types';
import { deployPool, RAY } from '../fixtures/pool';
import { expect } from 'chai';
import { time } from '@nomicfoundation/hardhat-network-helpers';

import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('Pool - Liquidity Index', () => {
  let pool: Pool;
  let tokenA: MintableERC20;
  let deployer: SignerWithAddress;
  let oracleA: MockV3Aggregator;

  beforeEach(async () => {
    const fixture = await deployPool();
    ({ tokenA, pool, owner: deployer, oracleA } = fixture);

    // mint some tokens and give approval
    await tokenA.mint(deployer.address, eth('10'));
    await tokenA.approve(pool.target, eth('3'));
  });

  describe('basic checks', () => {
    it('liquidity & borrow index for a new reserve should be set to 1 ray', async () => {
      const reserve = await pool.getReserveData(tokenA.target);
      expect(reserve.liquidityIndex).eq(RAY);
      expect(reserve.borrowIndex).eq(RAY);
    });

    it('liquidity rate for a new reserve should be 0', async () => {
      const reserve = await pool.getReserveData(tokenA.target);
      expect(reserve.liquidityRate).eq(0);
    });

    it('after supplying, and waiting for some time, liquidity index should not change', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await time.increase(86400); // one day
      const reserve = await pool.getReserveData(tokenA.target);
      expect(reserve.liquidityIndex).eq(RAY);
    });

    it('after supplying, and waiting for some time; balances should not change', async () => {
      const balBefore = await pool.getBalance(tokenA.target, deployer.address, 0);

      await pool.supplySimple(tokenA.target, deployer.address, 2, 0);

      const balAfter = await pool.getBalance(tokenA.target, deployer.address, 0);
      await time.increase(86400); // one day
      const balAfterDay = await pool.getBalance(tokenA.target, deployer.address, 0);

      // Supply again
      await pool.supplySimple(tokenA.target, deployer.address, 2, 0);
      const finalBalance = await pool.getBalance(tokenA.target, deployer.address, 0);

      expect(balBefore).eq(0);
      expect(balAfter).eq(2);
      expect(balAfter).eq(balAfterDay);
      expect(finalBalance).eq(4);
    });

    it('borrowing should increase borrow and liquidity index', async () => {
      const before = await pool.getReserveData(tokenA.target);

      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);
      await time.increase(86400); // one day

      // trigger a borrow to force increase the borrow index
      await oracleA.updateRoundTimestamp();
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.1'), 0);

      const after = await pool.getReserveData(tokenA.target);

      expect(after.borrowIndex).greaterThan(RAY);
      expect(after.liquidityIndex).greaterThan(RAY);
      expect(after.liquidityRate).greaterThan(before.liquidityRate);
      expect(after.liquidityRate).greaterThan(0);
    });
  });

  it('after supplying and some borrowing, liquidity index should increase after some time', async () => {
    await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
    await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

    const reserveBefore = await pool.getReserveData(tokenA.target);
    await time.increase(86400 * 2000); // 2000 days

    await pool.repaySimple(tokenA.target, eth('0.01'), 0);
    const reserveAfter = await pool.getReserveData(tokenA.target);

    expect(reserveBefore.liquidityIndex).eq(RAY);
    expect(reserveAfter.liquidityIndex).approximately(RAY, '200000000000000000000000000');
  });

  it.skip('after supplying, borrowing and a full repay. The liquidity rate should be 0', async () => {
    // todo
    await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
    await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

    const reserveBefore = await pool.getReserveData(tokenA.target);
    await time.increase(86400 * 2000); // 2000 days

    await pool.repaySimple(tokenA.target, MaxUint256, 0);

    const reserveAfter = await pool.getReserveData(tokenA.target);

    expect(reserveBefore.liquidityRate).eq(RAY);
    expect(reserveAfter.liquidityRate).approximately(RAY, '200000000000000000000000000');
  });

  describe('- liquidityIndex & liquidityRate', () => {
    it('for a new reserve should be 1 ray', async () => {
      const reserve = await pool.getReserveData(tokenA.target);
      expect(reserve.liquidityIndex).eq(RAY);
      expect(reserve.liquidityRate).eq(0);
    });

    it('borrowing should immediately increase liquidity rate; liquidity index stays the same', async () => {
      const before = await pool.getReserveData(tokenA.target);

      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

      const after = await pool.getReserveData(tokenA.target);
      expect(after.liquidityRate).greaterThan(before.liquidityRate);
      expect(after.liquidityIndex).eq(before.liquidityIndex);
    });

    it('borrowing should increase liquidity rate and liquidity index increases after a few days', async () => {
      const before = await pool.getReserveData(tokenA.target);
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

      await time.increase(86400 * 2000); // 2000 days
      await pool.forceUpdateReserve(tokenA.target);

      const after = await pool.getReserveData(tokenA.target);
      expect(after.liquidityRate).greaterThan(before.liquidityRate);
      expect(after.liquidityIndex).greaterThan(before.liquidityIndex);
    });
  });

  describe('- borrowIndex & borrowRate', () => {
    it('for a new reserve should be 1 ray', async () => {
      const reserve = await pool.getReserveData(tokenA.target);
      expect(reserve.borrowIndex).eq(RAY);
      expect(reserve.borrowRate).eq(0);
    });

    it('borrowing should immediately increase borrow rate; borrow index stays the same', async () => {
      const before = await pool.getReserveData(tokenA.target);

      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

      const after = await pool.getReserveData(tokenA.target);
      expect(after.borrowRate).greaterThan(before.borrowRate);
      expect(after.borrowIndex).eq(before.borrowIndex);
    });

    it('borrowing should increase borrow rate and borrow index increases after a few days', async () => {
      const before = await pool.getReserveData(tokenA.target);
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.borrowSimple(tokenA.target, deployer.address, eth('0.4'), 0);

      await time.increase(86400 * 2000); // 2000 days
      await pool.forceUpdateReserve(tokenA.target);

      const after = await pool.getReserveData(tokenA.target);
      expect(after.borrowRate).greaterThan(before.borrowRate);
      expect(after.borrowIndex).greaterThan(before.borrowIndex);
    });
  });

  describe('- accruedToTreasuryShares', () => {
    // todo
  });
});
