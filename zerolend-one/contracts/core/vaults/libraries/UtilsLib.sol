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

/// @title UtilsLib
/// @author ZeroLend
/// @custom:contact contact@zerolend.xyz
/// @notice Library exposing helpers.
/// @dev Inspired by https://github.com/morpho-org/morpho-utils.
library UtilsLib {
  /// @dev Returns the min of `x` and `y`.
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := xor(x, mul(xor(x, y), lt(y, x)))
    }
  }

  /// @dev Returns max(0, x - y).
  function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := mul(gt(x, y), sub(x, y))
    }
  }
}
