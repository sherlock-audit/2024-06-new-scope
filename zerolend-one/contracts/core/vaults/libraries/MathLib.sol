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

uint256 constant WAD = 1e18;

/// @title MathLib
/// @author ZeroLend
/// @custom:contact contact@zerolend.xyz
/// @notice Library to manage fixed-point arithmetic.
library MathLib {
  /// @dev Returns (`x` * `y`) / `WAD` rounded down.
  function wMulDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, y, WAD);
  }

  /// @dev Returns (`x` * `WAD`) / `y` rounded down.
  function wDivDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, WAD, y);
  }

  /// @dev Returns (`x` * `WAD`) / `y` rounded up.
  function wDivUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, WAD, y);
  }

  /// @dev Returns (`x` * `y`) / `d` rounded down.
  function mulDivDown(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
    return (x * y) / d;
  }

  /// @dev Returns (`x` * `y`) / `d` rounded up.
  function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
    return (x * y + (d - 1)) / d;
  }
}
