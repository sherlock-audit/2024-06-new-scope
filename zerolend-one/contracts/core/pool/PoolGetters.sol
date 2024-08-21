// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz
// Telegram: https://t.me/zerolendxyz

import {IAggregatorV3Interface} from 'contracts/interfaces/IAggregatorV3Interface.sol';

import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';
import {IPool, IPoolGetters} from '../../interfaces/pool/IPool.sol';
import {IHook} from './../../interfaces/IHook.sol';

import {PoolStorage} from './PoolStorage.sol';
import {DataTypes} from './configuration/DataTypes.sol';
import {PositionBalanceConfiguration} from './configuration/PositionBalanceConfiguration.sol';

import {ReserveSuppliesConfiguration} from './configuration/ReserveSuppliesConfiguration.sol';
import {TokenConfiguration} from './configuration/TokenConfiguration.sol';
import {PoolLogic} from './logic/PoolLogic.sol';
import {ReserveLogic} from './logic/ReserveLogic.sol';

/**
 * @notice Provides all the getters and the view functions for the pool
 */
abstract contract PoolGetters is PoolStorage, IPool {
  using ReserveLogic for DataTypes.ReserveData;
  using TokenConfiguration for address;
  using ReserveSuppliesConfiguration for DataTypes.ReserveSupplies;
  using PositionBalanceConfiguration for DataTypes.PositionBalance;
  using ReserveLogic for DataTypes.ReserveCache;

  /// @inheritdoc IPoolGetters
  function getReserveData(address asset) external view virtual override returns (DataTypes.ReserveData memory) {
    return _reserves[asset];
  }

  /// @inheritdoc IPoolGetters
  function getBalanceByPosition(address asset, bytes32 positionId) external view returns (uint256 balance) {
    return _balances[asset][positionId].getSupplyBalance(_reserves[asset].liquidityIndex);
  }

  /// @inheritdoc IPoolGetters
  function getHook() external view returns (IHook) {
    return _hook;
  }

  /// @inheritdoc IPoolGetters
  function getBalance(address asset, address who, uint256 index) external view returns (uint256 balance) {
    bytes32 positionId = who.getPositionId(index);
    return _balances[asset][positionId].getSupplyBalance(_reserves[asset].liquidityIndex);
  }

  /// @inheritdoc IPoolGetters
  function getBalanceRawByPositionId(address asset, bytes32 positionId) external view returns (DataTypes.PositionBalance memory) {
    return _balances[asset][positionId];
  }

  /// @inheritdoc IPoolGetters
  function getBalanceRaw(address asset, address who, uint256 index) external view returns (DataTypes.PositionBalance memory) {
    bytes32 positionId = who.getPositionId(index);
    return _balances[asset][positionId];
  }

  /// @inheritdoc IPoolGetters
  function getTotalSupplyRaw(address asset) external view returns (DataTypes.ReserveSupplies memory) {
    return _totalSupplies[asset];
  }

  /// @inheritdoc IPoolGetters
  function totalAssets(address asset) external view returns (uint256 balance) {
    balance = _totalSupplies[asset].getSupplyBalance(_reserves[asset].liquidityIndex);
  }

  /// @inheritdoc IPoolGetters
  function totalDebt(address asset) external view returns (uint256 balance) {
    balance = _totalSupplies[asset].getDebtBalance(_reserves[asset].borrowIndex);
  }

  /// @inheritdoc IPoolGetters
  function getDebtByPosition(address asset, bytes32 positionId) external view returns (uint256 debt) {
    return _balances[asset][positionId].getDebtBalance(_reserves[asset].borrowIndex);
  }

  /// @inheritdoc IPoolGetters
  function getDebt(address asset, address who, uint256 index) external view returns (uint256 debt) {
    bytes32 positionId = who.getPositionId(index);
    return _balances[asset][positionId].getDebtBalance(_reserves[asset].borrowIndex);
  }

  /// @inheritdoc IPoolGetters
  function getUserAccountData(
    address user,
    uint256 index
  ) external view virtual override returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    bytes32 positionId = user.getPositionId(index);
    return PoolLogic.executeGetUserAccountData(
      _balances,
      _reserves,
      _reservesList,
      DataTypes.CalculateUserAccountDataParams({userConfig: _usersConfig[positionId], position: positionId, pool: address(this)})
    );
  }

  /// @inheritdoc IPoolGetters
  function getConfiguration(address asset) external view virtual override returns (DataTypes.ReserveConfigurationMap memory) {
    return _reserves[asset].configuration;
  }

  /// @inheritdoc IPoolGetters
  function getUserConfiguration(address user, uint256 index) external view virtual override returns (DataTypes.UserConfigurationMap memory) {
    return _usersConfig[user.getPositionId(index)];
  }

  /// @inheritdoc IPoolGetters
  function getReserveNormalizedIncome(address reserve) external view virtual override returns (uint256) {
    return _reserves[reserve].getNormalizedIncome();
  }

  /// @inheritdoc IPoolGetters
  function getReserveNormalizedVariableDebt(address reserve) external view virtual override returns (uint256) {
    return _reserves[reserve].getNormalizedDebt();
  }

  /// @inheritdoc IPoolGetters
  function getReservesList() external view virtual override returns (address[] memory) {
    address[] memory reservesList = new address[](_reservesCount);
    for (uint256 i = 0; i < _reservesCount; i++) {
      reservesList[i] = _reservesList[i];
    }
    return reservesList;
  }

  /// @inheritdoc IPoolGetters
  function getReservesCount() external view virtual override returns (uint256) {
    return _reservesCount;
  }

  /// @inheritdoc IPoolGetters
  function getConfigurator() external view override returns (address) {
    return address(_factory.configurator());
  }

  /// @inheritdoc IPoolGetters
  function getReserveAddressById(uint16 id) external view returns (address) {
    return _reservesList[id];
  }

  /// @inheritdoc IPoolGetters
  function getAssetPrice(address reserve) public view override returns (uint256) {
    (, int256 price,, uint256 updatedAt,) = IAggregatorV3Interface(_reserves[reserve].oracle).latestRoundData();
    require(price > 0, 'Invalid price');
    require(block.timestamp <= updatedAt + 1800, 'Stale Price');
    return uint256(price);
  }

  /// @inheritdoc IPoolGetters
  function factory() external view returns (IPoolFactory) {
    return _factory;
  }

  /// @inheritdoc IPoolGetters
  function getReserveFactor() external view returns (uint256 reseveFactor) {
    return _factory.reserveFactor();
  }

  /// @inheritdoc IPoolGetters
  function marketBalances(address asset) public view returns (uint256, uint256, uint256, uint256) {
    DataTypes.ReserveSupplies storage supplies = _totalSupplies[asset];

    return (
      supplies.getSupplyBalance(_reserves[asset].liquidityIndex),
      supplies.supplyShares,
      supplies.getDebtBalance(_reserves[asset].borrowIndex),
      supplies.debtShares
    );
  }

  /// @inheritdoc IPoolGetters
  function supplyAssets(address asset, bytes32 positionId) external view returns (uint256) {
    return _balances[asset][positionId].getSupplyBalance(_reserves[asset].liquidityIndex);
  }

  /// @inheritdoc IPoolGetters
  function supplyShares(address asset, bytes32 positionId) external view returns (uint256 shares) {
    return _balances[asset][positionId].supplyShares;
  }

  /// @inheritdoc IPoolGetters
  function debtAssets(address asset, bytes32 positionId) external view returns (uint256) {
    return _balances[asset][positionId].getDebtBalance(_reserves[asset].borrowIndex);
  }

  /// @inheritdoc IPoolGetters
  function debtShares(address asset, bytes32 positionId) external view returns (uint256 shares) {
    return _balances[asset][positionId].debtShares;
  }
}
