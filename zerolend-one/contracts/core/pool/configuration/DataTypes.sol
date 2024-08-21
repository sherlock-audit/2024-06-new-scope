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

library DataTypes {
  struct ReserveData {
    // stores the reserve configuration
    ReserveConfigurationMap configuration;
    // the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    // the current supply rate. Expressed in ray
    uint128 liquidityRate;
    // borrow index. Expressed in ray
    uint128 borrowIndex;
    // the current borrow rate. Expressed in ray
    uint128 borrowRate;
    // timestamp of last update
    uint40 lastUpdateTimestamp;
    // the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    // address of the interest rate strategy
    address interestRateStrategyAddress;
    // address of the oracle
    address oracle;
    // the current treasury balance in shares
    uint256 accruedToTreasuryShares;
  }

  struct ReserveConfigurationMap {
    // bit 0-15: LTV
    // bit 16-31: Liq. threshold
    // bit 32-47: Liq. bonus
    // bit 48-55: Decimals
    // bit 56: reserve is active
    // bit 57: reserve is frozen
    // bit 58: borrowing is enabled
    // bit 59: stable rate borrowing enabled
    // bit 60: asset is paused
    // bit 61: borrowing in isolation mode is enabled
    // bit 62: siloed borrowing enabled
    // bit 63: flashloaning enabled
    // bit 64-79: reserve factor
    // bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    // bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    // bit 152-167 liquidation protocol fee
    // bit 168-175 eMode category
    // bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    // bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    // bit 252-255 unused
    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct ReserveCache {
    ReserveConfigurationMap reserveConfiguration;
    uint128 currBorrowIndex;
    uint128 currLiquidityIndex;
    uint128 nextBorrowIndex;
    uint128 nextLiquidityIndex;
    uint256 currBorrowRate;
    uint256 currDebtShares;
    uint256 currLiquidityRate;
    uint256 nextDebtShares;
    uint40 reserveLastUpdateTimestamp;
  }

  struct PositionBalance {
    uint128 lastDebtLiquidtyIndex;
    uint128 lastSupplyLiquidtyIndex;
    uint256 debtShares;
    uint256 supplyShares;
  }

  struct ReserveSupplies {
    uint256 debtShares;
    uint256 supplyShares;
    uint128 underlyingBalance;
  }

  struct SharesType {
    uint256 shares;
    uint256 assets;
  }

  struct ExtraData {
    bytes hookData;
    bytes interestRateData;
  }

  struct ExecuteLiquidationCallParams {
    address collateralAsset;
    address debtAsset;
    address pool;
    bytes32 position;
    ExtraData data;
    uint256 debtToCover;
    uint256 reserveFactor;
    uint256 reservesCount;
  }

  struct ExecuteSupplyParams {
    address asset;
    address pool;
    bytes32 position;
    ExtraData data;
    uint256 amount;
    uint256 reserveFactor;
  }

  struct ExecuteBorrowParams {
    address asset;
    address pool;
    address user;
    address destination;
    bytes32 position;
    ExtraData data;
    uint256 amount;
    uint256 reserveFactor;
    uint256 reservesCount;
  }

  struct ExecuteRepayParams {
    address asset;
    address pool;
    address user;
    bytes32 position;
    ExtraData data;
    uint256 amount;
    uint256 reserveFactor;
  }

  struct ExecuteWithdrawParams {
    address asset;
    address destination;
    address pool;
    bytes32 position;
    ExtraData data;
    uint256 amount;
    uint256 reserveFactor;
  }

  struct FlashloanSimpleParams {
    address asset;
    address receiverAddress;
    bytes params;
    ExtraData data;
    uint256 amount;
    uint256 flashLoanPremiumTotal;
    uint256 reserveFactor;
  }

  struct FlashLoanRepaymentParams {
    address asset;
    address pool;
    address receiverAddress;
    uint256 amount;
    uint256 reserveFactor;
    uint256 totalPremium;
  }

  struct CalculateUserAccountDataParams {
    address pool;
    bytes32 position;
    // uint256 reservesCount;
    UserConfigurationMap userConfig;
  }

  struct ValidateBorrowParams {
    address asset;
    address pool;
    bytes32 position;
    ReserveCache cache;
    uint256 amount;
    uint256 reservesCount;
    UserConfigurationMap userConfig;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 healthFactor;
    uint256 totalDebt;
  }

  struct CalculateInterestRatesParams {
    address reserve;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 reserveFactor;
    uint256 totalDebt;
  }

  struct InitReserveConfig {
    bool borrowable;
    bool frozen;
    uint256 borrowCap;
    uint256 decimals;
    uint256 liquidationBonus;
    uint256 liquidationThreshold;
    uint256 ltv;
    uint256 supplyCap;
  }

  struct InitReserveParams {
    address asset;
    address interestRateStrategyAddress;
    address oracle;
    InitReserveConfig configuration;
    uint16 reservesCount;
  }

  struct InitPoolParams {
    bool revokeProxy;
    address proxyAdmin;
    address[] admins;
    address[] emergencyAdmins;
    address[] riskAdmins;
    address hook;
    address[] assets;
    address[] rateStrategyAddresses;
    address[] sources;
    DataTypes.InitReserveConfig[] configurations;
  }

  struct SeedPoolParams {
    address pool;
    address[] assets;
    uint256[] amounts;
  }
}
