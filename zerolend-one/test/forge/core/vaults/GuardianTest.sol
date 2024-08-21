// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ConstantsLib} from '../../../../contracts/core/vaults/libraries/ConstantsLib.sol';
import {MarketConfig, PendingAddress} from '../../../../contracts/interfaces/vaults/ICuratedVaultBase.sol';
import './helpers/IntegrationVaultTest.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

contract GuardianTest is IntegrationVaultTest {
  using Math for uint256;
  using MathLib for uint256;

  function setUp() public {
    _setUpVault();
    _setGuardian(guardian);
  }

  function testSubmitGuardianNotowner() public {
    vm.expectRevert();
    vault.grantGuardianRole(guardian);

    vm.prank(owner);
    vault.grantGuardianRole(guardian);
  }

  function testOwnerRevokePendingTimelockDecreased(uint256 timelock, uint256 elapsed) public {
    timelock = bound(timelock, ConstantsLib.MIN_TIMELOCK, TIMELOCK - 1);
    elapsed = bound(elapsed, 0, TIMELOCK - 1);

    vm.prank(owner);
    vault.submitTimelock(timelock);

    vm.warp(block.timestamp + elapsed);

    vm.expectEmit();
    emit CuratedEventsLib.RevokePendingTimelock(owner);
    vm.prank(owner);
    vault.revokePendingTimelock();

    uint256 newTimelock = vault.timelock();
    PendingUint192 memory pendingTimelock = vault.pendingTimelock();

    assertEq(newTimelock, TIMELOCK, 'newTimelock');
    assertEq(pendingTimelock.value, 0, 'value');
    assertEq(pendingTimelock.validAt, 0, 'validAt');
  }

  function testGuardianRevokePendingCapIncreased(uint256 seed, uint256 cap, uint256 elapsed) public {
    IPool marketParams = _randomMarketParams(seed);
    elapsed = bound(elapsed, 0, TIMELOCK - 1);
    cap = bound(cap, 1, type(uint184).max);

    vm.prank(owner);
    vault.submitCap(marketParams, cap);

    vm.warp(block.timestamp + elapsed);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.RevokePendingCap(guardian, marketParams);
    vm.prank(guardian);
    vault.revokePendingCap(marketParams);

    MarketConfig memory marketConfig = vault.config(marketParams);
    PendingUint192 memory pendingCap = vault.pendingCap(marketParams);

    assertEq(marketConfig.cap, 0, 'marketConfig.cap');
    assertEq(marketConfig.enabled, false, 'marketConfig.enabled');
    assertEq(marketConfig.removableAt, 0, 'marketConfig.removableAt');
    assertEq(pendingCap.value, 0, 'pendingCap.value');
    assertEq(pendingCap.validAt, 0, 'pendingCap.validAt');
  }

  function testRevokePendingMarketRemoval(uint256 elapsed) public {
    elapsed = bound(elapsed, 0, TIMELOCK - 1);

    IPool marketParams = allMarkets[0];

    _setCap(marketParams, CAP);
    _setCap(marketParams, 0);

    vm.prank(curator);
    vault.submitMarketRemoval(allMarkets[0]);

    vm.warp(block.timestamp + elapsed);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.RevokePendingMarketRemoval(guardian, marketParams);
    vm.prank(guardian);
    vault.revokePendingMarketRemoval(marketParams);

    MarketConfig memory marketConfig = vault.config(marketParams);

    assertEq(marketConfig.cap, 0, 'marketConfig.cap');
    assertEq(marketConfig.enabled, true, 'marketConfig.enabled');
    assertEq(marketConfig.removableAt, 0, 'marketConfig.removableAt');
  }
}
