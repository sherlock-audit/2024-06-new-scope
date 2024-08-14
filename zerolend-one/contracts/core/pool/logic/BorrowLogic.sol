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

import {PoolEventsLib} from '../../../interfaces/events/PoolEventsLib.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

/**
 * @title BorrowLogic library
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PositionBalanceConfiguration for DataTypes.PositionBalance;
  using SafeCast for uint256;

  /**
   * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
   * protocol proportionally to their collateralization power.
   * @dev  Emits the `Borrow()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the borrow function
   */
  function executeBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage _balances,
    DataTypes.ReserveSupplies storage totalSupplies,
    DataTypes.ExecuteBorrowParams memory params
  ) public returns (DataTypes.SharesType memory borrowed) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory cache = reserve.cache(totalSupplies);

    reserve.updateState(params.reserveFactor, cache);

    ValidationLogic.validateBorrow(
      _balances,
      reservesData,
      reservesList,
      DataTypes.ValidateBorrowParams({
        cache: cache,
        userConfig: userConfig,
        asset: params.asset,
        position: params.position,
        amount: params.amount,
        reservesCount: params.reservesCount,
        pool: params.pool
      })
    );

    // mint debt tokens
    DataTypes.PositionBalance storage b = _balances[params.asset][params.position];
    bool isFirstBorrowing;
    (isFirstBorrowing, borrowed.shares) = b.borrowDebt(totalSupplies, params.amount, cache.nextBorrowIndex);
    cache.nextDebtShares = totalSupplies.debtShares;

    // if first borrowing, flag that
    if (isFirstBorrowing) userConfig.setBorrowing(reserve.id, true);

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

    IERC20(params.asset).safeTransfer(params.destination, params.amount);

    emit PoolEventsLib.Borrow(params.asset, params.user, params.position, params.amount, reserve.borrowRate);

    borrowed.assets = params.amount;
  }

  /**
   * @notice Implements the repay feature. Repaying transfers the underlying back to the aToken and clears the
   * equivalent amount of debt for the user by burning the corresponding debt token.
   * @dev  Emits the `Repay()` event
   * @param reserve The state of the reserve
   * @param balances The balance of the position
   * @param totalSupplies The total supply of the reserve
   * @param params The additional parameters needed to execute the repay function
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @return payback The actual amount being repaid
   */
  function executeRepay(
    DataTypes.ReserveData storage reserve,
    DataTypes.PositionBalance storage balances,
    DataTypes.ReserveSupplies storage totalSupplies,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteRepayParams memory params
  ) external returns (DataTypes.SharesType memory payback) {
    DataTypes.ReserveCache memory cache = reserve.cache(totalSupplies);
    reserve.updateState(params.reserveFactor, cache);
    payback.assets = balances.getDebtBalance(cache.nextBorrowIndex);

    // Allows a user to max repay without leaving dust from interest.
    if (params.amount == type(uint256).max) {
      params.amount = payback.assets;
    }

    ValidationLogic.validateRepay(params.amount, payback.assets);

    // If paybackAmount is more than what the user wants to payback, the set it to the
    // user input (ie params.amount)
    if (params.amount < payback.assets) payback.assets = params.amount;

    reserve.updateInterestRates(
      totalSupplies,
      cache,
      params.asset,
      IPool(params.pool).getReserveFactor(),
      payback.assets,
      0,
      params.position,
      params.data.interestRateData
    );

    // update balances and total supplies
    payback.shares = balances.repayDebt(totalSupplies, payback.assets, cache.nextBorrowIndex);
    cache.nextDebtShares = totalSupplies.debtShares;

    if (balances.getDebtBalance(cache.nextBorrowIndex) == 0) {
      userConfig.setBorrowing(reserve.id, false);
    }

    IERC20(params.asset).safeTransferFrom(msg.sender, address(this), payback.assets);
    emit PoolEventsLib.Repay(params.asset, params.position, msg.sender, payback.assets);
  }
}
