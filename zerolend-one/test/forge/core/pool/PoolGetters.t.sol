// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {DataTypes} from './../../../../contracts/core/pool/configuration/DataTypes.sol';
import {UserConfiguration} from './../../../../contracts/core/pool/configuration/UserConfiguration.sol';

import {IPoolFactory} from './../../../../contracts/interfaces/IPoolFactory.sol';
import {PoolSetup} from './PoolSetup.sol';

contract PoolGetterTests is PoolSetup {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  function setUp() public {
    _setUpPool();
  }

  function testFactory() public view {
    IPoolFactory factory = pool.factory();
    assertEq(address(factory), address(poolFactory));
  }

  function testGetReserveData() public view {
    DataTypes.ReserveData memory data = pool.getReserveData(address(tokenA));
    assertTrue(data.borrowIndex > 0);
  }

  function testGetBalanceByPosition() public view {
    uint256 balance = pool.getBalanceByPosition(address(tokenA), pos);
    assertEq(balance, 0);
  }

  function testGetHook() public view {
    address hook = address(pool.getHook());
    assertEq(hook, address(0));
  }

  function testGetBalance() public view {
    uint256 balance = pool.getBalance(address(tokenA), address(1), 0);
    assertEq(balance, 0);
  }

  function testGetBalanceRawByPositionId() public view {
    DataTypes.PositionBalance memory balanceData = pool.getBalanceRawByPositionId(address(tokenA), pos);
    assertEq(balanceData.supplyShares, 0);
    assertEq(balanceData.debtShares, 0);
  }

  function testGetBalanceRaw() public view {
    DataTypes.PositionBalance memory balanceData = pool.getBalanceRaw(address(tokenA), address(1), 0);
    assertEq(balanceData.supplyShares, 0);
    assertEq(balanceData.debtShares, 0);
  }

  function testGetTotalSupplyRaw() public view {
    DataTypes.ReserveSupplies memory reserveSuppliesData = pool.getTotalSupplyRaw(address(tokenA));
    assertEq(reserveSuppliesData.supplyShares, 0);
    assertEq(reserveSuppliesData.debtShares, 0);
  }

  function testTotalAssets() public view {
    uint256 totalAssets = pool.totalAssets(address(tokenA));
    assertEq(totalAssets, 0);
  }

  function testTotalDebt() public view {
    uint256 totalDebt = pool.totalDebt(address(tokenA));
    assertEq(totalDebt, 0);
  }

  function testGetDebtByPosition() public view {
    uint256 debt = pool.getDebtByPosition(address(tokenA), pos);
    assertEq(debt, 0);
  }

  function testGetDebt() public view {
    uint256 debt = pool.getDebt(address(tokenA), address(1), 0);
    assertEq(debt, 0);
  }

  function testGetUserAccountData() public view {
    (uint256 totalCollateralBase, uint256 totalDebtBase,,,,) = pool.getUserAccountData(address(1), 0);
    assertEq(totalCollateralBase, 0);
    assertEq(totalDebtBase, 0);
  }

  function testGetConfiguration() public view {
    DataTypes.ReserveConfigurationMap memory configurationMap = pool.getConfiguration(address(tokenA));
    assertTrue(configurationMap.data > 0);
  }

  function testGetUserConfiguration() public view {
    DataTypes.UserConfigurationMap memory userConfigurationMap = pool.getUserConfiguration(address(1), 0);
    assertTrue(userConfigurationMap.data == 0);
  }

  function testGetReserveNormalizedIncome() public view {
    uint256 income = pool.getReserveNormalizedIncome(address(tokenA));
    assertEq(income, 1_000_000_000e18);
  }

  function testGetReserveNormalizedVariableDebt() public view {
    uint256 debt = pool.getReserveNormalizedVariableDebt(address(tokenA));
    assertEq(debt, 1_000_000_000e18);
  }

  function testGetReservesList() public view {
    address[] memory reservesList = pool.getReservesList();
    assertEq(reservesList.length, 4);
  }

  function testGetReservesCount() public view {
    uint256 reservesCount = pool.getReservesCount();
    assertEq(reservesCount, 4);
  }

  function testGetConfigurator() public view {
    address poolConfigurator = pool.getConfigurator();
    assertEq(poolConfigurator, address(configurator));
  }

  function testGetReserveAddressById() public view {
    address reserveAddress = pool.getReserveAddressById(0);
    assertEq(reserveAddress, address(tokenA));
  }

  function testGetAssetPrice() public view {
    uint256 price = pool.getAssetPrice(address(tokenA));
    assertEq(price, 1e8);
  }

  function testGetReserveFactor() public view {
    uint256 reserveFactor = pool.getReserveFactor();
    assertEq(reserveFactor, 0);
  }
}
