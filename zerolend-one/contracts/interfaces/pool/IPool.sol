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
import {IPoolGetters} from './IPoolGetters.sol';
import {IPoolSetters} from './IPoolSetters.sol';

/**
 * @title IPool
 * @notice Defines the basic interface for a ZeroLend Pool.
 */
interface IPool is IPoolGetters, IPoolSetters {
  /**
   * Returns the version of the pool implementation
   * @return version The version of this pool's implementation
   */
  function revision() external view returns (uint256 version);

  /**
   * @notice Initializes the pool with the given parameters. This call sets all the assets and their configs (LTV/LT/Oracle etc..)
   * in one call. Since assets once created cannot be changed, this has to be done within the initialize call itself.
   * @dev This is function is called by the factory contract.
   * @param params The init parameters for the pool. See {DataTypes-InitPoolParams}
   */
  function initialize(DataTypes.InitPoolParams memory params) external;
}
