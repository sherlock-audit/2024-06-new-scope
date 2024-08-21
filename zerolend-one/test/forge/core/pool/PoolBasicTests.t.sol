// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {DataTypes} from './../../../../contracts/core/pool/configuration/DataTypes.sol';
import {ReserveConfiguration} from './../../../../contracts/core/pool/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from './../../../../contracts/core/pool/configuration/UserConfiguration.sol';

import {IPool} from './../../../../contracts/interfaces/pool/IPool.sol';
import {PoolSetup} from './PoolSetup.sol';

contract PoolBasicTests is PoolSetup {
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  DataTypes.UserConfigurationMap userConfig;
  address alice = address(1);

  uint256 mintAmount = 2000 ether;
  uint256 tokenCMintAmount = 1000 ether;

  function setUp() public {
    _setUpPool();
  }

  function testPoolFactoryLength() external view {
    assertEq(poolFactory.poolsLength(), 1);
  }

  function testReserveList() external view {
    address[] memory reserveList = pool.getReservesList();
    assertEq(reserveList[0], address(tokenA));
    assertEq(reserveList[1], address(tokenB));
    assertEq(reserveList[2], address(tokenC));
  }

  function testSetReserveConfigurationByNonOwner() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;

    vm.startPrank(alice);
    vm.expectRevert(bytes('only configurator'));
    pool.setReserveConfiguration(address(tokenA), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testSetReserveConfigurationRevertZeroAddress() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;
    vm.startPrank(address(configurator));
    vm.expectRevert(bytes('ZERO_ADDRESS_NOT_VALID'));
    pool.setReserveConfiguration(address(0), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testSetReserveConfigurationRevertLTVGreaterThanLT() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;
    vm.startPrank(address(configurator));
    config.setLtv(10_000);
    vm.expectRevert(bytes('INVALID_RESERVE_PARAMS'));
    pool.setReserveConfiguration(address(tokenA), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testSetReserveConfigurationRevertWhenLBLessThanPF() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;
    vm.startPrank(address(configurator));
    config.setLiquidationBonus(1e2);
    vm.expectRevert(bytes('INVALID_RESERVE_PARAMS'));
    pool.setReserveConfiguration(address(tokenA), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testSetReserveConfigurationRevertWhenLTMultiplyLBGreaterThanPF() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;
    vm.startPrank(address(configurator));
    config.setLiquidationBonus(1e2);
    config.setLiquidationThreshold(1e3);
    vm.expectRevert(bytes('INVALID_RESERVE_PARAMS'));
    pool.setReserveConfiguration(address(tokenA), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testSetReserveConfigurationRevertWhenDecimalsGreaterThanSix() external {
    DataTypes.ReserveConfigurationMap memory config = pool.getReserveData(address(tokenA)).configuration;
    vm.startPrank(address(configurator));
    config.setDecimals(5);
    vm.expectRevert(bytes('not enough decimals'));
    pool.setReserveConfiguration(address(tokenA), address(irStrategy), address(oracleA), config);
    vm.stopPrank();
  }

  function testForceUpdateReserve() external {
    // Should execute smoothly
    pool.forceUpdateReserve(address(tokenA));
  }

  function testForceUpdateReserves() external {
    // Should execute smoothly
    pool.forceUpdateReserves();
  }

  function testSetUserUseReserveAsCollateralRevertForNoSupply() external {
    _mintAndApprove(alice, tokenA, mintAmount, address(pool));
    vm.startPrank(alice);

    pool.supplySimple(address(tokenA), alice, mintAmount, 0);

    userConfig = pool.getUserConfiguration(alice, 0);
    assertEq(userConfig.isUsingAsCollateral(0), true);
    assertEq(userConfig.isUsingAsCollateralAny(), true);

    vm.expectRevert(bytes('UNDERLYING_BALANCE_ZERO'));
    pool.setUserUseReserveAsCollateral(address(tokenC), 0, false);

    vm.stopPrank();
  }

  function testSetUserUseReserveAsCollateralRevertWhenFrozen() external {
    _mintAndApprove(alice, tokenA, mintAmount, address(pool));
    _mintAndApprove(alice, tokenC, mintAmount, address(pool));
    vm.startPrank(alice);

    pool.supplySimple(address(tokenA), alice, mintAmount, 0);
    pool.supplySimple(address(tokenC), alice, mintAmount, 0);
    vm.stopPrank();

    configurator.setReserveFreeze(IPool(address(pool)), address(tokenC), true);
    vm.startPrank(alice);

    vm.expectRevert(bytes('RESERVE_FROZEN'));
    pool.setUserUseReserveAsCollateral(address(tokenC), 0, false);
    vm.stopPrank();
  }

  function testSetUserUseReserveAsCollateral() external {
    _mintAndApprove(alice, tokenA, mintAmount, address(pool));
    _mintAndApprove(alice, tokenC, mintAmount, address(pool));
    vm.startPrank(alice);

    pool.supplySimple(address(tokenA), alice, mintAmount, 0);

    userConfig = pool.getUserConfiguration(alice, 0);
    assertEq(userConfig.isUsingAsCollateral(0), true);
    assertEq(userConfig.isUsingAsCollateral(2), false);
    assertEq(userConfig.isUsingAsCollateralAny(), true);

    pool.supplySimple(address(tokenC), alice, mintAmount, 0);

    userConfig = pool.getUserConfiguration(alice, 0);
    assertEq(userConfig.isUsingAsCollateral(0), true);
    assertEq(userConfig.isUsingAsCollateral(2), true);
    assertEq(userConfig.isUsingAsCollateralAny(), true);

    pool.setUserUseReserveAsCollateral(address(tokenC), 0, false);
    userConfig = pool.getUserConfiguration(alice, 0);
    assertEq(userConfig.isUsingAsCollateral(2), false);

    pool.setUserUseReserveAsCollateral(address(tokenC), 0, true);
    userConfig = pool.getUserConfiguration(alice, 0);
    assertEq(userConfig.isUsingAsCollateral(2), true);

    vm.stopPrank();
  }
}
