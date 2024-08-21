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

import {IHook} from '../../interfaces/IHook.sol';
import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';
import {DataTypes} from './configuration/DataTypes.sol';

/**
 * @title PoolStorage Child Contract
 * @author ZeroLend
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
  /// @notice Map of reserves and their data (underlyingAssetOfReserve => reserveData)
  mapping(address asset => DataTypes.ReserveData data) internal _reserves;

  /// @notice Map of positions and their configuration data (userAddress => userConfiguration)
  mapping(bytes32 position => DataTypes.UserConfigurationMap config) internal _usersConfig;

  /// @notice Map of position's individual balances
  mapping(address reserve => mapping(bytes32 position => DataTypes.PositionBalance balance)) internal _balances;

  /// @notice Map of total supply of tokens
  mapping(address reserve => DataTypes.ReserveSupplies totalSupply) internal _totalSupplies;

  /// @notice List of reserves as a map (reserveId => reserve).
  /// It is structured as a mapping for gas savings reasons, using the reserve id as index
  mapping(uint256 reserveId => address reserve) internal _reservesList;

  /// @notice Number of active reserves in the pool
  uint16 internal _reservesCount;

  /// @notice The original factory contract with protocol-level control variables
  IPoolFactory internal _factory;

  /// @notice The assigned hook for this pool
  IHook internal _hook;
}
