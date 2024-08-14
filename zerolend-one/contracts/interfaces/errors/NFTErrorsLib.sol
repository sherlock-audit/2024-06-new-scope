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

/**
 * @title NFTErrorsLib
 * @notice Defines the errors for the NFTPositionManager
 */
library NFTErrorsLib {
  /**
   * @notice Error indicating that the caller is not the owner or approved operator of the token ID.
   */
  error NotTokenIdOwner();

  /**
   * @notice Error indicating that a zero address was provided, which is not allowed.
   */
  error ZeroAddressNotAllowed();

  /**
   * @notice Error indicating that a zero value was provided, which is not allowed.
   */
  error ZeroValueNotAllowed();

  /**
   * @notice Error indicating a mismatch in balance.
   */
  error BalanceMisMatch();

  /**
   * @notice Error indicating that the position is not cleared.
   */
  error PositionNotCleared();

  /**
   * @notice Error indicating that pool is not register in pool factory.
   */
  error NotPool();

  /**
   * @notice Error indicating that sending ETH is failed
   */
  error SendETHFailed(uint256 value);

  /**
   * @notice Error indication that the amount sent and the amount in params
   * are not equal.
   */
  error UnequalAmountNotAllowed();
}
