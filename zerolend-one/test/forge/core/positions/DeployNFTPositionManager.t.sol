// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Pool} from '../../../../contracts/core/pool/Pool.sol';
import {PoolFactory} from '../../../../contracts/core/pool/PoolFactory.sol';
import {Test} from '../../../../lib/forge-std/src/Test.sol';
import {NFTPositionManager} from 'contracts/core/positions/NFTPositionManager.sol';
import {TransparentUpgradeableProxy} from 'node_modules/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {PoolSetup} from 'test/forge/core/pool/PoolSetup.sol';

abstract contract DeployNFTPositionManager is PoolSetup {
  NFTPositionManager nftPositionManager;
  address admin = makeAddr('ProxyAdmin');

  function _setup() public {
    NFTPositionManager _nftPositionManager = new NFTPositionManager();
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(_nftPositionManager), admin, bytes(''));
    nftPositionManager = NFTPositionManager(payable(address(proxy)));
    nftPositionManager.initialize(address(poolFactory), address(0), owner, address(0), address(wethToken));
  }
}
