// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPool, PoolEventsLib, PoolSetup} from './PoolSetup.sol';

contract PoolSupplyTests is PoolSetup {
  function setUp() public {
    _setUpPool();
  }

  function testSupplyAmountZero() external {
    vm.expectRevert(bytes('INVALID_AMOUNT'));
    pool.supplySimple(address(tokenA), address(1), 0, 0);
  }

  function testSupplyFrozenEnabled() external {
    configurator.setReserveFreeze(IPool(address(pool)), address(tokenA), true);

    vm.startPrank(address(1));
    tokenA.mint(address(1), 1e18);
    tokenA.approve(address(pool), 1e18);

    vm.expectRevert(bytes('RESERVE_FROZEN'));
    pool.supplySimple(address(tokenA), address(1), 1e18, 0);
  }

  function testSupplyCapExceed() external {
    configurator.setSupplyCap(IPool(address(pool)), address(tokenA), 100);

    vm.startPrank(address(1));
    tokenA.mint(address(1), 1e18);
    tokenA.approve(address(pool), 1e18);

    vm.expectRevert(bytes('SUPPLY_CAP_EXCEEDED'));
    pool.supplySimple(address(tokenA), address(1), 101e18, 0);
  }

  function testSupplyEventEmit() external {
    uint256 index = 0;
    address user = owner;
    uint256 supplyAmount = 50 ether;
    bytes32 pos = keccak256(abi.encodePacked(user, 'index', index));

    vm.startPrank(owner);

    tokenA.mint(owner, 150 ether);
    tokenA.approve(address(pool), supplyAmount);

    vm.expectEmit(true, true, false, true);
    emit PoolEventsLib.Supply(address(tokenA), pos, supplyAmount);

    pool.supplySimple(address(tokenA), owner, supplyAmount, index);

    vm.stopPrank();
  }

  function testFailSupplyZeroAssetAddress() external {
    pool.supplySimple(address(0), owner, 50 ether, 0);
  }

  function testPoolSupply() external {
    uint256 supplyAmount = 50 ether;
    uint256 mintAmount = 150 ether;
    uint256 index = 1;

    vm.startPrank(owner);

    tokenA.mint(owner, mintAmount);
    tokenA.approve(address(pool), supplyAmount);

    pool.supplySimple(address(tokenA), owner, supplyAmount, index);

    assertEq(tokenA.balanceOf(address(pool)), supplyAmount);
    assertEq(tokenA.balanceOf(owner), mintAmount - supplyAmount);

    assertEq(pool.getTotalSupplyRaw(address(tokenA)).supplyShares, supplyAmount);
    assertEq(pool.getTotalSupplyRaw(address(tokenA)).debtShares, 0);
    assertEq(pool.getBalanceRaw(address(tokenA), owner, index).debtShares, 0);
    assertEq(pool.getBalanceRaw(address(tokenA), owner, index).supplyShares, supplyAmount);

    vm.stopPrank();
  }
}
