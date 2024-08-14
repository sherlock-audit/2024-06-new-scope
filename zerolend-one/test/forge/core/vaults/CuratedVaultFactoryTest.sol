// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './helpers/IntegrationVaultTest.sol';

import '../../../../contracts/core/vaults/CuratedVault.sol';
import '../../../../contracts/core/vaults/CuratedVaultFactory.sol';
import '../../../../contracts/interfaces/events/CuratedEventsLib.sol';

contract CuratedVaultFactoryTest is IntegrationVaultTest {
  function setUp() public {
    _setUpVault();
  }

  function testCreateVault(address initialOwner, uint256 initialTimelock, string memory name, string memory symbol, bytes32 salt) public {
    vm.assume(address(initialOwner) != address(0));
    vm.assume(initialTimelock >= 1 days);

    initialTimelock = bound(initialTimelock, 2 days, 2 weeks);

    defaultVaultParams.proxyAdmin = initialOwner;
    defaultVaultParams.admins[0] = initialOwner;
    defaultVaultParams.timelock = initialTimelock;
    defaultVaultParams.name = name;
    defaultVaultParams.symbol = symbol;
    defaultVaultParams.salt = salt;

    bytes32 initCodeHash = hashInitCode(type(RevokableBeaconProxy).creationCode, abi.encode(address(vaultFactory), initialOwner));
    address expectedAddress = computeCreate2Address(salt, initCodeHash, address(vaultFactory));

    // vm.expectEmit(address(vaultFactory));
    // emit CuratedEventsLib.VaultCreated(ICuratedVault(expectedAddress), uint256(2), defaultVaultParams, address(this));

    ICuratedVault vault = vaultFactory.createVault(defaultVaultParams);

    assertEq(expectedAddress, address(vault), 'computeCreate2Address');
    assertTrue(vaultFactory.isVault(address(vault)), 'isvault');
    assertTrue(vault.isOwner(initialOwner), 'owner');
    assertEq(vault.timelock(), initialTimelock, 'timelock');
    assertEq(vault.asset(), address(loanToken), 'asset');
    assertEq(vault.name(), name, 'name');
    assertEq(vault.symbol(), symbol, 'symbol');
  }
}
