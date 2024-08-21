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

import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';

import {DataTypes} from '../configuration/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {ReserveSuppliesConfiguration} from '../configuration/ReserveSuppliesConfiguration.sol';
import {MathUtils} from '../utils/MathUtils.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {PoolEventsLib} from '../../../interfaces/events/PoolEventsLib.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

/**
 * @title ReserveLogic library
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using ReserveSuppliesConfiguration for DataTypes.ReserveSupplies;

  /**
   * @notice Returns the ongoing normalized income for the reserve.
   * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
   * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return The normalized income, expressed in ray
   */
  function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    } else {
      return MathUtils.calculateLinearInterest(reserve.liquidityRate, timestamp).rayMul(reserve.liquidityIndex);
    }
  }

  /**
   * @notice Returns the ongoing normalized variable debt for the reserve.
   * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
   * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt, expressed in ray
   */
  function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.borrowIndex;
    } else {
      return MathUtils.calculateCompoundedInterest(reserve.borrowRate, timestamp).rayMul(reserve.borrowIndex);
    }
  }

  /**
   * @notice Updates the liquidity cumulative index and the borrow index.
   * @param self The reserve object
   * @param _cache The caching layer for the reserve data
   * @param _reserveFactor The reserve factor that is used to calculate how much revenue gets shared
   */
  function updateState(DataTypes.ReserveData storage self, uint256 _reserveFactor, DataTypes.ReserveCache memory _cache) internal {
    // If time didn't pass since last stored timestamp, skip state update
    if (self.lastUpdateTimestamp == uint40(block.timestamp)) return;

    _updateIndexes(self, _cache);
    _accrueToTreasury(_reserveFactor, self, _cache);

    self.lastUpdateTimestamp = uint40(block.timestamp);
  }

  /**
   * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
   * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accumulate
   * @return The next liquidity index of the reserve
   */
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal returns (uint256) {
    // next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
    // division `amount / totalLiquidity` done in ray for precision
    uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(reserve.liquidityIndex);
    reserve.liquidityIndex = result.toUint128();
    return result;
  }

  /**
   * @notice Initializes a reserve.
   * @param reserve The reserve object
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   */
  function init(DataTypes.ReserveData storage reserve, address interestRateStrategyAddress) internal {
    reserve.liquidityIndex = uint128(WadRayMath.RAY);
    reserve.borrowIndex = uint128(WadRayMath.RAY);
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 nextLiquidityRate;
    uint256 nextBorrowRate;
    uint256 totalDebt;
  }

  /**
   * @notice Updates the current borrow rate and the current liquidity rate.
   * @param _reserve The reserve reserve to be updated
   * @param _cache The caching layer for the reserve data
   * @param _reserveAddress The address of the reserve to be updated
   * @param _reserveFactor How much % of the interest goes to the treasury
   * @param _liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
   * @param _liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
   * @param _position The position of the user executing the interest rate updates
   * @param _data Any extra data to be passed to the interest rate strategy
   */
  function updateInterestRates(
    DataTypes.ReserveData storage _reserve,
    DataTypes.ReserveSupplies storage totalSupplies,
    DataTypes.ReserveCache memory _cache,
    address _reserveAddress,
    uint256 _reserveFactor,
    uint256 _liquidityAdded,
    uint256 _liquidityTaken,
    bytes32 _position,
    bytes memory _data
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalDebt = _cache.nextDebtShares.rayMul(_cache.nextBorrowIndex);

    (vars.nextLiquidityRate, vars.nextBorrowRate) = IReserveInterestRateStrategy(_reserve.interestRateStrategyAddress)
      .calculateInterestRates(
      _position,
      _data,
      DataTypes.CalculateInterestRatesParams({
        liquidityAdded: _liquidityAdded,
        liquidityTaken: _liquidityTaken,
        totalDebt: vars.totalDebt,
        reserveFactor: _reserveFactor,
        reserve: _reserveAddress
      })
    );

    _reserve.liquidityRate = vars.nextLiquidityRate.toUint128();
    _reserve.borrowRate = vars.nextBorrowRate.toUint128();

    if (_liquidityAdded > 0) totalSupplies.underlyingBalance += _liquidityAdded.toUint128();
    else if (_liquidityTaken > 0) totalSupplies.underlyingBalance -= _liquidityTaken.toUint128();

    emit PoolEventsLib.ReserveDataUpdated(
      _reserveAddress, vars.nextLiquidityRate, vars.nextBorrowRate, _cache.nextLiquidityIndex, _cache.nextBorrowIndex
    );
  }

  struct AccrueToTreasuryLocalVars {
    uint256 prevtotalDebt;
    uint256 currtotalDebt;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
  }

  /**
   * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
   * specific asset.
   * @param _reserve The reserve to be updated
   * @param _cache The caching layer for the reserve data
   */
  function _accrueToTreasury(uint256 reserveFactor, DataTypes.ReserveData storage _reserve, DataTypes.ReserveCache memory _cache) internal {
    if (reserveFactor == 0) return;
    AccrueToTreasuryLocalVars memory vars;

    // calculate the total variable debt at moment of the last interaction
    vars.prevtotalDebt = _cache.currDebtShares.rayMul(_cache.currBorrowIndex);

    // calculate the new total variable debt after accumulation of the interest on the index
    vars.currtotalDebt = _cache.currDebtShares.rayMul(_cache.nextBorrowIndex);

    // debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars.currtotalDebt - vars.prevtotalDebt;

    vars.amountToMint = vars.totalDebtAccrued.percentMul(reserveFactor);

    if (vars.amountToMint != 0) _reserve.accruedToTreasuryShares += vars.amountToMint.rayDiv(_cache.nextLiquidityIndex).toUint128();
  }

  /**
   * @notice Updates the reserve indexes and the timestamp of the update.
   * @param _reserve The reserve reserve to be updated
   * @param _cache The cache layer holding the cached protocol data
   */
  function _updateIndexes(DataTypes.ReserveData storage _reserve, DataTypes.ReserveCache memory _cache) internal {
    // Only cumulating on the supply side if there is any income being produced
    // The case of Reserve Factor 100% is not a problem (liquidityRate == 0),
    // as liquidity index should not be updated
    if (_cache.currLiquidityRate != 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(_cache.currLiquidityRate, _cache.reserveLastUpdateTimestamp);
      _cache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(_cache.currLiquidityIndex).toUint128();
      _reserve.liquidityIndex = _cache.nextLiquidityIndex;
    }

    // Variable borrow index only gets updated if there is any variable debt.
    // cache.currBorrowRate != 0 is not a correct validation,
    // because a positive base variable rate can be stored on
    // cache.currBorrowRate, but the index should not increase
    if (_cache.currDebtShares != 0) {
      uint256 cumulatedBorrowInterest = MathUtils.calculateCompoundedInterest(_cache.currBorrowRate, _cache.reserveLastUpdateTimestamp);
      _cache.nextBorrowIndex = cumulatedBorrowInterest.rayMul(_cache.currBorrowIndex).toUint128();
      _reserve.borrowIndex = _cache.nextBorrowIndex;
    }
  }

  /**
   * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
   * interest rates.
   * @param reserve The reserve object for which the cache will be filled
   * @param supplies The total supply object for the reserve asset
   * @return The cache object
   */
  function cache(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveSupplies storage supplies
  ) internal view returns (DataTypes.ReserveCache memory) {
    DataTypes.ReserveCache memory _cache;

    _cache.currLiquidityIndex = _cache.nextLiquidityIndex = reserve.liquidityIndex;
    _cache.currLiquidityRate = reserve.liquidityRate;
    _cache.currBorrowIndex = _cache.nextBorrowIndex = reserve.borrowIndex;
    _cache.currBorrowRate = reserve.borrowRate;
    _cache.reserveConfiguration = reserve.configuration;
    _cache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;
    _cache.currDebtShares = _cache.nextDebtShares = supplies.debtShares;

    return _cache;
  }
}
