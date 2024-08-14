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

import {Proxy} from '@openzeppelin/contracts/proxy/Proxy.sol';
import {IBeacon} from '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {StorageSlot} from '@openzeppelin/contracts/utils/StorageSlot.sol';

interface IRevokableBeaconProxy {
  // todo add events for admin and implementation changes
  event ImplementationRevoked(address indexed implementation, address indexed admin);
  event BeaconUpdated(address indexed newBeacon, address indexed oldBeacon, address sender);
  event AdminUpdated(address indexed newAdmin, address indexed oldAdmin, address sender);

  /**
   * @notice Transfer the ownership of the proxy to another address
   * @dev Can only be called by the proxy admin
   * @param newAdmin The new admin to transfer ownership to
   */
  function setAdmin(address newAdmin) external;

  /**
   * @notice Revokes the beacon's ability to upgrade this contract and forver seals the implementation
   * into the code forever.
   * @dev Can only be called by the proxy admin
   */
  function revokeBeacon() external;

  /**
   * @notice Revoke the beacon's admin
   * @dev Can only be called by the proxy admin
   */
  function revokeAdmin() external;

  /**
   * @notice Returns the implementation of the current proxy
   * @return The proxy's current implementation
   */
  function implementation() external view returns (address);

  function admin() external view returns (address);

  function beacon() external view returns (address);

  /**
   * @notice Checks if the beacon is revoked in which case the contract is as good as immutable.
   * @dev The revoked implementation address can be found in the `implementation()` call.
   * @return revoked True iff the beacon has been revoked.
   */
  function isBeaconRevoked() external view returns (bool revoked);
}
