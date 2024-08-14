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

import {DataTypes} from '../configuration/DataTypes.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';

/**
 * @title ReserveSuppliesConfiguration
 * @author ZeroLend
 * @notice Used to do math between the total supply/debt shares
 */
library ReserveSuppliesConfiguration {
  using WadRayMath for uint256;

  /**
   * @notice Get the rebased assets worth of collateral the position has
   * @dev Converts `shares` into `amount` and returns the rebased value
   * @param self The position to fetch the value for
   * @param index The current liquidity index
   */
  function getSupplyBalance(DataTypes.ReserveSupplies storage self, uint256 index) internal view returns (uint256 supply) {
    supply = self.supplyShares.rayMul(index);
  }

  /**
   * @notice Get the rebased assets worth of debt the position has
   * @dev Converts `shares` into `amount` and returns the rebased value
   * @param self The position to fetch the value for
   * @param index The current liquidity index
   */
  function getDebtBalance(DataTypes.ReserveSupplies storage self, uint256 index) internal view returns (uint256 debt) {
    debt = self.debtShares.rayMul(index);
  }
}
