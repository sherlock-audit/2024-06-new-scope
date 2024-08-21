import { MaxUint256, parseEther as eth, parseUnits } from 'ethers';
import {
  DefaultReserveInterestRateStrategy,
  MintableERC20,
  MockV3Aggregator,
} from '../../../types';
import { Pool } from '../../../types/contracts/core/pool';
import { deployPool } from '../fixtures/pool';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { getPositionId } from '../utils/helpers';

describe('Pool', () => {
  let pool: Pool;
  let irStrategy: DefaultReserveInterestRateStrategy;
  let oracleB: MockV3Aggregator;
  let oracleA: MockV3Aggregator;

  let tokenA: MintableERC20;
  let tokenB: MintableERC20;

  let deployer: SignerWithAddress;
  let ant: SignerWithAddress;

  beforeEach(async () => {
    const fixture = await deployPool();
    ({ tokenA, tokenB, oracleA, oracleB, pool, owner: deployer, ant, irStrategy } = fixture);
  });

  describe('Supply / Withdraw functions', () => {
    beforeEach(async () => {
      await tokenA.mint(deployer.address, eth('10'));
      await tokenA.approve(pool.target, eth('3'));
    });

    it('try to supply into a pool', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
    });

    it('try to withdraw after a supply into a pool', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.withdrawSimple(tokenA.target, deployer.address, eth('1'), 0);
    });

    it('should give right balances for supplied positions', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      await pool.supplySimple(tokenA.target, deployer.address, eth('2'), 1);

      expect(await pool.getBalance(tokenA, deployer.address, 0)).eq(eth('1'));
      expect(await pool.getBalance(tokenA, deployer.address, 1)).eq(eth('2'));
    });

    it('should revert if withdraw after another index', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      const t = pool.withdrawSimple(tokenA.target, deployer.address, eth('1'), 1);
      await expect(t).to.revertedWith('NOT_ENOUGH_AVAILABLE_USER_BALANCE');
    });

    it('should revert if withdraw more than supplied', async () => {
      await pool.supplySimple(tokenA.target, deployer.address, eth('1'), 0);
      const t = pool.withdrawSimple(tokenA.target, deployer.address, eth('10'), 0);
      await expect(t).to.revertedWith('NOT_ENOUGH_AVAILABLE_USER_BALANCE');
    });
  });

  describe('Borrow / Repay functions', () => {
    beforeEach(async () => {
      await tokenA.mint(deployer.address, eth('10'));
      await tokenB.mint(deployer.address, eth('10'));

      await tokenA.approve(pool.target, eth('10'));
      await tokenB.approve(pool.target, eth('10'));

      await pool.supplySimple(tokenA.target, deployer.address, eth('5'), 0);
      await pool.supplySimple(tokenB.target, deployer.address, eth('5'), 0);
    });

    it('try to borrow from a pool', async () => {
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('5'));
      await pool.borrowSimple(tokenB.target, deployer.address, eth('1'), 0);
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('6'));
    });

    it('try to max repay whatever was borrowed', async () => {
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('5'));
      await pool.borrowSimple(tokenB.target, deployer.address, eth('1'), 0);
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('6'));
      await pool.repaySimple(tokenB.target, MaxUint256.toString(), 0);
      expect(await tokenB.balanceOf(deployer.address)).closeTo(eth('5'), eth('0.01'));
    });

    it('try to partial repay whatever was borrowed', async () => {
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('5'));
      await pool.borrowSimple(tokenB.target, deployer.address, eth('1'), 0);
      expect(await tokenB.balanceOf(deployer.address)).eq(eth('6'));
      await pool.repaySimple(tokenB.target, eth('0.1'), 0);
      expect(await tokenB.balanceOf(deployer.address)).closeTo(eth('5.9'), eth('0.01'));
    });
  });

  describe('Liquidate function', () => {
    beforeEach(async () => {
      await tokenA.mint(deployer.address, eth('1000'));
      await tokenB.mint(ant.address, eth('2000'));
      await tokenA.mint(ant.address, eth('2000'));

      await tokenA.approve(pool.target, eth('1000'));
      await tokenA.connect(ant).approve(pool.target, eth('2000'));
      await tokenB.connect(ant).approve(pool.target, eth('2000'));

      await pool.connect(ant).supplySimple(tokenA.target, ant.address, eth('5'), 0);
      await pool.connect(ant).supplySimple(tokenB.target, ant.address, eth('5'), 0);

      await pool.supplySimple(tokenA.target, deployer.address, eth('5'), 0);
      await pool.borrowSimple(tokenB.target, deployer.address, eth('1'), 0);
    });

    it('should not simply liquidate a healthy position', async () => {
      const position = getPositionId(deployer.address, 0);
      const liquidationTxn = pool
        .connect(ant)
        .liquidateSimple(tokenB.target, tokenB.target, position, eth('1'));

      await expect(liquidationTxn).to.be.revertedWith('HEALTH_FACTOR_NOT_BELOW_THRESHOLD');
    });

    it('should completely liquidate a non healthy position', async () => {
      const position = getPositionId(deployer.address, 0);

      const balanceOfAntBeforeTokenA = await tokenA.balanceOf(ant.address);
      const balanceOfAntBeforeTokenB = await tokenB.balanceOf(ant.address);
      await oracleA.updateAnswer(50);
      await pool.connect(ant).liquidateSimple(tokenA.target, tokenB.target, position, eth('1'));
      const balanceOfAntAfterTokenA = await tokenA.balanceOf(ant.address);
      const balanceOfAntAfterTokenB = await tokenB.balanceOf(ant.address);

      expect(balanceOfAntAfterTokenA).to.equal(eth('2000'));
      expect(balanceOfAntAfterTokenB).to.be.lessThan(balanceOfAntBeforeTokenB);
    });
  });

  describe('DefaultReserveInterestRateStrategy', function () {
    const BASE_VARIABLE_BORROW_RATE = BigInt(0);
    const VARIABLE_RATE_SLOPE_1 = parseUnits('0.07', 27);
    const VARIABLE_RATE_SLOPE_2 = parseUnits('0.3', 27);
    it('should return the correct optimal usage ratio', async function () {
      expect(await irStrategy.OPTIMAL_USAGE_RATIO()).to.equal(parseUnits('0.45', 27));
    });

    it('should return the correct max excess usage ratio', async function () {
      const MAX_EXCESS_USAGE_RATIO = parseUnits('0.55', 27);
      expect(await irStrategy.MAX_EXCESS_USAGE_RATIO()).to.equal(MAX_EXCESS_USAGE_RATIO);
    });

    it('should return the correct base borrow rate', async function () {
      expect(await irStrategy.getBaseBorrowRate()).to.equal(BASE_VARIABLE_BORROW_RATE);
    });

    it('should return the correct variable rate slope 1', async function () {
      expect(await irStrategy.getDebtSlope1()).to.equal(VARIABLE_RATE_SLOPE_1);
    });

    it('should return the correct variable rate slope 2', async function () {
      expect(await irStrategy.getDebtSlope2()).to.equal(VARIABLE_RATE_SLOPE_2);
    });

    it('should return the correct max borrow rate', async function () {
      const MAX_VARIABLE_BORROW_RATE =
        BASE_VARIABLE_BORROW_RATE + VARIABLE_RATE_SLOPE_1 + VARIABLE_RATE_SLOPE_2;
      expect(await irStrategy.getMaxBorrowRate()).to.equal(MAX_VARIABLE_BORROW_RATE);
    });
  });
});
