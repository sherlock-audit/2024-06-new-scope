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

import {MathLib} from './MathLib.sol';

/// @title SharesMathLib
/// @author ZeroLend
/// @custom:contact contact@zerolend.xyz
/// @notice Shares management library.
/// @dev This implementation mitigates share price manipulations, using OpenZeppelin's method of virtual shares:
/// https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack.
library SharesMathLib {
  using MathLib for uint256;

  /// @dev The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
  /// high precision computations.
  /// @dev Virtual shares can never be redeemed for the assets they are entitled to, but it is assumed the share price
  /// stays low enough not to inflate these assets to a significant value.
  /// @dev Warning: The assets to which virtual borrow shares are entitled behave like unrealizable bad debt.
  uint256 internal constant VIRTUAL_SHARES = 0;

  /// @dev A number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
  /// empty.
  uint256 internal constant VIRTUAL_ASSETS = 0;

  /// @dev Calculates the value of `shares` quoted in assets, rounding down.
  function toAssetsDown(uint256 shares, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
    if (totalShares == 0) {
      return 0;
    }
    return shares.mulDivDown(totalAssets + VIRTUAL_ASSETS, totalShares + VIRTUAL_SHARES);
  }

  /// @dev Calculates the value of `shares` quoted in assets, rounding up.
  function toAssetsUp(uint256 shares, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
    if (totalShares == 0) {
      return 0;
    }
    return shares.mulDivUp(totalAssets + VIRTUAL_ASSETS, totalShares + VIRTUAL_SHARES);
  }
}
