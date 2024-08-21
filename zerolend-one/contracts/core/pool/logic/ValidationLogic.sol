// require(amount <= _balances[asset][pos].supplyShares, 'Insufficient Balance!');
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
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';

import {PoolErrorsLib} from '../../../interfaces/errors/PoolErrorsLib.sol';
import {TokenConfiguration} from '../configuration/TokenConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';

import {GenericLogic} from './GenericLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using Address for address;
  using TokenConfiguration for address;

  // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
  // A value of 0.9e4 results in 90%
  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

  // Minimum health factor allowed under any circumstance
  // A value of 0.95e18 results in 0.95
  uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

  /**
   * @dev Minimum health factor to consider a user position healthy
   * A value of 1e18 results in 1
   */
  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  /**
   * @notice Validates a supply action.
   * @param cache The cached data of the reserve
   * @param params The amount to be supplied
   */
  function validateSupply(
    DataTypes.ReserveCache memory cache,
    DataTypes.ReserveData storage reserve,
    DataTypes.ExecuteSupplyParams memory params,
    DataTypes.ReserveSupplies storage totalSupplies
  ) internal view {
    require(params.amount != 0, PoolErrorsLib.INVALID_AMOUNT);

    (bool isFrozen,) = cache.reserveConfiguration.getFlags();
    require(!isFrozen, PoolErrorsLib.RESERVE_FROZEN);

    uint256 supplyCap = cache.reserveConfiguration.getSupplyCap();

    require(
      supplyCap == 0
        || ((totalSupplies.supplyShares + uint256(reserve.accruedToTreasuryShares)).rayMul(cache.nextLiquidityIndex) + params.amount)
          <= supplyCap * (10 ** cache.reserveConfiguration.getDecimals()),
      PoolErrorsLib.SUPPLY_CAP_EXCEEDED
    );
  }

  /**
   * @notice Validates a withdraw action.
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(uint256 amount, uint256 userBalance) internal pure {
    require(amount != 0, PoolErrorsLib.INVALID_AMOUNT);
    require(amount <= userBalance, PoolErrorsLib.NOT_ENOUGH_AVAILABLE_USER_BALANCE);
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 collateralNeededInBaseCurrency;
    uint256 userCollateralInBaseCurrency;
    uint256 userDebtInBaseCurrency;
    uint256 availableLiquidity;
    uint256 healthFactor;
    uint256 totalDebt;
    uint256 totalSupplyVariableDebt;
    uint256 reserveDecimals;
    uint256 borrowCap;
    uint256 amountInBaseCurrency;
    uint256 assetUnit;
    bool isFrozen;
    bool borrowingEnabled;
  }

  /**
   * @notice Validates a borrow action.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param params Additional params needed for the validation
   */
  function validateBorrow(
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage _balances,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.ValidateBorrowParams memory params
  ) internal view {
    require(params.amount != 0, PoolErrorsLib.INVALID_AMOUNT);

    ValidateBorrowLocalVars memory vars;

    (vars.isFrozen, vars.borrowingEnabled) = params.cache.reserveConfiguration.getFlags();

    require(!vars.isFrozen, PoolErrorsLib.RESERVE_FROZEN);
    require(vars.borrowingEnabled, PoolErrorsLib.BORROWING_NOT_ENABLED);

    vars.reserveDecimals = params.cache.reserveConfiguration.getDecimals();
    vars.borrowCap = params.cache.reserveConfiguration.getBorrowCap();
    unchecked {
      vars.assetUnit = 10 ** vars.reserveDecimals;
    }

    if (vars.borrowCap != 0) {
      vars.totalSupplyVariableDebt = params.cache.currDebtShares.rayMul(params.cache.nextBorrowIndex);

      vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

      unchecked {
        require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, PoolErrorsLib.BORROW_CAP_EXCEEDED);
      }
    }

    (vars.userCollateralInBaseCurrency, vars.userDebtInBaseCurrency, vars.currentLtv,, vars.healthFactor,) = GenericLogic
      .calculateUserAccountData(
      _balances,
      reservesData,
      reservesList,
      DataTypes.CalculateUserAccountDataParams({userConfig: params.userConfig, position: params.position, pool: params.pool})
    );

    require(vars.userCollateralInBaseCurrency != 0, PoolErrorsLib.COLLATERAL_BALANCE_IS_ZERO);
    require(vars.currentLtv != 0, PoolErrorsLib.LTV_VALIDATION_FAILED);

    require(vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD, PoolErrorsLib.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD);

    vars.amountInBaseCurrency = IPool(params.pool).getAssetPrice(params.asset) * params.amount;
    unchecked {
      vars.amountInBaseCurrency /= vars.assetUnit;
    }

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is
    // calculated in percentage

    require(vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency, PoolErrorsLib.COLLATERAL_CANNOT_COVER_NEW_BORROW);
  }

  /**
   * @notice Validates a repay action.
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(uint256 amountSent, uint256 variableDebt) internal pure {
    require(amountSent != 0, PoolErrorsLib.INVALID_AMOUNT);
    require(amountSent != type(uint256).max, PoolErrorsLib.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF);
    require((variableDebt != 0), PoolErrorsLib.NO_DEBT_OF_SELECTED_TYPE);
  }

  /**
   * @notice Validates a flashloan action.
   * @param reserve The state of the reserve
   */
  function validateFlashloanSimple(DataTypes.ReserveData storage reserve) internal view {
    DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;
    require(!configuration.getFrozen(), PoolErrorsLib.RESERVE_FROZEN);
  }

  struct ValidateLiquidationCallLocalVars {
    bool collateralReserveActive;
    bool collateralReservePaused;
    bool principalReserveActive;
    bool principalReservePaused;
    bool isCollateralEnabled;
  }

  /**
   * @notice Validates the liquidation action.
   * @param userConfig The user configuration mapping
   * @param collateralReserve The reserve data of the collateral
   * @param params Additional parameters needed for the validation
   */
  function validateLiquidationCall(
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ValidateLiquidationCallParams memory params
  ) internal view {
    ValidateLiquidationCallLocalVars memory vars;

    require(params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD, PoolErrorsLib.HEALTH_FACTOR_NOT_BELOW_THRESHOLD);

    vars.isCollateralEnabled =
      collateralReserve.configuration.getLiquidationThreshold() != 0 && userConfig.isUsingAsCollateral(collateralReserve.id);

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    require(vars.isCollateralEnabled, PoolErrorsLib.COLLATERAL_CANNOT_BE_LIQUIDATED);
    require(params.totalDebt != 0, PoolErrorsLib.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
  }

  /**
   * @notice Validates the health factor of a user.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The state of the user for the specific reserve
   * @param position The user to validate health factor of
   * @param pool The pool instance
   */
  function validateHealthFactor(
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage _balances,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap memory userConfig,
    bytes32 position,
    address pool
  ) internal view returns (uint256, bool) {
    (,,,, uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic.calculateUserAccountData(
      _balances,
      reservesData,
      reservesList,
      DataTypes.CalculateUserAccountDataParams({userConfig: userConfig, position: position, pool: pool})
    );

    require(healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD, PoolErrorsLib.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD);

    return (healthFactor, hasZeroLtvCollateral);
  }

  /**
   * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The state of the user for the specific reserve
   * @param params The params to calculate HF and Ltv for
   */
  function validateHFAndLtv(
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage _balances,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap memory userConfig,
    DataTypes.ExecuteWithdrawParams memory params
  ) internal view {
    DataTypes.ReserveData memory reserve = reservesData[params.asset];

    (, bool hasZeroLtvCollateral) = validateHealthFactor(_balances, reservesData, reservesList, userConfig, params.position, params.pool);

    require(!hasZeroLtvCollateral || reserve.configuration.getLtv() == 0, PoolErrorsLib.LTV_VALIDATION_FAILED);
  }

  /**
   * @notice Validates the action of activating the asset as collateral.
   * @dev Only possible if the asset has non-zero LTV
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   */
  function validateUseAsCollateral(DataTypes.ReserveConfigurationMap memory reserveConfig) internal pure returns (bool) {
    return reserveConfig.getLtv() > 0;
  }

  /**
   * @notice Validates the action of setting an asset as collateral.
   * @param cache The cached data of the reserve
   * @param userBalance The balance of the user
   */
  function validateSetUseReserveAsCollateral(DataTypes.ReserveCache memory cache, uint256 userBalance) internal pure {
    require(userBalance != 0, PoolErrorsLib.UNDERLYING_BALANCE_ZERO);
    DataTypes.ReserveConfigurationMap memory configuration = cache.reserveConfiguration;
    require(!configuration.getFrozen(), PoolErrorsLib.RESERVE_FROZEN);
  }
}
