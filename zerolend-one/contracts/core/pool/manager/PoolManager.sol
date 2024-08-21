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

import {IPool, IPoolManager} from '../../../interfaces/IPoolManager.sol';
import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

abstract contract PoolManager is AccessControlEnumerable, IPoolManager {
  bytes32 public constant POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
  bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256('EMERGENCY_ADMIN');
  bytes32 public constant RISK_ADMIN_ROLE = keccak256('RISK_ADMIN');

  /// @inheritdoc IPoolManager
  function addPoolAdmin(IPool pool, address admin) public {
    grantRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function addEmergencyAdmin(IPool pool, address admin) public {
    grantRole(getRoleFromPool(pool, EMERGENCY_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function addRiskAdmin(IPool pool, address admin) public {
    grantRole(getRoleFromPool(pool, RISK_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function isPoolAdmin(IPool pool, address admin) public view returns (bool) {
    return hasRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function isEmergencyAdmin(IPool pool, address admin) public view returns (bool) {
    return hasRole(getRoleFromPool(pool, EMERGENCY_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function isRiskAdmin(IPool pool, address admin) public view returns (bool) {
    return hasRole(getRoleFromPool(pool, RISK_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function removeEmergencyAdmin(IPool pool, address admin) public {
    revokeRole(getRoleFromPool(pool, EMERGENCY_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function removeRiskAdmin(IPool pool, address admin) public {
    revokeRole(getRoleFromPool(pool, RISK_ADMIN_ROLE), admin);
  }

  /// @inheritdoc IPoolManager
  function removePoolAdmin(IPool pool, address admin) public {
    revokeRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), admin);
  }

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   */
  modifier onlyPoolAdmin(IPool pool) {
    require(hasRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), msg.sender), 'not risk or pool admin');
    _;
  }

  modifier onlyEmergencyAdmin(IPool pool) {
    require(hasRole(getRoleFromPool(pool, EMERGENCY_ADMIN_ROLE), msg.sender), 'not risk or pool admin');
    _;
  }

  modifier onlyEmergencyOrPoolAdmin(IPool pool) {
    require(
      hasRole(getRoleFromPool(pool, EMERGENCY_ADMIN_ROLE), msg.sender) || hasRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), msg.sender),
      'not emergency or pool admin'
    );
    _;
  }

  modifier onlyRiskOrPoolAdmins(IPool pool) {
    require(
      hasRole(getRoleFromPool(pool, RISK_ADMIN_ROLE), msg.sender) || hasRole(getRoleFromPool(pool, POOL_ADMIN_ROLE), msg.sender),
      'not risk or pool admin'
    );
    _;
  }

  /// @inheritdoc IPoolManager
  function getRoleFromPool(IPool pool, bytes32 role) public pure returns (bytes32) {
    return keccak256(abi.encode(pool, role));
  }
}
