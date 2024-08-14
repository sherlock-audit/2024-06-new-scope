import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { MintableERC20, PoolConfigurator } from '../../../types';
import { Pool } from '../../../types/contracts/core/pool';
import { deployPool } from '../fixtures/pool';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('PoolConfigurator', () => {
  let pool: Pool;
  let configurator: PoolConfigurator;

  let admin: SignerWithAddress;
  let emergencyAdmin: SignerWithAddress;
  let riskAdmin: SignerWithAddress;
  let randWallet: SignerWithAddress;
  let randWallet2: SignerWithAddress;

  let tokenA: MintableERC20;

  beforeEach(async () => {
    const fixture = await deployPool();
    [, , , , , , , randWallet, randWallet2] = await ethers.getSigners();
    ({ configurator, pool, tokenA, owner: admin, ant: emergencyAdmin, whale: riskAdmin } = fixture);
    await configurator.addEmergencyAdmin(pool.target, emergencyAdmin);
    await configurator.addRiskAdmin(pool.target, riskAdmin);
  });

  it('should allow the pool admin to set reserve borrowing', async function () {
    await configurator.setReserveBorrowing(pool.target, tokenA.target, true);
    const config = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
    expect(config.borrowable).to.equal(true);
  });

  it('should allow the risk or pool admin to set reserve freeze', async function () {
    await configurator.setReserveFreeze(pool.target, tokenA, true);
    const configBefore = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
    expect(configBefore.frozen).to.equal(true);

    await configurator.connect(admin).setReserveFreeze(pool.target, tokenA, false);
    const configAfter = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
    expect(configAfter.frozen).to.equal(false);
  });

  it('should allow the emergency admin to set pool freeze', async function () {
    // const reserves = [ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address];
    const reserves = await pool.getReservesList();

    await configurator.connect(emergencyAdmin).setPoolFreeze(pool.target, true);
    for (let reserve of reserves) {
      const config = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
      expect(config.frozen).to.equal(true);
    }
  });

  it('should not allow anyone other than the emergency admin to set pool freeze', async function () {
    await expect(
      configurator.connect(randWallet).setPoolFreeze(pool.target, true)
    ).to.be.revertedWith('not risk or pool admin');
  });

  it('should allow the risk or pool admin to set borrow cap', async function () {
    const newBorrowCap = 1000;
    await configurator.connect(riskAdmin).setBorrowCap(pool.target, tokenA.target, newBorrowCap);
    const config = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
    expect(config.borrowCap).to.equal(newBorrowCap);
  });

  it('should allow the risk or pool admin to set supply cap', async function () {
    const newSupplyCap = 2000;
    await configurator.connect(admin).setSupplyCap(pool.target, tokenA.target, newSupplyCap);
    const config = await configurator.getPoolAssetConfiguration(pool.target, tokenA.target);
    expect(config.supplyCap).to.equal(newSupplyCap);
  });

  it('should allow the pool admin to set reserve interest rate strategy address', async function () {
    const newRateStrategyAddress = ethers.Wallet.createRandom().address;
    await configurator
      .connect(admin)
      .setReserveInterestRateStrategyAddress(pool.target, tokenA.target, newRateStrategyAddress);
    const reserveData = await pool.getReserveData(tokenA.target);
    expect(reserveData.interestRateStrategyAddress).to.equal(newRateStrategyAddress);
  });

  describe('Pool Manager', () => {
    describe('Admin Role Management', function () {
      it('should add and remove PoolAdmin', async function () {
        await configurator.addPoolAdmin(pool.target, randWallet.address);
        expect(await configurator.isPoolAdmin(pool.target, randWallet)).to.be.true;

        await configurator.removePoolAdmin(pool.target, randWallet.address);
        expect(await configurator.isPoolAdmin(pool.target, randWallet.address)).to.be.false;
      });

      it('should add and remove EmergencyAdmin', async function () {
        await configurator.addEmergencyAdmin(pool.target, randWallet.address);
        expect(await configurator.isEmergencyAdmin(pool.target, randWallet.address)).to.be.true;

        await configurator.removeEmergencyAdmin(pool.target, randWallet.address);
        expect(await configurator.isEmergencyAdmin(pool.target, randWallet.address)).to.be.false;
      });

      it('should add and remove RiskAdmin', async function () {
        await configurator.addRiskAdmin(pool.target, randWallet.address);
        expect(await configurator.isRiskAdmin(pool.target, randWallet.address)).to.be.true;

        await configurator.removeRiskAdmin(pool.target, randWallet.address);
        expect(await configurator.isRiskAdmin(pool.target, randWallet.address)).to.be.false;
      });
    });
  });
});
