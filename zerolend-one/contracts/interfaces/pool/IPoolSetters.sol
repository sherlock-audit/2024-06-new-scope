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

import {DataTypes} from '../../core/pool/configuration/DataTypes.sol';

interface IPoolSetters {
  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the rate strategy for the reserve
   * @param source The address of the oracle for the reserve
   * @param configuration The new configuration bitmap
   */
  function setReserveConfiguration(
    address asset,
    address rateStrategyAddress,
    address source,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param to The address to supply for
   * @param amount The amount to be supplied
   * @param index The index of the user's position
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   * @return minted The amount of shares minted
   */
  function supply(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) external returns (DataTypes.SharesType memory minted);

  /**
   * @dev See [supply(...)](#supply) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function supplySimple(address asset, address to, uint256 amount, uint256 index) external returns (DataTypes.SharesType memory);

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param to The address to send the tokens to
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param index The index of the user's position
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   * @return burnt The amount of shares burnt
   */
  function withdraw(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) external returns (DataTypes.SharesType memory burnt);

  /**
   * @dev See [withdraw(...)](#withdraw) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function withdrawSimple(address asset, address to, uint256 amount, uint256 index) external returns (DataTypes.SharesType memory minted);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param to The address to send the tokens to
   * @param amount The amount to be borrowed
   * @param index The index of the user's position
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   * @return borrowed The amount of shares borrowed
   */
  function borrow(
    address asset,
    address to,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) external returns (DataTypes.SharesType memory borrowed);

  /**
   * @dev See [borrow(...)](#borrow) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function borrowSimple(address asset, address to, uint256 amount, uint256 index) external returns (DataTypes.SharesType memory);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param index The index of the user's position
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   * @return repaid The amount of shares repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 index,
    DataTypes.ExtraData memory data
  ) external returns (DataTypes.SharesType memory repaid);

  /**
   * @dev See [repay(...)](#repay) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function repaySimple(address asset, uint256 amount, uint256 index) external returns (DataTypes.SharesType memory);

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param index The index of the user's position
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, uint256 index, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   */
  function liquidate(
    address collateralAsset,
    address debtAsset,
    bytes32 position,
    uint256 debtToCover,
    DataTypes.ExtraData memory data
  ) external;

  /**
   * @dev See [liquidate(...)](#liquidate) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function liquidateSimple(address collateralAsset, address debtAsset, bytes32 position, uint256 debtToCover) external;

  /**
   * @dev See [flashLoan(...)](#flashLoan) for the full documentation. This call executes the same function with
   * dummy data params
   */
  function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration.
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param data Extra data that gets passed to the hook and to the interest rate strategy
   */
  function flashLoan(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    DataTypes.ExtraData memory data
  ) external;

  function forceUpdateReserves() external;

  function forceUpdateReserve(address asset) external;
}
