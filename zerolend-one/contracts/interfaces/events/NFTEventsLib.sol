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
 * @title NFTEventsLib
 * @notice Defines the events for the NFTPositionManager
 */
library NFTEventsLib {
  /**
   *
   * @param asset The address of the asset that we want to borrow.
   * @param tokenId  The ID of the position token.
   * @param amount The amount of the asset that we want to borrow.
   */
  event Borrow(address indexed asset, uint256 indexed amount, uint256 indexed tokenId);

  /**
   *
   * @param asset The address of the asset that we want to withdraw
   * @param amount The amount of asset that we want to withdraw
   * @param tokenId The ID of the NFT.
   *
   */
  event Withdraw(address indexed asset, uint256 indexed amount, uint256 tokenId);

  /**
   *
   * @param asset The address of the asset that we want to repay.
   * @param tokenId The ID of the NFT.
   * @param amount The amount of asset that we want to repay
   */
  event Repay(address indexed asset, uint256 indexed tokenId, uint256 indexed amount);

  /**
   * @notice Emitted when liquidity is increased for a specific position token.
   * @param asset The address of the asset for which liquidity was increased.
   * @param tokenId The ID of the position token.
   * @param amount The amount of the asset that was added to the position.
   */
  event Supply(address indexed asset, uint256 indexed tokenId, uint256 indexed amount);
}
