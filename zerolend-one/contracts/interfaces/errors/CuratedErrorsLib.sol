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

import {IPool} from '../pool/IPool.sol';

/**
 * @title CuratedErrorsLib
 * @notice Defines the errors for a Curated Vault.
 */
library CuratedErrorsLib {
  /// @notice Thrown when the address passed is the zero address.
  error ZeroAddress();

  /// @notice Thrown when the caller doesn't have the curator role.
  error NotCuratorRole();

  /// @notice Thrown when the caller doesn't have the allocator role.
  error NotAllocatorRole();

  /// @notice Thrown when the caller doesn't have the admin role.
  error NotOwnerRole();

  /// @notice Thrown when the caller doesn't have the guardian role.
  error NotGuardianRole();

  /// @notice Thrown when the caller doesn't have the curator nor the guardian role.
  error NotCuratorNorGuardianRole();

  /// @notice Thrown when the market `id` cannot be set in the supply queue.
  error UnauthorizedMarket(IPool id);

  /// @notice Thrown when submitting a cap for a market `id` whose loan token does not correspond to the underlying.
  /// asset.
  error InconsistentAsset(IPool id);

  /// @notice Thrown when the supply cap has been exceeded on market `id` during a reallocation of funds.
  error SupplyCapExceeded(IPool id);

  /// @notice Thrown when the fee to set exceeds the maximum fee.
  error MaxFeeExceeded();

  /// @notice Thrown when the value is already set.
  error AlreadySet();

  /// @notice Thrown when a value is already pending.
  error AlreadyPending();

  error MaxUint128Exceeded();

  /// @notice Thrown when submitting the removal of a market when there is a cap already pending on that market.
  error PendingCap(IPool id);

  /// @notice Thrown when submitting a cap for a market with a pending removal.
  error PendingRemoval();

  /// @notice Thrown when submitting a market removal for a market with a non zero cap.
  error NonZeroCap();

  /// @notice Thrown when market `id` is a duplicate in the new withdraw queue to set.
  error DuplicateMarket(IPool id);

  /// @notice Thrown when market `id` is missing in the updated withdraw queue and the market has a non-zero cap set.
  error InvalidMarketRemovalNonZeroCap(IPool id);

  /// @notice Thrown when market `id` is missing in the updated withdraw queue and the market has a non-zero supply.
  error InvalidMarketRemovalNonZeroSupply(IPool id);

  /// @notice Thrown when market `id` is missing in the updated withdraw queue and the market is not yet disabled.
  error InvalidMarketRemovalTimelockNotElapsed(IPool id);

  /// @notice Thrown when there's no pending value to set.
  error NoPendingValue();

  /// @notice Thrown when the requested liquidity cannot be withdrawn from ZeroLend.
  error NotEnoughLiquidity();

  /// @notice Thrown when submitting a cap for a market which does not exist.
  error MarketNotCreated();

  /// @notice Thrown when interacting with a non previously enabled market `id`.
  error MarketNotEnabled(IPool id);

  /// @notice Thrown when the submitted timelock is above the max timelock.
  error AboveMaxTimelock();

  /// @notice Thrown when the submitted timelock is below the min timelock.
  error BelowMinTimelock();

  /// @notice Thrown when the timelock is not elapsed.
  error TimelockNotElapsed();

  /// @notice Thrown when too many markets are in the withdraw queue.
  error MaxQueueLengthExceeded();

  /// @notice Thrown when setting the fee to a non zero value while the fee recipient is the zero address.
  error ZeroFeeRecipient();

  /// @notice Thrown when the amount withdrawn is not exactly the amount supplied.
  error InconsistentReallocation();

  /// @notice Thrown when all caps have been reached.
  error AllCapsReached();
}
