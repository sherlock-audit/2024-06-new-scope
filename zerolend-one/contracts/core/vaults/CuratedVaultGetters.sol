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

import {DataTypes, IPool} from '../../interfaces/pool/IPool.sol';

import {ICuratedVaultBase} from '../../interfaces/vaults/ICuratedVaultBase.sol';

import {CuratedVaultBase, ERC4626Upgradeable} from './CuratedVaultBase.sol';
import {SharesMathLib} from './libraries/SharesMathLib.sol';
import {UtilsLib} from './libraries/UtilsLib.sol';
import {IERC4626Upgradeable, MathUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract CuratedVaultGetters is CuratedVaultBase {
  using MathUpgradeable for uint256;
  using UtilsLib for uint256;
  using SharesMathLib for uint256;

  function revision() external pure virtual returns (uint256) {
    return 1;
  }

  /* EXTERNAL */

  /// @inheritdoc ICuratedVaultBase
  function supplyQueueLength() external view returns (uint256) {
    return supplyQueue.length;
  }

  /// @inheritdoc ICuratedVaultBase
  function withdrawQueueLength() external view returns (uint256) {
    return withdrawQueue.length;
  }

  /* ERC4626Upgradeable (PUBLIC) */

  /// @inheritdoc IERC4626Upgradeable
  /// @dev Warning: May be higher than the actual max deposit due to duplicate markets in the supplyQueue.
  function maxDeposit(address) public view override returns (uint256) {
    return _maxDeposit();
  }

  /// @inheritdoc IERC4626Upgradeable
  /// @dev Warning: May be higher than the actual max mint due to duplicate markets in the supplyQueue.
  function maxMint(address) public view override returns (uint256) {
    uint256 suppliable = _maxDeposit();
    return _convertToShares(suppliable, MathUpgradeable.Rounding.Down);
  }

  /// @inheritdoc IERC4626Upgradeable
  /// @dev Warning: May be lower than the actual amount of assets that can be withdrawn by `owner` due to conversion
  /// roundings between shares and assets.
  function maxWithdraw(address owner) public view override returns (uint256 assets) {
    (assets,,) = _maxWithdraw(owner);
  }

  /// @inheritdoc IERC4626Upgradeable
  /// @dev Warning: May be lower than the actual amount of shares that can be redeemed by `owner` due to conversion
  /// roundings between shares and assets.
  function maxRedeem(address owner) public view override returns (uint256) {
    (uint256 assets, uint256 newTotalSupply, uint256 newTotalAssets) = _maxWithdraw(owner);
    return _convertToSharesWithTotals(assets, newTotalSupply, newTotalAssets, MathUpgradeable.Rounding.Down);
  }

  /* ERC4626Upgradeable (INTERNAL) */

  /// @dev Returns the maximum amount of asset (`assets`) that the `owner` can withdraw from the vault, as well as the
  /// new vault's total supply (`newTotalSupply`) and total assets (`newTotalAssets`).
  function _maxWithdraw(address owner) internal view returns (uint256 assets, uint256 newTotalSupply, uint256 newTotalAssets) {
    uint256 feeShares;
    (feeShares, newTotalAssets) = _accruedFeeShares();
    newTotalSupply = totalSupply() + feeShares;

    assets = _convertToAssetsWithTotals(balanceOf(owner), newTotalSupply, newTotalAssets, MathUpgradeable.Rounding.Down);
    assets -= _simulateWithdraw(assets);
  }

  /// @notice simulates a withdraw of `assets` from ZeroLend.
  /// @return The remaining assets to be withdrawn.
  function _simulateWithdraw(uint256 assets) internal view returns (uint256) {
    for (uint256 i; i < withdrawQueue.length; ++i) {
      IPool pool = withdrawQueue[i];

      // get info on how much shares this contract has
      DataTypes.PositionBalance memory pos = pool.getBalanceRawByPositionId(asset(), positionId);
      uint256 supplyShares = pos.supplyShares;

      // get info on how much shares and asset the pool has
      (uint256 totalSupplyAssets, uint256 totalSupplyShares, uint256 totalBorrowAssets,) = pool.marketBalances(asset());

      // The vault withdrawing from ZeroLend cannot fail because:
      // 1. oracle.price() is never called (the vault doesn't borrow)
      // 2. the amount is capped to the liquidity available on ZeroLend
      // 3. virtually accruing interest didn't fail
      assets = assets.zeroFloorSub(
        _withdrawable(pool, totalSupplyAssets, totalBorrowAssets, supplyShares.toAssetsDown(totalSupplyAssets, totalSupplyShares))
      );

      if (assets == 0) break;
    }

    return assets;
  }

  /// @dev Returns the withdrawable amount of assets from the market defined by `pool`, given the market's
  /// total supply and borrow assets and the vault's assets supplied.
  function _withdrawable(
    IPool pool,
    uint256 totalSupplyAssets,
    uint256 totalBorrowAssets,
    uint256 supplyAssets
  ) internal view returns (uint256) {
    // Inside a flashloan callback, liquidity on the pool may be limited to the singleton's balance.
    uint256 availableLiquidity = UtilsLib.min(totalSupplyAssets - totalBorrowAssets, IERC20(asset()).balanceOf(address(pool)));
    return UtilsLib.min(supplyAssets, availableLiquidity);
  }

  /// @dev Returns the maximum amount of assets that the vault can supply on ZeroLend.
  function _maxDeposit() internal view returns (uint256 totalSuppliable) {
    for (uint256 i; i < supplyQueue.length; ++i) {
      IPool pool = supplyQueue[i];

      uint256 supplyCap = config[pool].cap;
      if (supplyCap == 0) continue;

      uint256 supplyShares = pool.supplyShares(asset(), positionId);
      (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = pool.marketBalances(asset());

      // `supplyAssets` needs to be rounded up for `totalSuppliable` to be rounded down.
      uint256 supplyAssets = supplyShares.toAssetsUp(totalSupplyAssets, totalSupplyShares);
      totalSuppliable += supplyCap.zeroFloorSub(supplyAssets);
    }
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The accrual of performance fees is taken into account in the conversion.
  function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view override returns (uint256) {
    (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
    return _convertToSharesWithTotals(assets, totalSupply() + feeShares, newTotalAssets, rounding);
  }

  /// @inheritdoc ERC4626Upgradeable
  /// @dev The accrual of performance fees is taken into account in the conversion.
  function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view override returns (uint256) {
    (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
    return _convertToAssetsWithTotals(shares, totalSupply() + feeShares, newTotalAssets, rounding);
  }

  /// @dev Returns the amount of shares that the vault would exchange for the amount of `assets` provided.
  /// @dev It assumes that the arguments `newTotalSupply` and `newTotalAssets` are up to date.
  function _convertToSharesWithTotals(
    uint256 assets,
    uint256 newTotalSupply,
    uint256 newTotalAssets,
    MathUpgradeable.Rounding rounding
  ) internal view returns (uint256) {
    return assets.mulDiv(newTotalSupply + 10 ** _decimalsOffset(), newTotalAssets + 1, rounding);
  }

  /// @dev Returns the amount of assets that the vault would exchange for the amount of `shares` provided.
  /// @dev It assumes that the arguments `newTotalSupply` and `newTotalAssets` are up to date.
  function _convertToAssetsWithTotals(
    uint256 shares,
    uint256 newTotalSupply,
    uint256 newTotalAssets,
    MathUpgradeable.Rounding rounding
  ) internal view returns (uint256) {
    return shares.mulDiv(newTotalAssets + 1, newTotalSupply + 10 ** _decimalsOffset(), rounding);
  }

  /// @dev Computes and returns the fee shares (`feeShares`) to mint and the new vault's total assets
  /// (`newTotalAssets`).
  function _accruedFeeShares() internal view returns (uint256 feeShares, uint256 newTotalAssets) {
    newTotalAssets = totalAssets();

    uint256 totalInterest = newTotalAssets.zeroFloorSub(lastTotalAssets);
    if (totalInterest != 0 && fee != 0) {
      // It is acknowledged that `feeAssets` may be rounded down to 0 if `totalInterest * fee < WAD`.
      uint256 feeAssets = totalInterest.mulDiv(fee, 1e18);
      // The fee assets is subtracted from the total assets in this calculation to compensate for the fact
      // that total assets is already increased by the total interest (including the fee assets).
      feeShares = _convertToSharesWithTotals(feeAssets, totalSupply(), newTotalAssets - feeAssets, MathUpgradeable.Rounding.Down);
    }
  }
}
