import { deployPool } from '../fixtures/pool';
import { expect } from 'chai';
import { getPositionId } from '../utils/helpers';
import { MintableERC20, PoolConfigurator } from '../../../types';
import { Pool, PoolFactory } from '../../../types/contracts/core/pool';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import { ZeroAddress, ZeroHash, parseEther as eth } from 'ethers';

describe('Pool - Getters', () => {
  let configurator: PoolConfigurator;
  let deployer: SignerWithAddress;
  let pool: Pool;
  let poolFactory: PoolFactory;
  let tokenA: MintableERC20;

  beforeEach(async () => {
    const fixture = await deployPool();
    ({ tokenA, pool, owner: deployer, poolFactory, configurator } = fixture);
  });

  describe('getReserveData', function () {
    it('should return reserve data for a given asset', async function () {
      const reserveData = await pool.getReserveData(tokenA.target);
      expect(reserveData).to.exist;
    });
  });

  describe('getBalanceByPosition', function () {
    it('should return balance for a given position', async function () {
      const balance = await pool.getBalanceByPosition(
        tokenA.target,
        getPositionId(deployer.address, 0)
      );
      expect(balance).to.equal(0);
    });
  });

  describe('getHook', function () {
    it('should return the hook address', async function () {
      const hook = await pool.getHook();
      expect(hook).to.equal(ZeroAddress);
    });
  });

  describe('getBalance', function () {
    it('should return balance for a given user and index', async function () {
      const balance = await pool.getBalance(tokenA, deployer.address, 0);
      expect(balance).to.equal(0);
    });
  });

  describe('getBalanceRawByPositionId', function () {
    it('should return raw balance for a given position ID', async function () {
      const balance = await pool.getBalanceRawByPositionId(tokenA.target, ZeroHash);
      expect(balance.supplyShares).to.equal(0);
      expect(balance.debtShares).to.equal(0);
    });
  });

  describe('getBalanceRaw', function () {
    it('should return raw balance for a given user and index', async function () {
      const balance = await pool.getBalanceRaw(tokenA.target, deployer.address, 0);
      expect(balance.supplyShares).to.equal(0);
      expect(balance.debtShares).to.equal(0);
    });
  });

  describe('getTotalSupplyRaw', function () {
    it('should return total raw supply for a given asset', async function () {
      const totalSupply = await pool.getTotalSupplyRaw(tokenA.target);
      expect(totalSupply.supplyShares).to.equal(0);
      expect(totalSupply.debtShares).to.equal(0);
    });
  });

  describe('totalAssets', function () {
    it('should return total assets for a given asset', async function () {
      const totalAssets = await pool.totalAssets(tokenA.target);
      expect(totalAssets).to.equal(0);
    });
  });

  describe('totalDebt', function () {
    it('should return total debt for a given asset', async function () {
      const totalDebt = await pool.totalDebt(tokenA.target);
      expect(totalDebt).to.equal(0);
    });
  });

  describe('getDebtByPosition', function () {
    it('should return debt for a given position', async function () {
      const debt = await pool.getDebtByPosition(tokenA.target, ZeroHash);
      expect(debt).to.equal(0);
    });
  });

  describe('getDebt', function () {
    it('should return debt for a given user and index', async function () {
      const debt = await pool.getDebt(tokenA.target, deployer.address, 0);
      expect(debt).to.equal(0);
    });
  });

  describe('getUserAccountData', function () {
    it('should return user account data', async function () {
      const userData = await pool.getUserAccountData(deployer.address, 0);
      expect(userData).to.exist;
    });
  });

  describe('getConfiguration', function () {
    it('should return configuration for a given asset', async function () {
      const config = await pool.getConfiguration(tokenA.target);
      expect(config).to.exist;
    });
  });

  describe('getUserConfiguration', function () {
    it('should return user configuration', async function () {
      const userConfig = await pool.getUserConfiguration(deployer.address, 0);
      expect(userConfig).to.exist;
    });
  });

  describe('getReserveNormalizedIncome', function () {
    it('should return normalized income for a given reserve', async function () {
      const income = await pool.getReserveNormalizedIncome(tokenA.target);
      expect(income).to.equal(eth('1000000000'));
    });
  });

  describe('getReserveNormalizedVariableDebt', function () {
    it('should return normalized variable debt for a given reserve', async function () {
      const debt = await pool.getReserveNormalizedVariableDebt(tokenA.target);
      expect(debt).to.equal(eth('1000000000'));
    });
  });

  describe('getReservesList', function () {
    it('should return list of reserves', async function () {
      const reservesList = await pool.getReservesList();
      expect(reservesList.length).to.equal(3);
    });
  });

  describe('getReservesCount', function () {
    it('should return count of reserves', async function () {
      const reservesCount = await pool.getReservesCount();
      expect(reservesCount).to.equal(3);
    });
  });

  describe('getConfigurator', function () {
    it('should return configurator address', async function () {
      const poolConfigurator = await pool.getConfigurator();
      expect(poolConfigurator).to.equal(configurator);
    });
  });

  describe('getReserveAddressById', function () {
    it('should return reserve address by ID', async function () {
      const reserveAddress = await pool.getReserveAddressById(0);
      expect(reserveAddress).to.equal(tokenA.target);
    });
  });

  describe('getAssetPrice', function () {
    it('should return asset price from the oracle', async function () {
      const price = await pool.getAssetPrice(tokenA.target);
      expect(price).to.equal(5000);
    });
  });

  describe('factory', function () {
    it('should return the factory address', async function () {
      const factory = await pool.factory();
      expect(factory).to.equal(poolFactory.target);
    });
  });

  describe('getReserveFactor', function () {
    it('should return the reserve factor', async function () {
      const reserveFactor = await pool.getReserveFactor();
      expect(reserveFactor).to.equal(0);
    });
  });
});
