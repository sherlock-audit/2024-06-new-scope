import {
  CuratedVault,
  CuratedVaultFactory,
  DefaultReserveInterestRateStrategy,
  ICuratedVaultFactory,
  MintableERC20,
  MockAggregator,
  PoolFactory,
} from '../../../types';
import { MaxUint256, ZeroAddress, keccak256 } from 'ethers';
import { basicConfig, deployPool } from '../fixtures/pool';
import _range from 'lodash/range';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';
import hre, { ethers } from 'hardhat';
import { DataTypes, Pool } from '../../../types/contracts/core/pool/Pool';
import {
  increaseTo,
  latest,
  setNextBlockTimestamp,
} from '@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time';
import { mine } from '@nomicfoundation/hardhat-network-helpers';

const e18 = BigInt(10 ** 18);

let seed = 42;
const random = () => {
  seed = (seed * 16807) % 2147483647;
  return (seed - 1) / 2147483646;
};

const forwardTimestamp = async (elapsed: number) => {
  const timestamp = await latest();
  const newTimestamp = timestamp + elapsed;

  await increaseTo(newTimestamp);
  await setNextBlockTimestamp(newTimestamp);
};

const randomForwardTimestamp = async () => {
  const elapsed = random() < 1 / 2 ? 0 : (1 + Math.floor(random() * 100)) * 12; // 50% of the time, don't go forward in time.
  await forwardTimestamp(elapsed);
};

describe('Curated Vault', () => {
  // Without the division it overflows.
  const initBalance = 100000000000000000000000n;
  const oraclePriceScale = BigInt(1000000000000000000000000000000000000);
  const marketsCount = 5;
  const timelock = 3600 * 24 * 7; // 1 week.

  let factory: CuratedVaultFactory;
  let poolFactory: PoolFactory;

  let poolA: Pool;
  let poolB: Pool;
  let poolC: Pool;
  let poolD: Pool;
  let poolE: Pool;
  let poolIdle: Pool;
  let pools: Pool[];

  let loan: MintableERC20;
  let collateral: MintableERC20;

  let oracleA: MockAggregator;
  let oracleB: MockAggregator;
  let oracleC: MockAggregator;

  let irStrategy: DefaultReserveInterestRateStrategy;

  let vault: CuratedVault;

  let admin: SignerWithAddress;
  let curator: SignerWithAddress;
  let allocator: SignerWithAddress;
  let suppliers: SignerWithAddress[];
  let borrowers: SignerWithAddress[];

  let supplyCap: bigint;

  beforeEach(async () => {
    const fixture = await deployPool();
    ({
      curatedVaultFactory: factory,
      poolFactory,
      tokenA: loan,
      tokenB: collateral,
      oracleA,
      oracleC,
      oracleB,
      irStrategy,
      whale: allocator,
      ant: curator,
      owner: admin,
    } = fixture);

    const allSigners = await ethers.getSigners();
    const users = allSigners.slice(0, -3);
    suppliers = users.slice(0, users.length / 2);
    borrowers = users.slice(users.length / 2);

    // create 5 pools and a vault
    const input: DataTypes.InitPoolParamsStruct = {
      proxyAdmin: ZeroAddress,
      revokeProxy: false,
      admins: [],
      emergencyAdmins: [],
      riskAdmins: [],
      hook: ZeroAddress,
      assets: [loan.target, collateral.target],
      rateStrategyAddresses: [irStrategy.target, irStrategy.target],
      sources: [oracleA.target, oracleB.target],
      configurations: [basicConfig, basicConfig],
    };

    await poolFactory.createPool(input);
    await poolFactory.createPool(input);
    await poolFactory.createPool(input);
    await poolFactory.createPool(input);
    await poolFactory.createPool(input);
    await poolFactory.createPool(input);

    poolA = await ethers.getContractAt('Pool', await poolFactory.pools(0));
    poolB = await ethers.getContractAt('Pool', await poolFactory.pools(1));
    poolC = await ethers.getContractAt('Pool', await poolFactory.pools(2));
    poolD = await ethers.getContractAt('Pool', await poolFactory.pools(3));
    poolE = await ethers.getContractAt('Pool', await poolFactory.pools(4));
    poolIdle = await ethers.getContractAt('Pool', await poolFactory.pools(5));

    pools = [poolA, poolB, poolC, poolD, poolE, poolIdle];

    const inputVault: ICuratedVaultFactory.InitVaultParamsStruct = {
      proxyAdmin: ZeroAddress,
      revokeProxy: false,
      admins: [admin],
      curators: [curator],
      allocators: [allocator],
      guardians: [],
      asset: loan.target,
      name: 'TEST',
      symbol: 'TEST-1',
      timelock: timelock,
      salt: keccak256('0x'),
    };
    await factory.createVault(inputVault);

    supplyCap = (e18 * BigInt(50 * suppliers.length * 2)) / BigInt(Math.floor(marketsCount / 2));

    const vaultAddr = await factory.vaults(0);
    vault = await ethers.getContractAt('CuratedVault', vaultAddr);

    for (const user of users) {
      await loan.mint(user.address, initBalance);
      await loan.connect(user).approve(vault.target, MaxUint256);
      await collateral.mint(user.address, initBalance);
      await collateral.connect(user).approve(vault.target, MaxUint256);
    }

    await vault.submitCap(poolA.target, supplyCap);
    await vault.submitCap(poolB.target, supplyCap);
    await vault.submitCap(poolC.target, supplyCap);
    await vault.submitCap(poolD.target, supplyCap);
    await vault.submitCap(poolE.target, supplyCap);
    await vault.submitCap(poolIdle.target, 2n ** 184n - 1n);

    await forwardTimestamp(timelock);

    await vault.acceptCap(poolA.target);
    await vault.acceptCap(poolB.target);
    await vault.acceptCap(poolC.target);
    await vault.acceptCap(poolD.target);
    await vault.acceptCap(poolE.target);
    await vault.acceptCap(poolIdle.target);

    await vault
      .connect(admin)
      .setSupplyQueue([
        poolA.target,
        poolB.target,
        poolC.target,
        poolD.target,
        poolE.target,
        poolIdle.target,
      ]);

    await vault.connect(admin).updateWithdrawQueue([0, 5, 4, 3, 2, 1]);

    hre.tracer.enabled = true;
  });

  it('should simulate gas cost [main]', async () => {
    const nbSuppliers = suppliers.length;
    const nbDeposits = nbSuppliers * 2;

    for (let i = 0; i < nbDeposits; ++i) {
      const j = i >= nbSuppliers ? nbDeposits - i - 1 : i;
      const supplier = suppliers[j];

      await randomForwardTimestamp();

      // Supplier j supplies twice, ~100 in total.
      await vault
        .connect(supplier)
        .deposit(
          e18 * BigInt(1 + Math.floor((99 * (nbDeposits - i - 1)) / (nbDeposits - 1))),
          supplier.address
        );

      await randomForwardTimestamp();

      // Supplier j withdraws twice, ~80 in total.
      await vault
        .connect(supplier)
        .withdraw(
          e18 * BigInt(1 + Math.ceil((79 * i) / (nbDeposits - 1))),
          supplier.address,
          supplier.address
        );

      await randomForwardTimestamp();

      // const allocation = await Promise.all(
      //   allMarketParams.map(async (marketParams) => {
      //     const market = await expectedMarket(marketParams);
      //     const position = await morpho.position(identifier(marketParams), metaMorphoAddress);

      //     return {
      //       marketParams,
      //       market,
      //       liquidity: market.totalSupplyAssets - market.totalBorrowAssets,
      //       supplyAssets: position.supplyShares.toAssetsDown(
      //         market.totalSupplyAssets,
      //         market.totalSupplyShares
      //       ),
      //     };
      //   })
      // );

      // const withdrawnAllocation = allocation.map(({ marketParams, liquidity, supplyAssets }) => {
      //   // Always withdraw all, up to the liquidity.
      //   const withdrawn = supplyAssets.min(liquidity);
      //   const remaining = supplyAssets - withdrawn;

      //   return {
      //     marketParams,
      //     supplyAssets,
      //     remaining,
      //     withdrawn,
      //   };
      // });

      // const idleMarket = await expectedMarket(idleParams);
      // const idlePosition = await morpho.position(identifier(idleParams), metaMorphoAddress);

      // const idleAssets = idlePosition.supplyShares.toAssetsDown(
      //   idleMarket.totalSupplyAssets,
      //   idleMarket.totalSupplyShares
      // );
      // const withdrawnAssets = withdrawnAllocation.reduce(
      //   (total, { withdrawn }) => total + withdrawn,
      //   0n
      // );

      // const marketAssets = ((withdrawnAssets + idleAssets) * 9n) / 10n / BigInt(nbMarkets);

      // const allocations = withdrawnAllocation.map(({ marketParams, remaining }) => ({
      //   marketParams,
      //   // Always supply evenly on each market 90% of what the vault withdrawn in total.
      //   assets: remaining + marketAssets,
      // }));

      // await vault.connect(allocator).reallocate(
      //   // Always withdraw all from idle first.
      //   [{ marketParams: idleParams, assets: 0n }]
      //     .concat(allocations)
      //     // Always supply remaining to idle last.
      //     .concat([{ marketParams: idleParams, assets: MaxUint256 }])
      // );

      // Borrow liquidity to generate interest.

      // await hre.network.provider.send('evm_setAutomine', [false]);

      const borrower = borrowers[i % nbSuppliers];

      for (const pool of pools) {
        await randomForwardTimestamp();

        // const market = await expectedMarket(marketParams);

        const liquidity = 0n; // market.totalSupplyAssets - market.totalBorrowAssets;
        const borrowed = BigInt(liquidity) / 100n;
        if (borrowed === 0n) break;

        // await pool.connect(borrower).supplySimple(loan, liquidity, 0);
        // await pool.connect(borrower).borrowSimple(collateral, borrowed, 0);

        await mine(); // Include supplyCollateral + borrow in a single block.
      }
    }

    await hre.network.provider.send('evm_setAutomine', [true]);
  });
});
