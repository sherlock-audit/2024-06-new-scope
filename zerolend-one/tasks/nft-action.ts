import { task } from 'hardhat/config';
import { waitForTx } from './utils';
import { MaxUint256, parseEther as eth, ZeroAddress } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

task(`nft-action`).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== 'linea') throw new Error('invalid network');

  const [deployer] = await hre.ethers.getSigners();

  const weth = '0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f';
  const pool = await hre.ethers.getContractAt('Pool', '0x9BD573a2ae22c41A12310030c5121Bf74BE79Dc5');
  const token = await hre.ethers.getContractAt('ERC20', weth);

  const manageraddr = (await hre.deployments.get('NFTPositionManager')).address;
  const manager = await hre.ethers.getContractAt('NFTPositionManager', manageraddr);

  console.log('manager at', manager.target);
  console.log('giving approval');
  await waitForTx(await token.approve(manager.target, MaxUint256));

  console.log('supplying asset');
  const mint = await manager.mint.populateTransaction(pool.target);

  const supply = await manager.supply.populateTransaction({
    asset: weth,
    tokenId: 0,
    target: deployer.address,
    amount: eth('0.001'),
    data: { interestRateData: '0x', hookData: '0x' },
  });

  const borrow = await manager.borrow.populateTransaction({
    asset: weth,
    target: deployer.address,
    tokenId: 0,
    amount: eth('0.0001'),
    data: { interestRateData: '0x', hookData: '0x' },
  });

  const repay = await manager.repay.populateTransaction({
    asset: weth,
    target: deployer.address,
    tokenId: 0,
    amount: eth('0.0001'),
    data: { interestRateData: '0x', hookData: '0x' },
  });

  const withdraw = await manager.withdraw.populateTransaction({
    asset: weth,
    target: deployer.address,
    tokenId: 0,
    amount: eth('0.0001'),
    data: { interestRateData: '0x', hookData: '0x' },
  });

  await waitForTx(
    await manager.multicall([mint.data, supply.data, borrow.data, repay.data, withdraw.data])
  );
});
