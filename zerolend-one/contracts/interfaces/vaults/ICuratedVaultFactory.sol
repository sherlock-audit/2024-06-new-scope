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

import {ICuratedVault} from './ICuratedVault.sol';
import {IBeacon} from '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';

interface ICuratedVaultFactory is IBeacon {
  /**
   * @param admins The admins of the vault. Used to make admin changes
   * @param proxyAdmin The proxy owner of the vault. Used to revoke proxy upgradability.
   * @param initialTimelock How many seconds for the timelock. Minimum is 1 day (86400 seconds).
   * @param asset The asset to deposit
   * @param name The name of the vault
   * @param symbol The symbol of the ERC4626 deposit
   * @param salt A random salt to randomize the deployment address of the pool
   */
  struct InitVaultParams {
    bool revokeProxy;
    address proxyAdmin;
    address[] admins;
    address[] curators;
    address[] guardians;
    address[] allocators;
    uint256 timelock;
    address asset;
    string name;
    string symbol;
    bytes32 salt;
  }

  /**
   * @notice Create a new vault for a particular asset on ZeroLend One
   * @dev This creates a ERC4626 compatible vault that is behind a proxy controlled by this factory contract.
   */
  function createVault(InitVaultParams memory params) external returns (ICuratedVault pool);

  function vaults(uint256 index) external view returns (ICuratedVault);

  function isVault(address vault) external view returns (bool);

  function vaultsLength() external view returns (uint256);

  function setImplementation(address updated) external;
}
