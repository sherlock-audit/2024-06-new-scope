// SPDX-License-Identifier: GPL-2.0-or-later
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

import {IPool} from '../../interfaces/pool/IPool.sol';

import {MarketConfig} from '../../interfaces/vaults/ICuratedVaultBase.sol';

import {SharesMathLib} from './libraries/SharesMathLib.sol';
import {UtilsLib} from './libraries/UtilsLib.sol';

import {CuratedErrorsLib} from '../../interfaces/errors/CuratedErrorsLib.sol';
import {CuratedEventsLib} from '../../interfaces/events/CuratedEventsLib.sol';
import {CuratedVaultGetters, ERC4626Upgradeable} from './CuratedVaultGetters.sol';

abstract contract CuratedVaultSetters is CuratedVaultGetters {
  using UtilsLib for uint256;
  using SharesMathLib for uint256;

  /* ERC4626Upgradeable (INTERNAL) */

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Used in mint or deposit to deposit the underlying asset to ZeroLend markets.
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
    super._deposit(caller, receiver, assets, shares);

    _supplyPool(assets);

    // `lastTotalAssets + assets` may be a little off from `totalAssets()`.
    _updateLastTotalAssets(lastTotalAssets + assets);
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev Used in redeem or withdraw to withdraw the underlying asset from ZeroLend markets.
  /// @dev Depending on 3 cases, reverts when withdrawing "too much" with:
  /// 1. NotEnoughLiquidity when withdrawing more than available liquidity.
  /// 2. ERC20InsufficientAllowance when withdrawing more than `caller`'s allowance.
  /// 3. ERC20InsufficientBalance when withdrawing more than `owner`'s balance.
  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    _withdrawPool(assets);
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  /* INTERNAL */

  /// @dev Accrues interest on ZeroLend and returns the vault's assets & corresponding shares supplied on the
  /// market defined by `pool`, as well as the market's state.
  /// @dev Assumes that the inputs `marketParams` and `pool` match.
  function _accruedSupplyBalance(IPool pool) internal returns (uint256 assets, uint256 shares) {
    // force update the rates and liquidity indexes
    pool.forceUpdateReserve(asset());

    shares = pool.supplyShares(asset(), positionId);

    // `supplyAssets` needs to be rounded up for `toSupply` to be rounded down.
    (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = pool.marketBalances(asset());
    assets = shares.toAssetsDown(totalSupplyAssets, totalSupplyShares);
  }

  /// @dev Reverts if `newTimelock` is not within the bounds.
  function _checkTimelockBounds(uint256 newTimelock) internal pure {
    if (newTimelock > MAX_TIMELOCK) revert CuratedErrorsLib.AboveMaxTimelock();
    if (newTimelock < MIN_TIMELOCK) revert CuratedErrorsLib.BelowMinTimelock();
  }

  /// @dev Sets `timelock` to `newTimelock`.
  function _setTimelock(uint256 newTimelock) internal {
    timelock = newTimelock;
    emit CuratedEventsLib.SetTimelock(_msgSender(), newTimelock);
    delete pendingTimelock;
  }

  /// @dev Sets the cap of the market defined by `pool` to `supplyCap`.
  function _setCap(IPool pool, uint184 supplyCap) internal {
    MarketConfig storage marketConfig = config[pool];

    if (supplyCap > 0) {
      if (!marketConfig.enabled) {
        withdrawQueue.push(pool);

        if (withdrawQueue.length > MAX_QUEUE_LENGTH) revert CuratedErrorsLib.MaxQueueLengthExceeded();

        marketConfig.enabled = true;

        // Take into account assets of the new market without applying a fee.
        pool.forceUpdateReserve(asset());
        uint256 supplyAssets = pool.supplyAssets(asset(), positionId);
        _updateLastTotalAssets(lastTotalAssets + supplyAssets);

        emit CuratedEventsLib.SetWithdrawQueue(msg.sender, withdrawQueue);
      }

      marketConfig.removableAt = 0;
    }

    marketConfig.cap = supplyCap;
    emit CuratedEventsLib.SetCap(_msgSender(), pool, supplyCap);
    delete pendingCap[pool];
  }

  /* LIQUIDITY ALLOCATION */

  /// @dev Supplies `assets` to ZeroLend.
  function _supplyPool(uint256 assets) internal {
    for (uint256 i; i < supplyQueue.length; ++i) {
      IPool pool = supplyQueue[i];

      uint256 supplyCap = config[pool].cap;
      if (supplyCap == 0) continue;

      pool.forceUpdateReserve(asset());

      uint256 supplyShares = pool.supplyShares(asset(), positionId);

      // `supplyAssets` needs to be rounded up for `toSupply` to be rounded down.
      (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = pool.marketBalances(asset());
      uint256 supplyAssets = supplyShares.toAssetsUp(totalSupplyAssets, totalSupplyShares);

      uint256 toSupply = UtilsLib.min(supplyCap.zeroFloorSub(supplyAssets), assets);

      if (toSupply > 0) {
        // Using try/catch to skip markets that revert.
        try pool.supplySimple(asset(), address(this), toSupply, 0) {
          assets -= toSupply;
        } catch {}
      }

      if (assets == 0) return;
    }

    if (assets != 0) revert CuratedErrorsLib.AllCapsReached();
  }

  /// @dev Withdraws `assets` from ZeroLend.
  function _withdrawPool(uint256 withdrawAmount) internal {
    for (uint256 i; i < withdrawQueue.length; ++i) {
      IPool pool = withdrawQueue[i];
      (uint256 supplyAssets,) = _accruedSupplyBalance(pool);
      uint256 toWithdraw =
        UtilsLib.min(_withdrawable(pool, pool.totalAssets(asset()), pool.totalDebt(asset()), supplyAssets), withdrawAmount);

      if (toWithdraw > 0) {
        // Using try/catch to skip markets that revert.
        try pool.withdrawSimple(asset(), address(this), toWithdraw, 0) {
          withdrawAmount -= toWithdraw;
        } catch {}
      }

      if (withdrawAmount == 0) return;
    }

    if (withdrawAmount != 0) revert CuratedErrorsLib.NotEnoughLiquidity();
  }

  /* FEE MANAGEMENT */

  /// @dev Updates `lastTotalAssets` to `updatedTotalAssets`.
  function _updateLastTotalAssets(uint256 updatedTotalAssets) internal {
    lastTotalAssets = updatedTotalAssets;
    emit CuratedEventsLib.UpdateLastTotalAssets(updatedTotalAssets);
  }

  /// @dev Accrues the fee and mints the fee shares to the fee recipient.
  /// @return newTotalAssets The vaults total assets after accruing the interest.
  function _accrueFee() internal returns (uint256 newTotalAssets) {
    uint256 feeShares;
    (feeShares, newTotalAssets) = _accruedFeeShares();
    if (feeShares != 0) _mint(feeRecipient, feeShares);
    emit CuratedEventsLib.AccrueInterest(newTotalAssets, feeShares);
  }
}
