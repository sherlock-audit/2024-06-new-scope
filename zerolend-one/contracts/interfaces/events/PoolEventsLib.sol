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

/**
 * @title PoolEventsLib
 * @notice Defines the events for a ZeroLend Pool.
 */
library PoolEventsLib {
  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param position The position to update
   * @param amount The amount supplied
   */
  event Supply(address indexed reserve, bytes32 indexed position, uint256 amount);

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param position The position to update
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   */
  event Withdraw(address indexed reserve, bytes32 indexed position, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param position The position to update
   * @param amount The amount borrowed out
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   */
  event Borrow(address indexed reserve, address user, bytes32 indexed position, uint256 amount, uint256 borrowRate);

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param position The position of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   */
  event Repay(address indexed reserve, bytes32 indexed position, address indexed repayer, uint256 amount);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param position The position to update
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, bytes32 indexed position);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param position The position to update
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, bytes32 indexed position);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   */
  event FlashLoan(address indexed target, address initiator, address indexed asset, uint256 amount, uint256 premium);

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param position The position to liquidate
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   */
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    bytes32 indexed position,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param borrowRate The next borrow rate
   * @param liquidityIndex The next liquidity index
   * @param borrowIndex The next borrow index
   */
  event ReserveDataUpdated(address indexed reserve, uint256 liquidityRate, uint256 borrowRate, uint256 liquidityIndex, uint256 borrowIndex);

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   */
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
  event CollateralConfigurationChanged(address indexed asset, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus);

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param oracle The address of the oracle
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   */
  event ReserveInitialized(address indexed asset, address oracle, address interestRateStrategyAddress);
}
