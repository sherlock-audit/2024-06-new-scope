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

import {DefaultReserveInterestRateStrategy} from './DefaultReserveInterestRateStrategy.sol';

contract FixedInterestRateStrategy is DefaultReserveInterestRateStrategy {
  /**
   * @dev Constructor.
   * @param baseBorrowRate The base borrow rate
   */
  constructor(uint256 baseBorrowRate) DefaultReserveInterestRateStrategy(0, baseBorrowRate, 0, 0) {}
}
