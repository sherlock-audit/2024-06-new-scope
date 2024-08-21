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

import {IPool} from '../../../interfaces/pool/IPool.sol';
import {DataTypes} from '../configuration/DataTypes.sol';

import {PositionBalanceConfiguration} from '../configuration/PositionBalanceConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';

import {PoolErrorsLib} from '../../../interfaces/errors/PoolErrorsLib.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';

import {PoolEventsLib} from '../../../interfaces/events/PoolEventsLib.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title SupplyLogic library
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
  using PercentageMath for uint256;
  using PositionBalanceConfiguration for DataTypes.PositionBalance;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using WadRayMath for uint256;

  /**
   * @notice Implements the supply feature. Through `supply()`, users supply assets to the ZeroLend protocol.
   * @dev Emits the `Supply()` event.
   * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
   * collateral.
   * @param reserve The state of the reserves
   * @param userConfig The state of the position
   * @param balance The balance of the position
   * @param totalSupplies The total supplies of the reserve
   * @param params The additional parameters needed to execute the supply function
   */
  function executeSupply(
    DataTypes.ReserveData storage reserve,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.PositionBalance storage balance,
    DataTypes.ReserveSupplies storage totalSupplies,
    DataTypes.ExecuteSupplyParams memory params
  ) external returns (DataTypes.SharesType memory minted) {
    DataTypes.ReserveCache memory cache = reserve.cache(totalSupplies);
    reserve.updateState(params.reserveFactor, cache);

    ValidationLogic.validateSupply(cache, reserve, params, totalSupplies);
    reserve.updateInterestRates(
      totalSupplies,
      cache,
      params.asset,
      IPool(params.pool).getReserveFactor(),
      params.amount,
      0,
      params.position,
      params.data.interestRateData
    );

    // take the asset from the user and mint the shares
    IERC20(params.asset).safeTransferFrom(msg.sender, address(this), params.amount);
    bool isFirst;
    (isFirst, minted.shares) = balance.depositCollateral(totalSupplies, params.amount, cache.nextLiquidityIndex);

    // if this is the user's first deposit, enable the reserve as collateral
    if (isFirst && ValidationLogic.validateUseAsCollateral(cache.reserveConfiguration)) {
      userConfig.setUsingAsCollateral(reserve.id, true);
      emit PoolEventsLib.ReserveUsedAsCollateralEnabled(params.asset, params.position);
    }

    emit PoolEventsLib.Supply(params.asset, params.position, minted.shares);

    minted.assets = params.amount;
  }

  /**
   * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their aTokens for the underlying asset
   * previously supplied in the ZeroLend protocol.
   * @dev Emits the `Withdraw()` event.
   * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the withdraw function
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage balances,
    DataTypes.ReserveSupplies storage totalSupplies,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (DataTypes.SharesType memory burnt) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory cache = reserve.cache(totalSupplies);
    reserve.updateState(params.reserveFactor, cache);

    uint256 balance = balances[params.asset][params.position].getSupplyBalance(cache.nextLiquidityIndex);

    // repay with max amount should clear off all debt
    if (params.amount == type(uint256).max) params.amount = balance;

    ValidationLogic.validateWithdraw(params.amount, balance);

    reserve.updateInterestRates(
      totalSupplies,
      cache,
      params.asset,
      IPool(params.pool).getReserveFactor(),
      0,
      params.amount,
      params.position,
      params.data.interestRateData
    );

    bool isCollateral = userConfig.isUsingAsCollateral(reserve.id);

    // if the user is withdrawing everything then disable usage as collateral
    if (isCollateral && params.amount == balance) {
      userConfig.setUsingAsCollateral(reserve.id, false);
      emit PoolEventsLib.ReserveUsedAsCollateralDisabled(params.asset, params.position);
    }

    // Burn debt. Which is burn supply, update total supply and send tokens to the user
    burnt.shares = balances[params.asset][params.position].withdrawCollateral(totalSupplies, params.amount, cache.nextLiquidityIndex);
    IERC20(params.asset).safeTransfer(params.destination, params.amount);

    // if the user is borrowing any asset, validate the HF and LTVs
    if (isCollateral && userConfig.isBorrowingAny()) {
      ValidationLogic.validateHFAndLtv(balances, reservesData, reservesList, userConfig, params);
    }

    emit PoolEventsLib.Withdraw(params.asset, params.position, params.destination, params.amount);

    burnt.assets = params.amount;
  }

  /**
   * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
   * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
   * checks to ensure collateralization.
   * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
   * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The users configuration mapping that track the supplied/borrowed assets
   * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
   */
  function executeUseReserveAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage balances,
    DataTypes.ReserveSupplies storage totalSupplies,
    bool useAsCollateral,
    DataTypes.ExecuteWithdrawParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory cache = reserve.cache(totalSupplies);

    uint256 balance = balances[params.asset][params.position].getSupplyBalance(cache.nextLiquidityIndex);

    ValidationLogic.validateSetUseReserveAsCollateral(cache, balance);

    if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id)) return;

    if (useAsCollateral) {
      require(ValidationLogic.validateUseAsCollateral(cache.reserveConfiguration), PoolErrorsLib.LTV_ZERO);
      userConfig.setUsingAsCollateral(reserve.id, true);
      emit PoolEventsLib.ReserveUsedAsCollateralEnabled(params.asset, params.position);
    } else {
      userConfig.setUsingAsCollateral(reserve.id, false);
      ValidationLogic.validateHFAndLtv(balances, reservesData, reservesList, userConfig, params);
      emit PoolEventsLib.ReserveUsedAsCollateralDisabled(params.asset, params.position);
    }
  }
}
