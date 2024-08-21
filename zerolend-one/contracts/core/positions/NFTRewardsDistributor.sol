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

import {NFTPositionManagerGetters} from './NFTPositionManagerGetters.sol';

import {AccessControlEnumerableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {
  ERC721EnumerableUpgradeable,
  IERC165Upgradeable
} from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title NFTRewardsDistributor
 * @notice Accounting contract to manage multiple staking distributions with multiple rewards
 * @author ZeroLend
 */
abstract contract NFTRewardsDistributor is
  ReentrancyGuardUpgradeable,
  ERC721EnumerableUpgradeable,
  AccessControlEnumerableUpgradeable,
  NFTPositionManagerGetters
{
  using SafeMath for uint256;

  function __NFTRewardsDistributor_init(
    uint256 maxBoostRequirement_,
    address staking_,
    uint256 rewardsDuration_,
    address rewardsToken_
  ) internal onlyInitializing {
    maxBoostRequirement = maxBoostRequirement_;
    stakingToken = IVotes(staking_);
    rewardsToken = IERC20(rewardsToken_);
    rewardsDuration = rewardsDuration_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC721EnumerableUpgradeable, IERC165Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function totalSupplyAssetForRewards(bytes32 _assetHash) external view returns (uint256) {
    return _totalSupply[_assetHash];
  }

  function balanceOfByAssetHash(uint256 tokenId, bytes32 _assetHash) external view returns (uint256) {
    return _balances[tokenId][_assetHash];
  }

  function lastTimeRewardApplicable(bytes32 _assetHash) public view returns (uint256) {
    return block.timestamp < periodFinish[_assetHash] ? block.timestamp : periodFinish[_assetHash];
  }

  function rewardPerToken(bytes32 _assetHash) public view returns (uint256) {
    if (_totalSupply[_assetHash] == 0) {
      return rewardPerTokenStored[_assetHash];
    }
    return rewardPerTokenStored[_assetHash].add(
      lastTimeRewardApplicable(_assetHash).sub(lastUpdateTime[_assetHash]).mul(rewardRate[_assetHash]).mul(1e18).div(
        _totalSupply[_assetHash]
      )
    );
  }

  function getReward(uint256 tokenId, bytes32 _assetHash) public nonReentrant returns (uint256 reward) {
    _updateReward(tokenId, _assetHash);
    reward = rewards[tokenId][_assetHash];
    if (reward > 0) {
      rewards[tokenId][_assetHash] = 0;
      rewardsToken.transfer(ownerOf(tokenId), reward);
      emit RewardPaid(tokenId, ownerOf(tokenId), reward);
    }
  }

  function earned(uint256 tokenId, bytes32 _assetHash) public view returns (uint256) {
    return _balances[tokenId][_assetHash].mul(rewardPerToken(_assetHash).sub(userRewardPerTokenPaid[tokenId][_assetHash])).div(1e18).add(
      rewards[tokenId][_assetHash]
    );
  }

  function getRewardForDuration(bytes32 _assetHash) external view returns (uint256) {
    return rewardRate[_assetHash].mul(rewardsDuration);
  }

  /**
   * @dev Calculates the boosted balance for an account.
   * @param account The address of the account for which to calculate the boosted balance.
   * @param balance The amount to boost.
   * @return The boosted balance of the account.
   */
  function boostedBalance(address account, uint256 balance) public view returns (uint256) {
    uint256 _boosted = (balance * 20) / 100;
    uint256 _stake = stakingToken.getVotes(account);

    uint256 _adjusted = ((balance * _stake * 80) / maxBoostRequirement) / 100;

    // because of this we are able to max out the boost by 5x
    uint256 _boostedBalance = _boosted + _adjusted;
    return _boostedBalance > balance ? balance : _boostedBalance;
  }

  function notifyRewardAmount(uint256 reward, address pool, address asset, bool isDebt) external onlyRole(REWARDS_ALLOCATOR_ROLE) {
    rewardsToken.transferFrom(msg.sender, address(this), reward);

    bytes32 _assetHash = assetHash(pool, asset, isDebt);
    _updateReward(0, _assetHash);

    if (block.timestamp >= periodFinish[_assetHash]) {
      rewardRate[_assetHash] = reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish[_assetHash].sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate[_assetHash]);
      rewardRate[_assetHash] = reward.add(leftover).div(rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate[_assetHash] <= balance.div(rewardsDuration), 'Provided reward too high');

    lastUpdateTime[_assetHash] = block.timestamp;
    periodFinish[_assetHash] = block.timestamp.add(rewardsDuration);
    emit RewardAdded(_assetHash, reward);
  }

  function _updateReward(uint256 _tokenId, bytes32 _assetHash) internal {
    rewardPerTokenStored[_assetHash] = rewardPerToken(_assetHash);
    lastUpdateTime[_assetHash] = lastTimeRewardApplicable(_assetHash);
    if (_tokenId != 0) {
      rewards[_tokenId][_assetHash] = earned(_tokenId, _assetHash);
      userRewardPerTokenPaid[_tokenId][_assetHash] = rewardPerTokenStored[_assetHash];
    }
  }

  function assetHash(address pool, address asset, bool isDebt) public pure returns (bytes32) {
    return keccak256(abi.encode(pool, asset, isDebt));
  }

  //// @inheritdoc IRewardsController
  function _handleSupplies(address pool, address asset, uint256 tokenId, uint256 balance) internal {
    bytes32 _assetHash = assetHash(pool, asset, false);
    uint256 _currentBalance = _balances[tokenId][_assetHash];

    _updateReward(tokenId, _assetHash);

    _balances[tokenId][_assetHash] = balance;
    _totalSupply[_assetHash] = _totalSupply[_assetHash] - _currentBalance + balance;
  }

  function _handleDebt(address pool, address asset, uint256 tokenId, uint256 balance) internal {
    bytes32 _assetHash = assetHash(pool, asset, true);
    uint256 _currentBalance = _balances[tokenId][_assetHash];

    _updateReward(tokenId, _assetHash);

    _balances[tokenId][_assetHash] = balance;
    _totalSupply[_assetHash] = _totalSupply[_assetHash] - _currentBalance + balance;
  }
}
