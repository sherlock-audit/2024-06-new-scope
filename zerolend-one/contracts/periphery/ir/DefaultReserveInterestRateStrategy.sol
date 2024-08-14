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

import {DataTypes} from '../../core/pool/configuration/DataTypes.sol';

import {PercentageMath} from '../../core/pool/utils/PercentageMath.sol';
import {WadRayMath} from '../../core/pool/utils/WadRayMath.sol';
import {IDefaultInterestRateStrategy} from '../../interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {PoolErrorsLib} from '../../interfaces/errors/PoolErrorsLib.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 * point of usage and another from that one to 100%.
 * - An instance of this same contract, can't be used across different markets, due to the caching
 *   of the PoolAddressesProvider
 */
contract DefaultReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public immutable OPTIMAL_USAGE_RATIO;

  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public immutable MAX_EXCESS_USAGE_RATIO;

  // Base borrow rate when usage rate = 0. Expressed in ray
  uint256 internal immutable _baseBorrowRate;

  // Slope of the debt interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _debtSlope1;

  // Slope of the debt interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _debtSlope2;

  /**
   * @dev Constructor.
   * @param optimalUsageRatio The optimal usage ratio
   * @param baseBorrowRate The base borrow rate
   * @param debtSlope1 The debt rate slope below optimal usage ratio
   * @param debtSlope2 The debt rate slope above optimal usage ratio
   */
  constructor(uint256 optimalUsageRatio, uint256 baseBorrowRate, uint256 debtSlope1, uint256 debtSlope2) {
    require(WadRayMath.RAY >= optimalUsageRatio, PoolErrorsLib.INVALID_OPTIMAL_USAGE_RATIO);
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
    _baseBorrowRate = baseBorrowRate;
    _debtSlope1 = debtSlope1;
    _debtSlope2 = debtSlope2;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getDebtSlope1() external view returns (uint256) {
    return _debtSlope1;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getDebtSlope2() external view returns (uint256) {
    return _debtSlope2;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getBaseBorrowRate() external view override returns (uint256) {
    return _baseBorrowRate;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getMaxBorrowRate() external view override returns (uint256) {
    return _baseBorrowRate + _debtSlope1 + _debtSlope2;
  }

  struct CalcInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 totalDebt;
    uint256 currentBorrowRate;
    uint256 currentLiquidityRate;
    uint256 borrowUsageRatio;
    uint256 supplyUsageRatio;
    uint256 availableLiquidityPlusDebt;
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function calculateInterestRates(
    bytes32,
    bytes memory,
    DataTypes.CalculateInterestRatesParams memory params
  ) public view override returns (uint256, uint256) {
    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = params.totalDebt;

    vars.currentLiquidityRate = 0;
    vars.currentBorrowRate = _baseBorrowRate;

    if (vars.totalDebt != 0) {
      vars.availableLiquidity = IERC20(params.reserve).balanceOf(msg.sender) + params.liquidityAdded - params.liquidityTaken;
      vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
      vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
      vars.supplyUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
    }

    if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
      uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(MAX_EXCESS_USAGE_RATIO);

      vars.currentBorrowRate += _debtSlope1 + _debtSlope2.rayMul(excessBorrowUsageRatio);
    } else {
      vars.currentBorrowRate += _debtSlope1.rayMul(vars.borrowUsageRatio).rayDiv(OPTIMAL_USAGE_RATIO);
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(params.totalDebt, vars.currentBorrowRate).rayMul(vars.supplyUsageRatio).percentMul(
      PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor
    );

    return (vars.currentLiquidityRate, vars.currentBorrowRate);
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total debt
   * @param totalDebt The total borrowed from the reserve at a debt rate
   * @param currentBorrowRate The current borrow rate of the reserve
   * @return overallBorrowRate The weighted averaged borrow rate
   */
  function _getOverallBorrowRate(uint256 totalDebt, uint256 currentBorrowRate) internal pure returns (uint256 overallBorrowRate) {
    if (totalDebt == 0) return 0;
    uint256 weightedDebt = totalDebt.wadToRay().rayMul(currentBorrowRate);
    overallBorrowRate = (weightedDebt).rayDiv(totalDebt.wadToRay());
  }
}
