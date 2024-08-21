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

import {PoolGetters} from './PoolGetters.sol';

import {PoolRentrancyGuard} from './PoolRentrancyGuard.sol';
import {DataTypes} from './configuration/DataTypes.sol';
import {ReserveConfiguration} from './configuration/ReserveConfiguration.sol';

import {PoolErrorsLib} from '../../interfaces/errors/PoolErrorsLib.sol';
import {TokenConfiguration} from './configuration/TokenConfiguration.sol';
import {BorrowLogic} from './logic/BorrowLogic.sol';
import {FlashLoanLogic} from './logic/FlashLoanLogic.sol';
import {LiquidationLogic} from './logic/LiquidationLogic.sol';
import {PoolLogic} from './logic/PoolLogic.sol';
import {SupplyLogic} from './logic/SupplyLogic.sol';
import {PercentageMath} from './utils/PercentageMath.sol';

abstract contract PoolSetters is PoolRentrancyGuard, PoolGetters {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;
  using TokenConfiguration for address;

  function _supply(
    address asset,
    uint256 amount,
    bytes32 pos,
    DataTypes.ExtraData memory data
  ) internal nonReentrant(RentrancyKind.LENDING) returns (DataTypes.SharesType memory res) {
    if (address(_hook) != address(0)) _hook.beforeSupply(msg.sender, pos, asset, address(this), amount, data.hookData);

    res = SupplyLogic.executeSupply(
      _reserves[asset],
      _usersConfig[pos],
      _balances[asset][pos],
      _totalSupplies[asset],
      DataTypes.ExecuteSupplyParams({
        reserveFactor: _factory.reserveFactor(),
        asset: asset,
        amount: amount,
        data: data,
        position: pos,
        pool: address(this)
      })
    );

    if (address(_hook) != address(0)) _hook.afterSupply(msg.sender, pos, asset, address(this), amount, data.hookData);
  }

  function _withdraw(
    address asset,
    address to,
    uint256 amount,
    bytes32 pos,
    DataTypes.ExtraData memory data
  ) internal nonReentrant(RentrancyKind.LENDING) returns (DataTypes.SharesType memory res) {
    require(to != address(0), PoolErrorsLib.ZERO_ADDRESS_NOT_VALID);

    DataTypes.ExecuteWithdrawParams memory params = DataTypes.ExecuteWithdrawParams({
      reserveFactor: _factory.reserveFactor(),
      asset: asset,
      amount: amount,
      position: pos,
      destination: to,
      data: data,
      pool: address(this)
    });

    if (address(_hook) != address(0)) _hook.beforeWithdraw(params);

    res = SupplyLogic.executeWithdraw(_reserves, _reservesList, _usersConfig[pos], _balances, _totalSupplies[asset], params);
    PoolLogic.executeMintToTreasury(_totalSupplies[asset], _reserves, _factory.treasury(), asset);

    if (address(_hook) != address(0)) _hook.afterWithdraw(params);
  }

  function _borrow(
    address asset,
    address to,
    uint256 amount,
    bytes32 pos,
    DataTypes.ExtraData memory data
  ) internal nonReentrant(RentrancyKind.LENDING) returns (DataTypes.SharesType memory res) {
    if (address(_hook) != address(0)) _hook.beforeBorrow(msg.sender, pos, asset, address(this), amount, data.hookData);
    require(to != address(0), PoolErrorsLib.ZERO_ADDRESS_NOT_VALID);

    res = BorrowLogic.executeBorrow(
      _reserves,
      _reservesList,
      _usersConfig[pos],
      _balances,
      _totalSupplies[asset],
      DataTypes.ExecuteBorrowParams({
        reserveFactor: _factory.reserveFactor(),
        asset: asset,
        user: msg.sender,
        position: pos,
        amount: amount,
        destination: to,
        data: data,
        reservesCount: _reservesCount,
        pool: address(this)
      })
    );

    if (address(_hook) != address(0)) _hook.afterBorrow(msg.sender, pos, asset, address(this), amount, data.hookData);
  }

  function _repay(
    address asset,
    uint256 amount,
    bytes32 pos,
    DataTypes.ExtraData memory data
  ) internal nonReentrant(RentrancyKind.LENDING) returns (DataTypes.SharesType memory res) {
    if (address(_hook) != address(0)) _hook.beforeRepay(msg.sender, pos, asset, address(this), amount, data.hookData);

    res = BorrowLogic.executeRepay(
      _reserves[asset],
      _balances[asset][pos],
      _totalSupplies[asset],
      _usersConfig[pos],
      DataTypes.ExecuteRepayParams({
        reserveFactor: _factory.reserveFactor(),
        asset: asset,
        amount: amount,
        user: msg.sender,
        pool: address(this),
        position: pos,
        data: data
      })
    );

    if (address(_hook) != address(0)) _hook.afterRepay(msg.sender, pos, asset, address(this), amount, data.hookData);
  }

  function _liquidate(
    address collat,
    address debt,
    bytes32 pos,
    uint256 debtAmt,
    DataTypes.ExtraData memory data
  ) internal nonReentrant(RentrancyKind.LIQUIDATION) {
    if (address(_hook) != address(0)) _hook.beforeLiquidate(msg.sender, pos, collat, debt, debtAmt, address(this), data.hookData);

    LiquidationLogic.executeLiquidationCall(
      _reserves,
      _reservesList,
      _balances,
      _totalSupplies,
      _usersConfig,
      DataTypes.ExecuteLiquidationCallParams({
        reserveFactor: _factory.reserveFactor(),
        reservesCount: _reservesCount,
        debtToCover: debtAmt,
        collateralAsset: collat,
        debtAsset: debt,
        position: pos,
        data: data,
        pool: address(this)
      })
    );

    if (address(_hook) != address(0)) _hook.afterLiquidate(msg.sender, pos, collat, debt, debtAmt, address(this), data.hookData);
  }

  function _flashLoan(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    DataTypes.ExtraData memory data
  ) public virtual nonReentrant(RentrancyKind.FLASHLOAN) {
    if (address(_hook) != address(0)) {
      _hook.beforeFlashloan(msg.sender, receiverAddress, asset, amount, params, address(this), data.hookData);
    }
    require(receiverAddress != address(0), PoolErrorsLib.ZERO_ADDRESS_NOT_VALID);
    DataTypes.FlashloanSimpleParams memory flashParams = DataTypes.FlashloanSimpleParams({
      receiverAddress: receiverAddress,
      asset: asset,
      amount: amount,
      data: data,
      reserveFactor: _factory.reserveFactor(),
      params: params,
      flashLoanPremiumTotal: _factory.flashLoanPremiumToProtocol()
    });
    FlashLoanLogic.executeFlashLoanSimple(address(this), _reserves[asset], _totalSupplies[asset], flashParams);
    if (address(_hook) != address(0)) {
      _hook.afterFlashloan(msg.sender, receiverAddress, asset, amount, params, address(this), data.hookData);
    }
  }

  function _setUserUseReserveAsCollateral(address asset, uint256 index, bool useAsCollateral) internal {
    bytes32 pos = msg.sender.getPositionId(index);
    SupplyLogic.executeUseReserveAsCollateral(
      _reserves,
      _reservesList,
      _usersConfig[pos],
      _balances,
      _totalSupplies[asset],
      useAsCollateral,
      DataTypes.ExecuteWithdrawParams({
        reserveFactor: _factory.reserveFactor(),
        destination: msg.sender,
        asset: asset,
        amount: 0,
        position: pos,
        data: DataTypes.ExtraData({hookData: '', interestRateData: ''}),
        pool: address(this)
      })
    );
  }
}
