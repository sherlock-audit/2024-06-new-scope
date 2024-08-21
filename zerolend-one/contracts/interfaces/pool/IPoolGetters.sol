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
import {IHook} from '../IHook.sol';
import {IPoolFactory} from '../IPoolFactory.sol';

interface IPoolGetters {
  /**
   * @notice Get the balance of a specific asset in a specific position.
   * @param asset The address of the asset.
   * @param positionId The ID of the position.
   * @return balance The balance of the specified asset in the specified position.
   */
  function getBalanceByPosition(address asset, bytes32 positionId) external view returns (uint256 balance);

  /**
   * @notice Get the balance of a specific asset for a user given a position index
   * @param asset The address of the asset.
   * @param who The user to find the balance of
   * @param index The index of the user's position
   * @return balance The balance of the specified asset for the given user and position idnex.
   */
  function getBalance(address asset, address who, uint256 index) external view returns (uint256 balance);

  /**
   * @notice Get the debt of a specific asset for a user given a position index
   * @param asset The address of the asset.
   * @param who The user to find the debt of
   * @param index The index of the user's position
   * @return debt The debt of the specified asset for the given user and position idnex.
   */
  function getDebt(address asset, address who, uint256 index) external view returns (uint256 debt);

  /**
   * @notice Get the debt of a specific asset in a specific position.
   * @param asset The address of the asset.
   * @param positionId The ID of the position.
   * @return debt The debt of the specified asset in the specified position.
   */
  function getDebtByPosition(address asset, bytes32 positionId) external view returns (uint256 debt);

  /**
   * @notice Gets the reserve factor that this pool charges. The reserve factory is the percentage of
   * revenue that the pool shares with the governance.
   * @dev This parameter is immutable.
   * @return reseveFactor The amount of revenue that gets shared to governance.
   */
  function getReserveFactor() external view returns (uint256 reseveFactor);

  /**
   * @notice The factory contract that created this contract
   */
  function factory() external view returns (IPoolFactory f);

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @param index The index of the user's position
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
  function getUserAccountData(
    address user,
    uint256 index
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @param index The index of the user's position
   * @return The configuration of the user
   */
  function getUserConfiguration(address user, uint256 index) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @return The addresses of the underlying assets of the initialized reserves
   */
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the number of initialized reserves
   * @return The count
   */
  function getReservesCount() external view returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   */
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Returns the current hook for the pool.
   * @dev The hook is immutable. Once it is set, it cannot be changed.
   * @return The hook for the pool, if set.
   */
  function getHook() external view returns (IHook);

  /**
   * @notice Gets the raw balance object for the asset for a given position id
   */
  function getBalanceRawByPositionId(address asset, bytes32 positionId) external view returns (DataTypes.PositionBalance memory);

  /**
   * @notice Gets the raw balance object for the asset for a given user and the position index.
   * @param asset The address of the asset
   * @param who The address of the user
   * @param index The index of the user's position
   */
  function getBalanceRaw(address asset, address who, uint256 index) external view returns (DataTypes.PositionBalance memory);

  /**
   * @notice Gets the raw reserve supply object for a given asset.
   * @param asset The address of the asset
   * @return data The reserve supply information of the given asset
   */
  function getTotalSupplyRaw(address asset) external view returns (DataTypes.ReserveSupplies memory data);

  /**
   * @notice Gets the Pool Configurator
   * @return The address of the Pool Configurator
   */
  function getConfigurator() external view returns (address);

  function totalAssets(address asset) external view returns (uint256 balance);

  function totalDebt(address asset) external view returns (uint256 balance);

  function marketBalances(address asset)
    external
    view
    returns (uint256 totalSupplyAssets, uint256 totalSupplyShares, uint256 totalBorrowAssets, uint256 totalBorrowShares);

  function supplyShares(address asset, bytes32 positionId) external view returns (uint256 shares);

  function supplyAssets(address asset, bytes32 positionId) external view returns (uint256);

  function debtAssets(address asset, bytes32 positionId) external view returns (uint256);

  function debtShares(address asset, bytes32 positionId) external view returns (uint256 shares);
}
