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

import {DataTypes, IPool} from '../../interfaces/IPoolFactory.sol';

import {NFTErrorsLib} from '../../interfaces/errors/NFTErrorsLib.sol';
import {NFTEventsLib} from '../../interfaces/events/NFTEventsLib.sol';
import {NFTRewardsDistributor} from './NFTRewardsDistributor.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract NFTPositionManagerSetters is NFTRewardsDistributor {
  using SafeERC20 for IERC20;

  /**
   * @dev Modifier to check if the caller is pool or not.
   * @param pool Address of the pool.
   */
  modifier isPool(address pool) {
    if (!factory.isPool(pool)) {
      revert NFTErrorsLib.NotPool();
    }
    _;
  }

  /**
   * @notice Handles the liquidity operations including transferring tokens, approving the pool, and updating balances.
   * @dev Anyone can supply tokens for a user.
   * @param params The liquidity parameters including asset, pool, user, amount, and tokenId.
   * @custom:event Supply emitted whenever user supply asset
   */
  function _supply(AssetOperationParams memory params) internal nonReentrant {
    if (params.amount == 0) revert NFTErrorsLib.ZeroValueNotAllowed();
    if (params.tokenId == 0) {
      if (msg.sender != _ownerOf(_nextId - 1)) revert NFTErrorsLib.NotTokenIdOwner();
      params.tokenId = _nextId - 1;
    }

    IPool pool = IPool(_positions[params.tokenId].pool);

    IERC20(params.asset).forceApprove(address(pool), params.amount);
    pool.supply(params.asset, address(this), params.amount, params.tokenId, params.data);

    // update incentives
    uint256 balance = pool.getBalance(params.asset, address(this), params.tokenId);
    _handleSupplies(address(pool), params.asset, params.tokenId, balance);

    emit NFTEventsLib.Supply(params.asset, params.tokenId, params.amount);
  }

  function _borrow(AssetOperationParams memory params) internal nonReentrant {
    if (params.target == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    if (params.amount == 0) revert NFTErrorsLib.ZeroValueNotAllowed();
    if (params.tokenId == 0) {
      if (msg.sender != _ownerOf(_nextId - 1)) revert NFTErrorsLib.NotTokenIdOwner();
      params.tokenId = _nextId - 1;
    }

    // check permissions
    _isAuthorizedForToken(params.tokenId);

    IPool pool = IPool(_positions[params.tokenId].pool);
    pool.borrow(params.asset, params.target, params.amount, params.tokenId, params.data);

    // update incentives
    uint256 balance = pool.getDebt(params.asset, address(this), params.tokenId);
    _handleDebt(address(pool), params.asset, params.tokenId, balance);

    emit NFTEventsLib.Borrow(params.asset, params.amount, params.tokenId);
  }

  function _withdraw(AssetOperationParams memory params) internal nonReentrant {
    if (params.amount == 0) revert NFTErrorsLib.ZeroValueNotAllowed();
    if (params.target == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    if (params.tokenId == 0) {
      if (msg.sender != _ownerOf(_nextId - 1)) revert NFTErrorsLib.NotTokenIdOwner();
      params.tokenId = _nextId - 1;
    }

    // check permissions
    _isAuthorizedForToken(params.tokenId);

    IPool pool = IPool(_positions[params.tokenId].pool);
    pool.withdraw(params.asset, params.target, params.amount, params.tokenId, params.data);

    // update incentives
    uint256 balance = pool.getBalance(params.asset, address(this), params.tokenId);
    _handleSupplies(address(pool), params.asset, params.tokenId, balance);

    emit NFTEventsLib.Withdraw(params.asset, params.amount, params.tokenId);
  }

  function _repay(AssetOperationParams memory params) internal nonReentrant {
    if (params.amount == 0) revert NFTErrorsLib.ZeroValueNotAllowed();
    if (params.tokenId == 0) {
      if (msg.sender != _ownerOf(_nextId - 1)) revert NFTErrorsLib.NotTokenIdOwner();
      params.tokenId = _nextId - 1;
    }

    Position memory userPosition = _positions[params.tokenId];

    IPool pool = IPool(userPosition.pool);
    IERC20 asset = IERC20(params.asset);

    asset.forceApprove(userPosition.pool, params.amount);

    uint256 previousDebtBalance = pool.getDebt(params.asset, address(this), params.tokenId);
    DataTypes.SharesType memory repaid = pool.repay(params.asset, params.amount, params.tokenId, params.data);
    uint256 currentDebtBalance = pool.getDebt(params.asset, address(this), params.tokenId);

    if (previousDebtBalance - currentDebtBalance != repaid.assets) {
      revert NFTErrorsLib.BalanceMisMatch();
    }

    if (currentDebtBalance == 0 && repaid.assets < params.amount) {
      asset.safeTransfer(msg.sender, params.amount - repaid.assets);
    }

    // update incentives
    _handleDebt(address(pool), params.asset, params.tokenId, currentDebtBalance);

    emit NFTEventsLib.Repay(params.asset, params.amount, params.tokenId);
  }

  function _isAuthorizedForToken(uint256 tokenId) internal view {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NFTErrorsLib.NotTokenIdOwner();
  }
}
