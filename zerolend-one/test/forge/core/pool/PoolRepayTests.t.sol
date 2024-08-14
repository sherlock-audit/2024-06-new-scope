// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {DataTypes} from './../../../../contracts/core/pool/configuration/DataTypes.sol';
import {UserConfiguration} from './../../../../contracts/core/pool/configuration/UserConfiguration.sol';
import {PoolEventsLib} from './../../../../contracts/interfaces/events/PoolEventsLib.sol';
import {PoolSetup} from './PoolSetup.sol';

contract PoolRepayTests is PoolSetup {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 amount = 2000e18;
  uint256 borrowAmount = 800e18;
  address alice = address(10);

  function setUp() public {
    _setUpPool();
  }

  function testRepayAmountZero() external {
    vm.expectRevert(bytes('INVALID_AMOUNT'));
    pool.repaySimple(address(tokenA), 0, 0);
  }

  function testFailRepayZeroAssetAddress() external {
    pool.repaySimple(address(0), 50 ether, 0);
  }

  function testRepayFullBorrow() external {
    _mintAndApprove(alice, tokenA, 2 * amount, address(pool));
    vm.startPrank(alice);

    pool.supplySimple(address(tokenA), alice, amount, 0);
    pool.borrowSimple(address(tokenA), alice, borrowAmount, 0);
    vm.warp(block.timestamp + 10 days);

    uint256 tokenBalanceBefore = tokenA.balanceOf(alice);
    assertGt(pool.getDebt(address(tokenA), alice, 0), 0);

    // This event can not be tested as the borrowAmount changes each block.
    // vm.expectEmit(true, true, true, true);
    // emit PoolEventsLib.Repay(
    //   address(tokenA),
    //   pos,
    //   alice,
    //   borrowAmount
    // );

    tokenA.approve(address(pool), UINT256_MAX);

    pool.repaySimple(address(tokenA), UINT256_MAX, 0);
    uint256 tokenBalanceAfter = tokenA.balanceOf(alice);

    vm.stopPrank();

    uint256 debtBalanceAfter = pool.getDebt(address(tokenA), alice, 0);
    assertEq(debtBalanceAfter, 0);

    // greater than the actual borrow amount as interest accrued
    assertGt(tokenBalanceBefore - tokenBalanceAfter, borrowAmount);
    assertEq(pool.getUserConfiguration(alice, 0).isBorrowing(pool.getReserveData(address(tokenA)).id), false);
  }

  function testRepayPartialBorrow() external {
    bytes32 pos = keccak256(abi.encodePacked(alice, 'index', uint256(0)));

    _mintAndApprove(alice, tokenA, 2 * amount, address(pool));
    vm.startPrank(alice);

    pool.supplySimple(address(tokenA), alice, amount, 0);

    pool.borrowSimple(address(tokenA), alice, borrowAmount, 0);
    vm.warp(block.timestamp + 10 days);

    uint256 tokenBalanceBefore = tokenA.balanceOf(alice);
    assertGt(pool.getDebt(address(tokenA), alice, 0), 0);

    tokenA.approve(address(pool), UINT256_MAX);

    // This event can not be tested as the borrowAmount changes each block.
    vm.expectEmit(address(pool));
    emit PoolEventsLib.Repay(address(tokenA), pos, alice, borrowAmount);

    pool.repaySimple(address(tokenA), borrowAmount, 0);
    uint256 tokenBalanceAfter = tokenA.balanceOf(alice);

    vm.stopPrank();

    uint256 debtBalanceAfter = pool.getDebt(address(tokenA), alice, 0);
    assertGt(debtBalanceAfter, 0);

    assertEq(tokenBalanceBefore - tokenBalanceAfter, borrowAmount);
    assertEq(pool.getUserConfiguration(alice, 0).isBorrowing(pool.getReserveData(address(tokenA)).id), true);
  }
}
