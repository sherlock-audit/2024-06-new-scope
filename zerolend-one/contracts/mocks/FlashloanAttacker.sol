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

import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import {FlashLoanSimpleReceiverBase} from '../core/FlashLoanSimpleReceiverBase.sol';

import {DataTypes} from '../core/pool/configuration/DataTypes.sol';
import {IPool} from '../interfaces/pool/IPool.sol';
import {MintableERC20} from './MintableERC20.sol';

contract FlashloanAttacker {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // IPoolAddressesProvider internal _provider;
  IPool internal _pool;

  // constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {
  //   _pool = IPool(provider.getPool());
  // }

  function supplyAsset(address asset, uint256 amount) public {
    MintableERC20 token = MintableERC20(asset);
    token.mint(address(this), amount);
    token.approve(address(_pool), type(uint256).max);
    // _pool.supply(asset, amount, address(this), 0);
  }

  // function _innerBorrow(address asset) internal view {
  //   // DataTypes.ReserveData memory config = _pool.getReserveData(asset);
  //   // IERC20 token = IERC20(asset);
  //   // uint256 avail = token.balanceOf(config.nftPositionManager);
  //   // _pool.borrow(asset, avail, 0, address(this));
  // }

  // function executeOperation(
  //   address asset,
  //   uint256 amount,
  //   uint256 premium,
  //   address, // initiator
  //   bytes memory // params
  // ) public returns (bool) {
  //   // MintableERC20 token = MintableERC20(asset);
  //   // uint256 amountToReturn = amount.add(premium);

  //   // // Also do a normal borrow here in the middle
  //   // _innerBorrow(asset);

  //   // token.mint(premium);
  //   // // IERC20(asset).approve(address(POOL), amountToReturn);

  //   return true;
  // }
}
