import { task } from 'hardhat/config';
import { waitForTx } from './utils';
import { DataTypes } from '../types/contracts/core/pool/Pool';
import { MaxUint256, parseEther as eth, ZeroAddress } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

/**
 * This task creates a pool with the given values. The data here is for the linea
 * network
 */
task(`pool-action`).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== 'linea') throw new Error('invalid network');

  const weth = '0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f';
  const pool = await hre.ethers.getContractAt('Pool', '0x1f3bb379a6d1beb067cd033a4304e135f0174269');
  const token = await hre.ethers.getContractAt('ERC20', weth);

  console.log('pool at', pool.target);

  // console.log('giving approval');
  // await waitForTx(await token.approve(pool.target, MaxUint256));

  // console.log('supplying asset');
  // await waitForTx(await pool.supplySimple(token.target, eth('0.001'), 0));

  // // console.log('setUserUseReserveAsCollateral');
  // // await waitForTx(await pool.setUserUseReserveAsCollateral(weth, 0, true));

  // console.log('borrowing asset');
  // await waitForTx(await pool.borrowSimple(token.target, eth('0.0001'), 0));

  // console.log('repaying asset');
  // await waitForTx(await pool.repaySimple(token.target, MaxUint256, 0));

  console.log('withdrawing asset');
  await waitForTx(await pool.withdrawSimple(token.target, MaxUint256, 0));
});
