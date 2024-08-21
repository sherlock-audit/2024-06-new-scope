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

/// @title ConstantsLib
/// @notice Library exposing constants.
library ConstantsLib {
  /// @dev The maximum delay of a timelock.
  uint256 internal constant MAX_TIMELOCK = 2 weeks;

  /// @dev The minimum delay of a timelock.
  uint256 internal constant MIN_TIMELOCK = 1 days;

  /// @dev The maximum number of markets in the supply/withdraw queue.
  uint256 internal constant MAX_QUEUE_LENGTH = 30;

  /// @dev The maximum fee the vault can have (50%).
  uint256 internal constant MAX_FEE = 0.5e18;
}
