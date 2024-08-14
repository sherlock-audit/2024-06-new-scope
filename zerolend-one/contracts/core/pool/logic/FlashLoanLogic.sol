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

import {IFlashLoanSimpleReceiver} from '../../../interfaces/IFlashLoanSimpleReceiver.sol';
import {IPool} from '../../../interfaces/pool/IPool.sol';

import {PoolErrorsLib} from '../../../interfaces/errors/PoolErrorsLib.sol';
import {DataTypes} from '../configuration/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';

import {PoolEventsLib} from '../../../interfaces/events/PoolEventsLib.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

/**
 * @title FlashLoanLogic library
 * @notice Implements the logic for the flash loans
 */
library FlashLoanLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;

  // Helper struct for internal variables used in the `executeFlashLoan` function
  struct FlashLoanLocalVars {
    IFlashLoanSimpleReceiver receiver;
    uint256 i;
    address currentAsset;
    uint256 currentAmount;
    uint256[] totalPremiums;
    uint256 flashloanPremiumTotal;
  }

  /**
   * @notice Implements the simple flashloan feature that allow users to access liquidity of ONE reserve for one
   * transaction as long as the amount taken plus fee is returned.
   * @dev Does not waive fee for approved flashborrowers nor allow taking on debt instead of repaying to save gas
   * @dev At the end of the transaction the pool will pull amount borrowed + fee from the receiver,
   * if the receiver have not approved the pool the transaction will revert.
   * @dev Emits the `FlashLoan()` event
   * @param _reserve The state of the flashloaned reserve
   * @param _params The additional parameters needed to execute the simple flashloan function
   */
  function executeFlashLoanSimple(
    address _pool,
    DataTypes.ReserveData storage _reserve,
    DataTypes.ReserveSupplies storage _totalSupplies,
    DataTypes.FlashloanSimpleParams memory _params
  ) external {
    // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
    // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
    // This is done to protect against reentrance and rate manipulation within the user specified payload.

    ValidationLogic.validateFlashloanSimple(_reserve);

    IFlashLoanSimpleReceiver receiver = IFlashLoanSimpleReceiver(_params.receiverAddress);
    uint256 totalPremium = _params.amount.percentMul(_params.flashLoanPremiumTotal);
    IERC20(_params.asset).safeTransfer(_params.receiverAddress, _params.amount);

    require(
      receiver.executeOperation(_params.asset, _params.amount, totalPremium, msg.sender, _params.params),
      PoolErrorsLib.INVALID_FLASHLOAN_EXECUTOR_RETURN
    );

    _handleFlashLoanRepayment(
      _reserve,
      _totalSupplies,
      DataTypes.FlashLoanRepaymentParams({
        reserveFactor: _params.reserveFactor,
        pool: _pool,
        asset: _params.asset,
        receiverAddress: _params.receiverAddress,
        amount: _params.amount,
        totalPremium: totalPremium
      })
    );
  }

  /**
   * @notice Handles repayment of flashloaned assets + premium
   * @dev Will pull the amount + premium from the receiver, so must have approved pool
   * @param _reserve The state of the flashloaned reserve
   * @param _params The additional parameters needed to execute the repayment function
   */
  function _handleFlashLoanRepayment(
    DataTypes.ReserveData storage _reserve,
    DataTypes.ReserveSupplies storage _totalSupplies,
    DataTypes.FlashLoanRepaymentParams memory _params
  ) internal {
    uint256 amountPlusPremium = _params.amount + _params.totalPremium;

    DataTypes.ReserveCache memory cache = _reserve.cache(_totalSupplies);
    _reserve.updateState(_params.reserveFactor, cache);

    _reserve.accruedToTreasuryShares += _params.totalPremium.rayDiv(cache.nextLiquidityIndex).toUint128();

    _reserve.updateInterestRates(_totalSupplies, cache, _params.asset, IPool(_params.pool).getReserveFactor(), amountPlusPremium, 0, '', '');

    IERC20(_params.asset).safeTransferFrom(_params.receiverAddress, address(_params.pool), amountPlusPremium);

    emit PoolEventsLib.FlashLoan(_params.receiverAddress, msg.sender, _params.asset, _params.amount, _params.totalPremium);
  }
}
