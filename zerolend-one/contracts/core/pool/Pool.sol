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

import {IHook} from '../../interfaces/IHook.sol';

import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';
import {IPool, IPoolSetters} from '../../interfaces/pool/IPool.sol';
import {PoolSetters} from './PoolSetters.sol';

import {DataTypes} from './configuration/DataTypes.sol';

import {TokenConfiguration} from './configuration/TokenConfiguration.sol';
import {ReserveLogic} from './logic/PoolLogic.sol';
import {PoolLogic} from './logic/PoolLogic.sol';

contract Pool is PoolSetters {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using TokenConfiguration for address;

  /**
   * @notice Initializes the Pool.
   * @dev This function is invoked by the factory contract when the Pool is created
   */
  function initialize(DataTypes.InitPoolParams memory params) public virtual initializer {
    _factory = IPoolFactory(msg.sender);
    _hook = IHook(params.hook);

    for (uint256 i = 0; i < params.assets.length; i++) {
      PoolLogic.executeInitReserve(
        _reserves,
        _reservesList,
        DataTypes.InitReserveParams({
          asset: params.assets[i],
          interestRateStrategyAddress: params.rateStrategyAddresses[i],
          oracle: params.sources[i],
          reservesCount: _reservesCount,
          configuration: params.configurations[i]
        })
      );

      _reservesCount++;
    }

    __PoolRentrancyGuard_init();
    if (address(_hook) != address(0)) _hook.afterInitialize(address(this));
  }

  /// @inheritdoc IPool
  function revision() external pure virtual returns (uint256) {
    return 1;
  }

  /// @inheritdoc IPoolSetters
  function supply(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) public returns (DataTypes.SharesType memory) {
    return _supply(asset, amount, to.getPositionId(index), data);
  }

  /// @inheritdoc IPoolSetters
  function supplySimple(address asset, address to, uint256 amount, uint256 index) public returns (DataTypes.SharesType memory) {
    return _supply(asset, amount, to.getPositionId(index), DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function withdraw(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) public returns (DataTypes.SharesType memory) {
    return _withdraw(asset, to, amount, msg.sender.getPositionId(index), data);
  }

  /// @inheritdoc IPoolSetters
  function withdrawSimple(address asset, address to, uint256 amount, uint256 index) public returns (DataTypes.SharesType memory) {
    return _withdraw(asset, to, amount, msg.sender.getPositionId(index), DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function borrow(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) public returns (DataTypes.SharesType memory) {
    return _borrow(asset, to, amount, msg.sender.getPositionId(index), data);
  }

  /// @inheritdoc IPoolSetters
  function borrowSimple(address asset, address to, uint256 amount, uint256 index) public returns (DataTypes.SharesType memory) {
    return _borrow(asset, to, amount, msg.sender.getPositionId(index), DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function repay(
    address asset,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) public returns (DataTypes.SharesType memory) {
    return _repay(asset, amount, msg.sender.getPositionId(index), data);
  }

  /// @inheritdoc IPoolSetters
  function repaySimple(address asset, uint256 amount, uint256 index) public returns (DataTypes.SharesType memory) {
    return _repay(asset, amount, msg.sender.getPositionId(index), DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function liquidate(address collat, address debt, bytes32 pos, uint256 debtAmt, DataTypes.ExtraData memory data) public {
    _liquidate(collat, debt, pos, debtAmt, data);
  }

  /// @inheritdoc IPoolSetters
  function liquidateSimple(address collat, address debt, bytes32 pos, uint256 debtAmt) public {
    _liquidate(collat, debt, pos, debtAmt, DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function flashLoan(address receiverAddress, address asset, uint256 amount, bytes calldata params, DataTypes.ExtraData memory data) public {
    _flashLoan(receiverAddress, asset, amount, params, data);
  }

  /// @inheritdoc IPoolSetters
  function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params) public {
    _flashLoan(receiverAddress, asset, amount, params, DataTypes.ExtraData({interestRateData: '', hookData: ''}));
  }

  /// @inheritdoc IPoolSetters
  function setReserveConfiguration(
    address asset,
    address rateStrategy,
    address source,
    DataTypes.ReserveConfigurationMap calldata config
  ) external virtual {
    require(msg.sender == address(_factory.configurator()), 'only configurator');
    PoolLogic.setReserveConfiguration(_reserves, asset, rateStrategy, source, config);
  }

  /// @inheritdoc IPoolSetters
  function forceUpdateReserve(address asset) public {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    DataTypes.ReserveCache memory cache = reserve.cache(_totalSupplies[asset]);
    reserve.updateState(0, cache);
  }

  /// @inheritdoc IPoolSetters
  function forceUpdateReserves() external {
    for (uint256 i = 0; i < _reservesCount; i++) {
      forceUpdateReserve(_reservesList[i]);
    }
  }

  /// @inheritdoc IPoolSetters
  function setUserUseReserveAsCollateral(address asset, uint256 index, bool useAsCollateral) external {
    _setUserUseReserveAsCollateral(asset, index, useAsCollateral);
  }
}
