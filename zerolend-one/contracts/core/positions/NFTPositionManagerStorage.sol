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

import {INFTPositionManager} from '../../interfaces/INFTPositionManager.sol';
import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';
import {IWETH} from '../../interfaces/IWETH.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract NFTPositionManagerStorage is INFTPositionManager {
  /// @dev the keccak256 hash of the allocator role.
  bytes32 public immutable REWARDS_ALLOCATOR_ROLE = keccak256('REWARDS_ALLOCATOR_ROLE');

  /// @notice The pool factory contract that is used to create pools.
  IPoolFactory public factory;

  /// @notice The ID of the next token that will be minted. Starts from 1 to avoid using 0 as a token ID.
  uint256 internal _nextId;

  /// @notice Mapping from token ID to the Position struct representing the details of the liquidity position.
  mapping(uint256 tokenId => Position position) internal _positions;

  /// @notice Address for the wrapped ether
  IWETH public weth;

  /* Reward Variables */

  /// @notice The ERC20 token used for rewards.
  IERC20 public rewardsToken;

  /// @notice The contract that holds the votes.
  IVotes internal stakingToken;

  /// @notice The list of assets for a pool that is eligible for rewards
  mapping(address pool => address[] assets) internal _poolAssetList;

  mapping(bytes32 assetHash => uint256) internal _totalSupply;
  mapping(bytes32 assetHash => uint256) public lastUpdateTime;
  mapping(bytes32 assetHash => uint256) public periodFinish;
  mapping(bytes32 assetHash => uint256) public rewardPerTokenStored;
  mapping(bytes32 assetHash => uint256) public rewardRate;
  mapping(uint256 tokenId => mapping(bytes32 assetHash => uint256)) internal _balances;
  mapping(uint256 tokenId => mapping(bytes32 assetHash => uint256)) public userRewardPerTokenPaid;
  mapping(uint256 tokenId => mapping(bytes32 assetHash => uint256)) public rewards;

  uint256 public maxBoostRequirement;
  uint256 public rewardsDuration;
}
