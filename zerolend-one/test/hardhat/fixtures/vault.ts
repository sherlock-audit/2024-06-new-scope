import { ethers } from 'hardhat';
import { deployCore } from './core';
import { ZeroAddress, parseEther } from 'ethers';
import { DataTypes } from '../../../types/contracts/core/pool/Pool';

export const basicConfig: DataTypes.InitReserveConfigStruct = {
  ltv: 7500,
  liquidationThreshold: 8000,
  liquidationBonus: 10500,
  decimals: 18,
  frozen: false,
  borrowable: true,
  borrowCap: 0,
  supplyCap: 0,
};

export const RAY = parseEther('1000000000');

export async function deployVault() {
  const fixture = await deployCore();
  const {
    poolFactory: factory,
    tokenA,
    tokenB,
    tokenC,
    irStrategy,
    oracleA,
    oracleB,
    oracleC,
  } = fixture;

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

  // create a pool
  await factory.createPool(input);

  // grab the instance and return
  const poolAddr = await factory.pools(0);
  const pool = await ethers.getContractAt('Pool', poolAddr);

  return {
    ...fixture,
    pool,
  };
}
