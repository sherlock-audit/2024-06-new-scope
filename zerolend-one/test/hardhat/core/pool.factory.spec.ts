import { DataTypes } from '../../../types/contracts/core/pool/Pool';

import {
  DefaultReserveInterestRateStrategy,
  MintableERC20,
  MockV3Aggregator as MockAggregator,
  PoolConfigurator,
} from '../../../types';
import { deployCore } from '../fixtures/core';
import { PoolFactory } from '../../../types/contracts/core/pool/PoolFactory';
import { Addressable, ZeroAddress } from 'ethers';
import { basicConfig } from '../fixtures/pool';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { ethers } from 'hardhat';

describe('Pool Factory', () => {
  let poolFactory: PoolFactory;

  let tokenA: MintableERC20;
  let tokenB: MintableERC20;
  let tokenC: MintableERC20;

  let oracleA: MockAggregator;
  let oracleB: MockAggregator;
  let oracleC: MockAggregator;

  let irStrategy: DefaultReserveInterestRateStrategy;

  let owner: SignerWithAddress;
  let ant: SignerWithAddress;
  let governance: SignerWithAddress;

  let libraries: {
    BorrowLogic: string | Addressable;
    FlashLoanLogic: string | Addressable;
    LiquidationLogic: string | Addressable;
    PoolLogic: string | Addressable;
    SupplyLogic: string | Addressable;
  };

  beforeEach(async () => {
    const fixture = await deployCore();
    ({
      poolFactory,
      libraries,
      tokenA,
      tokenB,
      tokenC,
      oracleA,
      oracleC,
      oracleB,
      irStrategy,
      ant,
      owner,
      governance,
    } = fixture);
  });

  describe('pool creation & updating', function () {
    it('should create a new pool', async () => {
      const input: DataTypes.InitPoolParamsStruct = {
        proxyAdmin: ZeroAddress,
        revokeProxy: false,
        admins: [],
        emergencyAdmins: [],
        riskAdmins: [],
        hook: ZeroAddress,
        assets: [tokenA.target, tokenB.target, tokenC.target],
        rateStrategyAddresses: [irStrategy.target, irStrategy.target, irStrategy.target],
        sources: [oracleA.target, oracleB.target, oracleC.target],
        configurations: [basicConfig, basicConfig, basicConfig],
      };

      expect(await poolFactory.poolsLength()).eq(0);
      const tx = poolFactory.createPool(input);
      await expect(tx).to.emit(poolFactory, 'PoolCreated');
      expect(await poolFactory.poolsLength()).eq(1);
    });

    it('should update pool implementation properly and not allow re-init(..)', async () => {
      const input: DataTypes.InitPoolParamsStruct = {
        proxyAdmin: ZeroAddress,
        revokeProxy: false,
        admins: [],
        emergencyAdmins: [],
        riskAdmins: [],
        hook: ZeroAddress,
        assets: [tokenA.target, tokenB.target, tokenC.target],
        rateStrategyAddresses: [irStrategy.target, irStrategy.target, irStrategy.target],
        sources: [oracleA.target, oracleB.target, oracleC.target],
        configurations: [basicConfig, basicConfig, basicConfig],
      };

      // should deploy pool
      const tx = await poolFactory.createPool(input);

      await expect(tx).to.emit(poolFactory, 'PoolCreated');
      expect(await poolFactory.poolsLength()).eq(1);
      const poolAddr = await poolFactory.pools(0);

      const pool = await ethers.getContractAt('Pool', poolAddr);
      expect(await pool.revision()).eq('1');

      // now try to upgrade the beacon
      const UpgradedPool = await ethers.getContractFactory('UpgradedPool', { libraries });
      const upgradedPool = await UpgradedPool.deploy();
      const tx2 = await poolFactory.setImplementation(upgradedPool.target);
      await expect(tx2).to.emit(poolFactory, 'ImplementationUpdated');

      // check if the pool upgraded properly
      expect(await pool.revision()).eq('1000');
      await expect(pool.initialize(input)).to.revertedWith(
        'Initializable: contract is already initialized'
      );
    });
  });
  describe('setImplementation', function () {
    it('should update implementation', async function () {
      await poolFactory.setImplementation(ant.address);
      expect(await poolFactory.implementation()).to.equal(ant.address);
    });

    it('should emit ImplementationUpdated event', async function () {
      const oldImplementation = await poolFactory.implementation();

      await expect(poolFactory.setImplementation(ant.address))
        .to.emit(poolFactory, 'ImplementationUpdated')
        .withArgs(oldImplementation, ant.address, owner.address);
    });

    it('should only allow owner to set implementation', async function () {
      await expect(poolFactory.connect(ant).setImplementation(ant.address)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
  });

  describe('setConfigurator', function () {
    let newConfigurator: PoolConfigurator;
    beforeEach(async () => {
      const PoolConfigurator = await ethers.getContractFactory('PoolConfigurator');
      newConfigurator = await PoolConfigurator.deploy(poolFactory.target);
    });
    it('should update configurator', async function () {
      await poolFactory.setConfigurator(newConfigurator.target);
      expect(await poolFactory.configurator()).to.equal(newConfigurator.target);
    });

    it('should emit ConfiguratorUpdated event', async function () {
      await expect(poolFactory.setConfigurator(newConfigurator.target))
        .to.emit(poolFactory, 'ConfiguratorUpdated')
        .withArgs(await poolFactory.configurator(), newConfigurator.target, owner.address);
    });

    it('should only allow owner to set configurator', async function () {
      await expect(
        poolFactory.connect(ant).setConfigurator(newConfigurator.target)
      ).to.be.revertedWith('Ownable: caller is not the owner');
    });
  });

  describe('setTreasury', function () {
    it('should update treasury', async function () {
      await poolFactory.setTreasury(ant.address);
      expect(await poolFactory.treasury()).to.equal(ant.address);
    });

    it('should emit TreasuryUpdated event', async function () {
      await expect(poolFactory.setTreasury(ant.address))
        .to.emit(poolFactory, 'TreasuryUpdated')
        .withArgs(await poolFactory.treasury(), ant.address, owner.address);
    });

    it('should only allow owner to set treasury', async function () {
      await expect(poolFactory.connect(ant).setTreasury(ant.address)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
  });

  describe('setReserveFactor', function () {
    it('should update reserve factor', async function () {
      await poolFactory.setReserveFactor(50);
      expect(await poolFactory.reserveFactor()).to.equal(50);
    });

    it('should emit ReserveFactorUpdated event', async function () {
      await expect(poolFactory.setReserveFactor(50))
        .to.emit(poolFactory, 'ReserveFactorUpdated')
        .withArgs(await poolFactory.reserveFactor(), 50, owner.address);
    });

    it('should only allow owner to set reserve factor', async function () {
      await expect(poolFactory.connect(ant).setReserveFactor(50)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
  });

  describe('setFlashloanPremium', function () {
    it('should update flashloan premium', async function () {
      await poolFactory.setFlashloanPremium(100);
      expect(await poolFactory.flashLoanPremiumToProtocol()).to.equal(100);
    });

    it('should emit FlashLoanPremiumToProtocolUpdated event', async function () {
      await expect(poolFactory.setFlashloanPremium(100))
        .to.emit(poolFactory, 'FlashLoanPremiumToProtocolUpdated')
        .withArgs(await poolFactory.flashLoanPremiumToProtocol(), 100, owner.address);
    });

    it('should only allow owner to set flashloan premium', async function () {
      await expect(poolFactory.connect(ant).setFlashloanPremium(100)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
  });

  describe('setLiquidationProtcolFeePercentage', function () {
    it('should update liquidation protocol fee percentage', async function () {
      await poolFactory.setLiquidationProtcolFeePercentage(100);
      expect(await poolFactory.liquidationProtocolFeePercentage()).to.equal(100);
    });

    it('should emit LiquidationProtocolFeePercentageUpdated event', async function () {
      await expect(poolFactory.setLiquidationProtcolFeePercentage(100))
        .to.emit(poolFactory, 'LiquidationProtocolFeePercentageUpdated')
        .withArgs(await poolFactory.liquidationProtocolFeePercentage(), 100, owner.address);
    });

    it('should only allow owner to set liquidation protocol fee percentage', async function () {
      await expect(
        poolFactory.connect(ant).setLiquidationProtcolFeePercentage(100)
      ).to.be.revertedWith('Ownable: caller is not the owner');
    });
  });
});
