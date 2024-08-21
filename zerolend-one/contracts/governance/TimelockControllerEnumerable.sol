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

import {AccessControl, AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {IERC1155Receiver, TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';

contract TimelockControllerEnumerable is TimelockController, AccessControlEnumerable {
  /**
   * @dev Sets the value for {name} and {version}
   */
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) TimelockController(minDelay, proposers, executors, admin) {
    // nothing
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override (TimelockController, AccessControlEnumerable) returns (bool) {
    return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Overload {_grantRole} to track enumerable memberships
   */
  function _grantRole(bytes32 role, address account) internal virtual override (AccessControl, AccessControlEnumerable) {
    super._grantRole(role, account);
  }

  /**
   * @dev Overload {_revokeRole} to track enumerable memberships
   */
  function _revokeRole(bytes32 role, address account) internal virtual override (AccessControl, AccessControlEnumerable) {
    super._revokeRole(role, account);
  }
}
