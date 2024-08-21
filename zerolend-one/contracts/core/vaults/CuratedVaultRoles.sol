// SPDX-License-Identifier: GPL-2.0-or-later
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

import {CuratedErrorsLib} from '../../interfaces/errors/CuratedErrorsLib.sol';
import {CuratedVaultStorage, ICuratedVaultBase} from './CuratedVaultStorage.sol';
import {AccessControlEnumerableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

abstract contract CuratedVaultRoles is AccessControlEnumerableUpgradeable, CuratedVaultStorage {
  function __CuratedVaultRoles_init(
    address[] memory _admins,
    address[] memory _curators,
    address[] memory _guardians,
    address[] memory _allocators
  ) internal {
    __AccessControlEnumerable_init();

    for (uint256 i = 0; i < _admins.length; i++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
    }

    for (uint256 i = 0; i < _curators.length; i++) {
      _setupRole(CURATOR_ROLE, _curators[i]);
    }

    for (uint256 i = 0; i < _guardians.length; i++) {
      _setupRole(GUARDIAN_ROLE, _guardians[i]);
    }

    for (uint256 i = 0; i < _allocators.length; i++) {
      _setupRole(ALLOCATOR_ROLE, _allocators[i]);
    }
  }

  /* MODIFIERS */

  /// @dev Reverts if the caller doesn't have the curator role.
  modifier onlyCuratorRole() {
    address sender = _msgSender();
    if (!isOwner(_msgSender()) && !isCurator(_msgSender())) revert CuratedErrorsLib.NotCuratorRole();
    _;
  }

  /// @dev Reverts if the caller doesn't have the allocator role.
  modifier onlyAllocator() {
    address sender = _msgSender();
    if (!isOwner(_msgSender()) && !isAllocator(_msgSender())) {
      revert CuratedErrorsLib.NotAllocatorRole();
    }
    _;
  }

  /// @dev Reverts if the caller doesn't have the guardian role.
  modifier onlyGuardian() {
    if (!isOwner(_msgSender()) && !isGuardian(_msgSender())) revert CuratedErrorsLib.NotGuardianRole();
    _;
  }

  /// @dev Reverts if the caller is not eh default admin
  modifier onlyOwner() {
    if (!isOwner(_msgSender())) revert CuratedErrorsLib.NotOwnerRole();
    _;
  }

  /// @dev Reverts if the caller doesn't have the curator nor the guardian role.
  modifier onlyCuratorOrGuardian() {
    if (!isOwner(_msgSender()) && !isCurator(_msgSender()) && !isGuardian(_msgSender())) {
      revert CuratedErrorsLib.NotCuratorNorGuardianRole();
    }
    _;
  }

  function isCurator(address who) public view returns (bool) {
    return hasRole(CURATOR_ROLE, who);
  }

  function isGuardian(address who) public view returns (bool) {
    return hasRole(GUARDIAN_ROLE, who);
  }

  function isOwner(address who) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, who);
  }

  /// @inheritdoc ICuratedVaultBase
  function isAllocator(address who) public view returns (bool) {
    return hasRole(ALLOCATOR_ROLE, who);
  }

  function grantCuratorRole(address who) public {
    grantRole(CURATOR_ROLE, who);
  }

  function grantGuardianRole(address who) public {
    grantRole(GUARDIAN_ROLE, who);
  }

  function grantOwnerRole(address who) public {
    grantRole(DEFAULT_ADMIN_ROLE, who);
  }

  function grantAllocatorRole(address who) public {
    grantRole(ALLOCATOR_ROLE, who);
  }

  function revokeCuratorRole(address who) public {
    revokeRole(CURATOR_ROLE, who);
  }

  function revokeGuardianRole(address who) public {
    revokeRole(GUARDIAN_ROLE, who);
  }

  function revokeOwnerRole(address who) public {
    revokeRole(DEFAULT_ADMIN_ROLE, who);
  }

  function revokeAllocatorRole(address who) public {
    revokeRole(ALLOCATOR_ROLE, who);
  }
}
