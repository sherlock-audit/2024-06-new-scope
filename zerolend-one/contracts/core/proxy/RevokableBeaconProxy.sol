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

import {IRevokableBeaconProxy} from '../../interfaces/IRevokableBeaconProxy.sol';
import {Proxy} from '@openzeppelin/contracts/proxy/Proxy.sol';
import {IBeacon} from '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {StorageSlot} from '@openzeppelin/contracts/utils/StorageSlot.sol';

/**
 * @notice A beacon proxy with the ability to have it's upgradability revoked
 * @author ZeroLend
 * @notice This is a beacon proxy contract that has the ability for the proxy admin to revoke
 * the beacon's ability to upgrade the contract.
 */
contract RevokableBeaconProxy is IRevokableBeaconProxy, Proxy {
  /// @dev The keccak256 hash used for the implementation slot
  bytes32 internal immutable _IMPLEMENTATION_SLOT = keccak256('eip1967.proxy.impl');

  /// @dev The keccak256 hash used for the beacon slot
  bytes32 internal immutable _BEACON_SLOT = keccak256('eip1967.proxy.beacon');

  /// @dev The keccak256 hash used for the admin slot
  bytes32 internal immutable _ADMIN_SLOT = keccak256('eip1967.proxy.admin');

  /**
   * @notice Constructor for the beacon proxy. Ideally called by a factory contract.
   * @param _beacon The address of the beacon contract.
   * @param _admin The admin to revoke the beacon contract
   */
  constructor(address _beacon, address _admin) {
    StorageSlot.getAddressSlot(_BEACON_SLOT).value = _beacon;
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = _admin;

    emit AdminUpdated(_admin, address(0), msg.sender);
    emit BeaconUpdated(_beacon, address(0), msg.sender);
  }

  /// @inheritdoc Proxy
  function _implementation() internal view virtual override returns (address) {
    address _beacon = _getBeacon();
    if (_beacon != address(0)) return IBeacon(_beacon).implementation();

    // if beacon was revoked, the use the last implementation
    return _getFrozenImpl();
  }

  /// @inheritdoc IRevokableBeaconProxy
  function setAdmin(address newAdmin) external {
    require(msg.sender == _getAdmin(), 'not proxy admin');
    address oldAdmin = StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;

    emit AdminUpdated(newAdmin, oldAdmin, msg.sender);
  }

  /// @inheritdoc IRevokableBeaconProxy
  function revokeBeacon() external {
    require(msg.sender == _getAdmin(), 'not proxy admin');
    address impl = _implementation();

    address oldAdmin = StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    address oldBeacon = StorageSlot.getAddressSlot(_BEACON_SLOT).value;

    StorageSlot.getAddressSlot(_BEACON_SLOT).value = address(0);
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = address(0);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = impl;

    emit ImplementationRevoked(impl, msg.sender);
    emit BeaconUpdated(address(0), oldBeacon, msg.sender);
    emit AdminUpdated(address(0), oldAdmin, msg.sender);
  }

  /// @inheritdoc IRevokableBeaconProxy
  function revokeAdmin() external {
    require(msg.sender == _getAdmin(), 'not proxy admin');
    address oldAdmin = StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    StorageSlot.getAddressSlot(_ADMIN_SLOT).value = address(0);

    emit AdminUpdated(address(0), oldAdmin, msg.sender);
  }

  /// @inheritdoc IRevokableBeaconProxy
  function implementation() external view returns (address) {
    return _implementation();
  }

  /// @inheritdoc IRevokableBeaconProxy
  function admin() external view returns (address) {
    return _getAdmin();
  }

  /// @inheritdoc IRevokableBeaconProxy
  function beacon() external view returns (address) {
    return _getBeacon();
  }

  /// @inheritdoc IRevokableBeaconProxy
  function isBeaconRevoked() external view returns (bool revoked) {
    revoked = _getBeacon() == address(0);
  }

  function _getBeacon() private view returns (address) {
    return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
  }

  function _getAdmin() private view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }

  function _getFrozenImpl() private view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }
}
