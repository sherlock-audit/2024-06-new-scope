import { task } from 'hardhat/config';
import { waitForTx } from './utils';
import { DataTypes } from '../types/contracts/core/pool/Pool';
import { ZeroAddress } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

/**
 * This task creates a pool with the given values. The data here is for the linea
 * network
 */
task(`create-pool`).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== 'linea') throw new Error('invalid network');

  const factoryD = await hre.deployments.get('PoolFactory');
  const ir = await hre.deployments.get('DefaultReserveInterestRateStrategy');
  const factory = await hre.ethers.getContractAt('PoolFactory', factoryD.address);

  const poolParams: DataTypes.InitPoolParamsStruct = {
    // admins: [], // TODO
    // emergencyAdmins: [], // TODO
    // proxyRevokable: false, // TODO
    hook: ZeroAddress,
    assets: [
      '0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f', // weth
      '0x176211869ca2b568f2a7d4ee941e073a821ee1ff', // usdc
    ],
    rateStrategyAddresses: [ir.address, ir.address],
    sources: [
      '0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA', // weth / usd
      '0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5', // usdc / usd
    ],
    configurations: [
      {
        ltv: 7500,
        liquidationThreshold: 8000,
        liquidationBonus: 10500,
        decimals: 18,
        frozen: false,
        borrowable: true,
        borrowCap: 0,
        supplyCap: 0,
      },
      {
        ltv: 7500,
        liquidationThreshold: 8000,
        liquidationBonus: 10500,
        decimals: 6,
        frozen: false,
        borrowable: true,
        borrowCap: 0,
        supplyCap: 0,
      },
    ],
  };

  console.log(poolParams);
  console.log('factory at', factory.target);
  const tx = await factory.createPool(poolParams);
  await waitForTx(tx);

  console.log('pool created!');
  console.log(await factory.pools((await factory.poolsLength()) - 1n));
});
