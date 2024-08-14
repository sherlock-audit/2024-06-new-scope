// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import './PoolSetup.sol';

import {ReserveConfiguration} from './../../../../contracts/core/pool/configuration/ReserveConfiguration.sol';

import {UserConfiguration} from './../../../../contracts/core/pool/configuration/UserConfiguration.sol';

contract PoolLiquidationTest is PoolSetup {
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address alice = address(1);
  address bob = address(2);

  uint256 mintAmountA = 1000 ether;
  uint256 mintAmountB = 2000 ether;
  uint256 supplyAmountA = 550 ether;
  uint256 supplyAmountB = 750 ether;
  uint256 borrowAmountB = 100 ether;

  function setUp() public {
    _setUpPool();
    pos = keccak256(abi.encodePacked(alice, 'index', uint256(0)));
  }

  function testLiquidateSimpleRevertWhenHealthFactorBelowThreshold() external {
    vm.expectRevert(bytes('HEALTH_FACTOR_NOT_BELOW_THRESHOLD'));
    pool.liquidateSimple(address(tokenA), alice, pos, 0);
  }

  function testLiquidationSimple1() external {
    _generateLiquidationCondition();
    (, uint256 totalDebtBase,,,,) = pool.getUserAccountData(alice, 0);

    vm.startPrank(bob);
    vm.expectEmit(true, true, true, false);
    emit PoolEventsLib.LiquidationCall(address(tokenA), address(tokenB), pos, 0, 0, bob);
    pool.liquidateSimple(address(tokenA), address(tokenB), pos, 10 ether);

    vm.stopPrank();

    (, uint256 totalDebtBaseNew,,,,) = pool.getUserAccountData(alice, 0);

    assertTrue(totalDebtBase > totalDebtBaseNew);
  }

  function testLiquidationSimpleRevertWhenCollateralNotActive() external {
    _generateLiquidationCondition();
    vm.startPrank(bob);
    vm.expectRevert(bytes('COLLATERAL_CANNOT_BE_LIQUIDATED'));
    pool.liquidateSimple(address(tokenB), address(tokenB), pos, 10 ether);
    vm.stopPrank();
  }

  function testLiquidationSimpleRevertWhenWrongBorrowAssetPassed() external {
    _generateLiquidationCondition();
    vm.startPrank(bob);
    vm.expectRevert(bytes('SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER'));
    pool.liquidateSimple(address(tokenA), address(tokenA), pos, 10 ether);
    vm.stopPrank();
  }

  function _generateLiquidationCondition() internal {
    _mintAndApprove(alice, tokenA, mintAmountA, address(pool)); // alice 1000 tokenA
    _mintAndApprove(bob, tokenB, mintAmountB, address(pool)); // bob 2000 tokenB

    vm.startPrank(alice);
    pool.supplySimple(address(tokenA), alice, supplyAmountA, 0); // 550 tokenA alice supply
    vm.stopPrank();

    vm.startPrank(bob);
    pool.supplySimple(address(tokenB), bob, supplyAmountB, 0); // 750 tokenB bob supply
    vm.stopPrank();

    vm.startPrank(alice);
    pool.borrowSimple(address(tokenB), alice, borrowAmountB, 0); // 100 tokenB alice borrow
    vm.stopPrank();

    assertEq(tokenB.balanceOf(alice), borrowAmountB);

    oracleA.updateAnswer(5e3);
  }
}
