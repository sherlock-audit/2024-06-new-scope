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

import {PercentageMath} from '../../core/pool/utils/PercentageMath.sol';
import {WadRayMath} from '../../core/pool/utils/WadRayMath.sol';
import {IDefaultInterestRateStrategy} from '../../interfaces/IDefaultInterestRateStrategy.sol';

/**
 * @title DiscountedInterestRateStrategy contract
 * @notice Implements an interest rate strategy that takes into account a
 * discount given how much ZERO a user has staked.
 */
abstract contract DiscountedInterestRateStrategy is IDefaultInterestRateStrategy {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // todo
}
