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

import {IERC721EnumerableUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

/**
 * @title INFTRewardsDistributor
 * @notice Defines the basic interface for a Rewards Distributor.
 */
interface INFTRewardsDistributor is IERC721EnumerableUpgradeable {
  event RewardAdded(bytes32 indexed assetHash, uint256 indexed reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(uint256 indexed tokenId, address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);

  // IERC20 external rewardsToken;
  // mapping(bytes32 assetHash => uint256) external lastUpdateTime;
  // mapping(bytes32 assetHash => uint256) external periodFinish;
  // mapping(bytes32 assetHash => uint256) external rewardPerTokenStored;
  // mapping(bytes32 assetHash => uint256) external rewardRate;
  // mapping(uint256 tokenId => mapping(bytes32 assetHash => uint256 rewards)) external rewards;

  // uint256 external rewardsDuration;

  function totalSupplyAssetForRewards(bytes32 _assetHash) external view returns (uint256);

  function balanceOfByAssetHash(uint256 tokenId, bytes32 _assetHash) external view returns (uint256);

  function lastTimeRewardApplicable(bytes32 _assetHash) external view returns (uint256);

  function rewardPerToken(bytes32 _assetHash) external view returns (uint256);

  function getReward(uint256 tokenId, bytes32 _assetHash) external returns (uint256 reward);

  function earned(uint256 tokenId, bytes32 _assetHash) external view returns (uint256);

  function getRewardForDuration(bytes32 _assetHash) external view returns (uint256);

  /**
   * @dev Calculates the boosted balance for an account.
   * @param account The address of the account for which to calculate the boosted balance.
   * @param balance The amount to boost.
   * @return The boosted balance of the account.
   */
  function boostedBalance(address account, uint256 balance) external view returns (uint256);

  function notifyRewardAmount(uint256 reward, address pool, address asset, bool isDebt) external;

  function assetHash(address pool, address asset, bool isDebt) external pure returns (bytes32);
}
