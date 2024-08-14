import { deployPool } from '../fixtures/pool';
import { expect } from 'chai';
import { MaxUint256, ZeroAddress, parseEther as e18 } from 'ethers';
import {
  MintableERC20,
  NFTPositionManager,
  Pool,
  PoolConfigurator,
  UIHelper,
  WETH9Mocked,
} from '../../../types';
import { deployNftPositionManager, deployUIHelper } from '../fixtures/periphery';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('NFT Position Manager - permissions', () => {
  let manager: NFTPositionManager;
  let poolFactory;
  let pool: Pool;
  let tokenA: MintableERC20;
  let weth: WETH9Mocked;
  let tokenB: MintableERC20;
  let uiHelper: UIHelper;
  let configurator: PoolConfigurator;
  let governance: SignerWithAddress, ant: SignerWithAddress, whale: SignerWithAddress;

  beforeEach(async () => {
    ({ poolFactory, pool, tokenA, tokenB, governance, ant, configurator, whale, weth } =
      await deployPool());
    manager = await deployNftPositionManager(poolFactory, weth, governance.address);
    uiHelper = await deployUIHelper(poolFactory, configurator, manager);

    await tokenA.connect(ant).approve(manager.target, MaxUint256);
    await tokenA.mint(ant.getAddress(), e18('100'));
    await tokenA.connect(whale).approve(manager.target, MaxUint256);
    await tokenA.mint(whale.getAddress(), e18('100'));
    await tokenB.connect(ant).approve(manager.target, MaxUint256);
    await tokenB.mint(ant.getAddress(), e18('100'));

    // seed some liquidity into the pool
    const mintCall = await manager.interface.encodeFunctionData('mint', [pool.target]);
    const supplyCall = await manager.interface.encodeFunctionData('supply', [
      {
        asset: tokenA.target,
        target: ZeroAddress,
        tokenId: 0,
        amount: e18('100'),
        data: { interestRateData: '0x', hookData: '0x' },
      },
    ]);
    await manager.connect(whale).multicall([mintCall, supplyCall]);
  });

  it('todo', async () => {
    expect(true).to.be.true;
  });
});
