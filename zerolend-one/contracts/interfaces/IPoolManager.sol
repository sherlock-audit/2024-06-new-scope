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

import {IPool} from './pool/IPool.sol';
import {IAccessControlEnumerable} from '@openzeppelin/contracts/access/IAccessControlEnumerable.sol';

/**
 * @title IPoolManager
 * @notice Defines the basic interface for the ACL Manager
 */
interface IPoolManager is IAccessControlEnumerable {
  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(IPool pool, address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(IPool pool, address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(IPool pool, address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(IPool pool, address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(IPool pool, address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(IPool pool, address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(IPool pool, address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(IPool pool, address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(IPool pool, address admin) external view returns (bool);

  /**
   * @notice Gets the role for a given pool
   * @param pool The pool to get the role for
   * @param role The role to get
   */
  function getRoleFromPool(IPool pool, bytes32 role) external pure returns (bytes32);
}
