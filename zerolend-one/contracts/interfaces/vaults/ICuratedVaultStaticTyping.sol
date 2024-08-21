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

import {IPool} from '../pool/IPool.sol';
import {ICuratedVaultBase, MarketConfig, PendingUint192} from './ICuratedVaultBase.sol';

/// @dev This interface is inherited by ZeroLend so that function signatures are checked by the compiler.
/// @dev Consider using the ICuratedVault interface instead of this one.
interface ICuratedVaultStaticTyping is ICuratedVaultBase {
  /// @notice Initializes the vault with the initial owner and timelock.
  /// @dev Called only by the factory contract
  function initialize(
    address[] memory _admins,
    address[] memory _curators,
    address[] memory _guardians,
    address[] memory _allocators,
    uint256 timelock,
    address asset,
    string memory name,
    string memory symbol
  ) external;

  function isCurator(address who) external view returns (bool);

  function isGuardian(address who) external view returns (bool);

  function isOwner(address who) external view returns (bool);

  function isAllocator(address who) external view returns (bool);

  function grantCuratorRole(address who) external;

  function grantGuardianRole(address who) external;

  function grantOwnerRole(address who) external;

  function grantAllocatorRole(address who) external;

  function revokeCuratorRole(address who) external;

  function revokeGuardianRole(address who) external;

  function revokeOwnerRole(address who) external;

  function revokeAllocatorRole(address who) external;
}
