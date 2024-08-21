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
 * @title IIncentivesController
 * @notice Defines the basic interface for an Incentives Controller.
 * @dev It only contains one single function, needed as a hook on aToken and debtToken transfers.
 */
interface IIncentivesController {
  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   */
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
}
