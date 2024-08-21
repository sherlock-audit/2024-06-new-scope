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

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FLASHLOAN_ENABLED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;

  uint256 internal constant MAX_VALID_LTV = 65_535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65_535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65_535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65_535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68_719_476_735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68_719_476_735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65_535;

  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   */
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, PoolErrorsLib.INVALID_LTV);
    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @dev If the asset is frozen, then the LTV is set to 0
   * @param self The reserve configuration
   * @return The loan to value
   */
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    bool frozen = (self.data & ~FROZEN_MASK) != 0;
    return frozen ? 0 : self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   */
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, PoolErrorsLib.INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   */
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   */
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, PoolErrorsLib.INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   */
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   */
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, PoolErrorsLib.INVALID_DECIMALS);
    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   */
  function getDecimals(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   */
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   */
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   */
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   */
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   */
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap) internal pure {
    require(borrowCap <= MAX_VALID_BORROW_CAP, PoolErrorsLib.INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   */
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   */
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, PoolErrorsLib.INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   */
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   */
  function getFlags(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool, bool) {
    uint256 dataLocal = self.data;
    return ((dataLocal & ~FROZEN_MASK) != 0, (dataLocal & ~BORROWING_MASK) != 0);
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   */
  function getParams(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }
}
