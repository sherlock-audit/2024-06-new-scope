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

import {PoolErrorsLib} from '../../../interfaces/errors/PoolErrorsLib.sol';
import {DataTypes} from '../configuration/DataTypes.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';

/**
 * @title PositionBalanceConfiguration
 * @author ZeroLend
 * @notice Used to do math between the supply/debt shares variables
 */
library PositionBalanceConfiguration {
  using WadRayMath for uint256;

  /**
   * @notice Deposits `amount` units of an asset as collateral for a position
   * @dev Converts `amount` into `shares` and `index` so that rebase values can be tracked properly.
   * @param self The position to update
   * @param totalSupply The total supply information of the asset
   * @param amount The amount to deposit
   * @param index The current liquidity index
   * @return isFirst True if this is the first supply for the position
   * @return sharesMinted How much shares was minted in this operation
   */
  function depositCollateral(
    DataTypes.PositionBalance storage self,
    DataTypes.ReserveSupplies storage totalSupply,
    uint256 amount,
    uint128 index
  ) internal returns (bool isFirst, uint256 sharesMinted) {
    sharesMinted = amount.rayDiv(index);
    require(sharesMinted != 0, PoolErrorsLib.INVALID_MINT_AMOUNT);
    isFirst = self.supplyShares == 0;
    self.lastSupplyLiquidtyIndex = index;
    self.supplyShares += sharesMinted;
    totalSupply.supplyShares += sharesMinted;
  }

  /**
   * @notice Borrows `amount` units of an asset as debt for a position
   * @dev Converts `amount` into `shares` and `index` so that rebase values can be tracked properly.
   * @param self The position to update
   * @param totalSupply The total supply information of the asset
   * @param amount The amount to borrow
   * @param index The current liquidity index
   * @return isFirst True if this is the first borrow for the position
   * @return sharesMinted How much shares was minted in this operation
   */
  function borrowDebt(
    DataTypes.PositionBalance storage self,
    DataTypes.ReserveSupplies storage totalSupply,
    uint256 amount,
    uint128 index
  ) internal returns (bool isFirst, uint256 sharesMinted) {
    sharesMinted = amount.rayDiv(index);
    require(sharesMinted != 0, PoolErrorsLib.INVALID_MINT_AMOUNT);
    isFirst = self.debtShares == 0;
    self.lastDebtLiquidtyIndex = index;
    self.debtShares += sharesMinted;
    totalSupply.debtShares += sharesMinted;
  }

  /**
   * @notice Withdraws `amount` units of an asset as collateral for a position
   * @dev Converts `amount` into `shares` and `index` so that rebase values can be tracked properly.
   * @param self The position to update
   * @param supply The total supply information of the asset
   * @param amount The amount to withdraw
   * @param index The current liquidity index
   * @return sharesBurnt How much shares was burnt
   */
  function withdrawCollateral(
    DataTypes.PositionBalance storage self,
    DataTypes.ReserveSupplies storage supply,
    uint256 amount,
    uint128 index
  ) internal returns (uint256 sharesBurnt) {
    sharesBurnt = amount.rayDiv(index);
    require(sharesBurnt != 0, PoolErrorsLib.INVALID_BURN_AMOUNT);
    self.lastSupplyLiquidtyIndex = index;
    self.supplyShares -= sharesBurnt;
    supply.supplyShares -= sharesBurnt;
  }

  /**
   * @notice Repays `amount` units of an asset as debt for a position
   * @dev Converts `amount` into `shares` and `index` so that rebase values can be tracked properly.
   * @param self The position to update
   * @param supply The total supply information of the asset
   * @param amount The amount to repay
   * @param index The current liquidity index
   * @return sharesBurnt How much shares was burnt
   */
  function repayDebt(
    DataTypes.PositionBalance storage self,
    DataTypes.ReserveSupplies storage supply,
    uint256 amount,
    uint128 index
  ) internal returns (uint256 sharesBurnt) {
    sharesBurnt = amount.rayDiv(index);
    require(sharesBurnt != 0, PoolErrorsLib.INVALID_BURN_AMOUNT);
    self.lastDebtLiquidtyIndex = index;
    self.debtShares -= sharesBurnt;
    supply.debtShares -= sharesBurnt;
  }

  /**
   * @notice Get the rebased assets worth of collateral the position has
   * @dev Converts `shares` into `amount` and returns the rebased value
   * @param self The position to fetch the value for
   * @param index The current liquidity index
   */
  function getSupplyBalance(DataTypes.PositionBalance storage self, uint256 index) public view returns (uint256 supply) {
    uint256 increase = self.supplyShares.rayMul(index) - self.supplyShares.rayMul(self.lastSupplyLiquidtyIndex);
    return self.supplyShares + increase;
  }

  /**
   * @notice Get the rebased assets worth of debt the position has
   * @dev Converts `shares` into `amount` and returns the rebased value
   * @param self The position to fetch the value for
   * @param index The current liquidity index
   */
  function getDebtBalance(DataTypes.PositionBalance storage self, uint256 index) internal view returns (uint256 debt) {
    uint256 increase = self.debtShares.rayMul(index) - self.debtShares.rayMul(self.lastDebtLiquidtyIndex);
    return self.debtShares + increase;
  }
}
