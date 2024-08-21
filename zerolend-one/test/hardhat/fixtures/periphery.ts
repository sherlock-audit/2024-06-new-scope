import { ethers } from 'hardhat';
import { IWETH, NFTPositionManager, PoolConfigurator, PoolFactory } from '../../../types';
import { ZeroAddress } from 'ethers';

export async function deployNftPositionManager(factory: PoolFactory, weth: IWETH, admin: string) {
  const NFTPositionManager = await ethers.getContractFactory('NFTPositionManager');
  const Proxy = await ethers.getContractFactory('TransparentUpgradeableProxy');

  const implementation = await NFTPositionManager.deploy();

  const proxy = await Proxy.deploy(implementation.target, admin, '0x');
  const manager = await ethers.getContractAt('NFTPositionManager', proxy.target);
  await manager.initialize(factory.target, ZeroAddress, ZeroAddress, ZeroAddress, weth.target);

  return manager;
}

export async function deployUIHelper(
  factory: PoolFactory,
  configurator: PoolConfigurator,
  manager: NFTPositionManager
) {
  const UIHelper = await ethers.getContractFactory('UIHelper');
  return await UIHelper.deploy(factory.target, configurator.target, manager.target);
}
