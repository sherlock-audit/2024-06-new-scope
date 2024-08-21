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

import {DataTypes} from '../core/pool/configuration/DataTypes.sol';
import {INFTRewardsDistributor} from './INFTRewardsDistributor.sol';

interface INFTPositionManager is INFTRewardsDistributor {
  /**
   * @notice Parameters required for minting a new position token.
   * @param asset The address of the asset to be supplied.
   * @param pool The address of the pool where the asset will be supplied.
   * @param amount The amount of the asset to be supplied.
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   */
  struct MintParams {
    address asset;
    address pool;
    uint256 amount;
    DataTypes.ExtraData data;
  }

  /**
   * @notice Parameters required for handling liquidity operations.
   * @param asset The address of the asset involved in the operation.
   * @param pool The address of the pool where the operation is being performed.
   * @param user The address of the user performing the operation.
   * @param amount The amount of the asset involved in the operation.
   * @param tokenId The ID of the position token related to the operation.
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   */
  struct LiquidityParams {
    address asset;
    address pool;
    uint256 amount;
    uint256 tokenId;
    DataTypes.ExtraData data;
  }

  /**
   * @notice Structure representing an asset in a user's position.
   * @param asset The address of the asset.
   * @param balance The balance of the asset in the position.
   * @param debt The debt of the asset in the position.
   */
  struct Asset {
    address asset;
    uint256 balance;
    uint256 debt;
  }

  /**
   * @notice Structure representing a user's position, including assets, pool, and operator.
   * @param pool The address of the pool associated with the position.
   * @param operator The address of the operator managing the position.
   */
  struct Position {
    address pool;
    address operator;
  }

  /**
   * @notice Parameters required for various asset operations (add liquidity, borrow, repay, withdraw) against a position.
   * @param asset The address of the asset involved in the operation.
   * @param target Optional argument. For withdraw it is the address of the user receiving the asset.
   * @param amount The amount of the asset involved in the operation.
   * @param tokenId The ID of the position token involved in the operation.
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   */
  struct AssetOperationParams {
    address asset;
    address target;
    uint256 amount;
    uint256 tokenId;
    DataTypes.ExtraData data;
  }

  /**
   * @notice Initializes the NFTPositionManager contract.
   */
  function initialize(address _factory, address _staking, address _owner, address _zero, address _weth) external;

  /**
   * @notice Mints a new NFT representing a liquidity position.
   * @param pool The pool to mint a position ID for
   * @return tokenId The ID of the newly minted token.
   * @custom:error ZeroAddressNotAllowed error thrown if asset address is zero address.
   * @custom:error ZeroValueNotAllowed error thrown if the  amount is zero.
   */
  function mint(address pool) external returns (uint256 tokenId);

  /**
   * @notice Allow User to increase liquidity in the postion
   * @param params  The parameters required for increase liquidity the position, including the token, pool, amount and asset.
   * @custom:error ZeroAddressNotAllowed error thrown if asset address is zero address.
   * @custom:error ZeroValueNotAllowed error thrown if the  amount is zero.
   */
  function supply(AssetOperationParams memory params) external;

  /**
   * @notice Allow user to borrow the underlying assets
   * @param params The params required for borrow the position which includes tokenId, market and amount
   * @custom:error ZeroAddressNotAllowed error thrown asset address is zero address.
   * @custom:error ZeroValueNotAllowed error thrown if the  amount is zero.
   * @custom:error BalanceMisMatch error thrown if difference of currentDebtBalance and previousDebtBalance is not equal to amount
   * @custom:event BorrowIncreased emitted whenever user borrows asset
   */
  function borrow(AssetOperationParams memory params) external;

  /**
   * @notice Allow user to withdraw their underlying assets.
   * @param params The parameters required for withdrawing from the position, including tokenId, asset, and amount.
   * @custom:error ZeroAddressNotAllowed error thrown if asset or user address is zero address.
   * @custom:error ZeroValueNotAllowed error thrown if the  amount is zero.
   * @custom:error BalanceMisMatch error thrown if difference of previousSupplyBalance currentSupplyBalance and  is not equal to amount
   * @custom:event Withdrawal emitted whenever user withdraws asset
   */
  function withdraw(AssetOperationParams memory params) external;

  /**
   * @notice Allow user to repay thier debt.
   * @param params The params required for repaying the position which includes tokenId, asset and amount.
   * @custom:error ZeroAddressNotAllowed error thrown if asset address is zero address.
   * @custom:error ZeroValueNotAllowed error thrown if the  amount is zero.
   * @custom:error BalanceMisMatch error thrown if difference of previousDebtBalance currentDebtBalance and is not equal to amount
   * @custom:event Repay emitted whenever user repays asset
   */
  function repay(AssetOperationParams memory params) external;

  function positions(uint256 tokenId) external view returns (Position memory);

  /**
   *
   */
  function repayETH(AssetOperationParams memory params) external payable;

  /**
   *
   */
  function borrowETH(AssetOperationParams memory params) external payable;

  /**
   *
   */
  function supplyETH(AssetOperationParams memory params) external payable;

  /**
   *
   */
  function withdrawETH(AssetOperationParams memory params) external payable;

  function sweep(address token) external;
}
