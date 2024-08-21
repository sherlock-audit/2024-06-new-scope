// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {DataTypes} from './../../../../contracts/core/pool/configuration/DataTypes.sol';
import {ReserveConfiguration} from './../../../../contracts/core/pool/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from './../../../../contracts/core/pool/configuration/UserConfiguration.sol';

import {PoolSetup} from '../../core/pool/PoolSetup.sol';
import {IPool} from './../../../../contracts/interfaces/pool/IPool.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Hal001Test is PoolSetup {
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  DataTypes.UserConfigurationMap userConfig;
  address alice = address(1);
  address bob = address(2);
  address attacker = address(3);

  uint256 mintAmount = 2000 ether;
  uint256 tokenCMintAmount = 1000 ether;

  function setUp() public {
    _setUpPool();
  }

  function test_supplyCapBypass() external {
    //Mint and approve tokens
    _mintAndApprove(bob, tokenA, 200 ether, address(pool));
    _mintAndApprove(bob, tokenB, 200 ether, address(pool));
    _mintAndApprove(attacker, tokenA, 100 ether, address(pool));

    //Bob supplies tokens to the pool to generate proper flashloan conditions
    vm.startPrank(bob);
    pool.supplySimple(address(tokenA), bob, 200 ether, 0);
    pool.supplySimple(address(tokenB), bob, 200 ether, 0);
    vm.stopPrank();

    vm.prank(attacker);
    FlashLoanReceiver flashLoanReceiver = new FlashLoanReceiver(pool, attacker);
    tokenA.mint(address(flashLoanReceiver), 205 ether);

    //Set a supply cap for tokenA
    configurator.setSupplyCap(IPool(address(pool)), address(tokenA), 200);

    //Attacker tries to supply more than the cap, expecting a revert
    vm.startPrank(attacker);
    vm.expectRevert(bytes('SUPPLY_CAP_EXCEEDED'));
    pool.supplySimple(address(tokenA), attacker, 1, 0);

    //Attacker uses a flashloan to manipulate the supply cap check
    bytes memory emptyParams;
    vm.expectRevert(bytes('SUPPLY_CAP_EXCEEDED')); // comment this out to test thet attack
    pool.flashLoanSimple(address(address(flashLoanReceiver)), address(tokenA), 200 ether, emptyParams);
    vm.stopPrank();
  }
}

contract FlashLoanReceiver {
  IPool public pool;
  address public owner;

  constructor(IPool _pool, address _owner) {
    pool = _pool;
    owner = _owner;
  }

  function executeOperation(address asset, uint256 amount, uint256, address, bytes memory) public returns (bool) {
    //Approve the pool to pull the flashloaned amount
    IERC20(asset).approve(address(pool), type(uint256).max);

    //Supply the flashloaned amount to the pool
    pool.supplySimple(address(asset), owner, amount, 0);

    return true;
  }
}
