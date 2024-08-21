// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPool} from './../../../../contracts/interfaces/pool/IPool.sol';
import {MockFlashLoanSimpleReceiver} from './../../../../contracts/mocks/MockSimpleFlashLoanReceiver.sol';
import {PoolEventsLib, PoolSetup} from './PoolSetup.sol';

contract PoolFlashLoanTests is PoolSetup {
  address alice = address(1);
  address bob = address(2);

  event Transfer(address indexed from, address indexed to, uint256 value);

  function setUp() public {
    _setUpPool();
  }

  function test_reverts_flashLoan_simple_invalid_return() public {
    bytes memory emptyParams;
    MockFlashLoanSimpleReceiver mockFlashSimpleReceiver = new MockFlashLoanSimpleReceiver(pool);
    _generateFlashloanCondition();

    mockFlashSimpleReceiver.setFailExecutionTransfer(true);
    mockFlashSimpleReceiver.setSimulateEOA(true);

    vm.expectRevert(bytes('INVALID_FLASHLOAN_EXECUTOR_RETURN'));

    vm.prank(alice);
    pool.flashLoanSimple(address(mockFlashSimpleReceiver), address(tokenA), 600 ether, emptyParams);
  }

  function test_reverts_flashLoan_reserve_frozen() public {
    bytes memory emptyParams;
    MockFlashLoanSimpleReceiver mockFlashSimpleReceiver = new MockFlashLoanSimpleReceiver(pool);

    configurator.setReserveFreeze(IPool(address(pool)), address(tokenA), true);

    vm.expectRevert(bytes('RESERVE_FROZEN'));

    vm.prank(alice);
    pool.flashLoanSimple(address(mockFlashSimpleReceiver), address(tokenA), 100 ether, emptyParams);
  }

  function test_reverts_flashloans_eoa() public {
    bytes memory emptyParams;
    vm.expectRevert();

    vm.prank(alice);
    pool.flashLoanSimple(alice, address(tokenA), 100 ether, emptyParams);
  }

  function testFailZeroAddress() public {
    bytes memory emptyParams;
    _generateFlashloanCondition();

    pool.flashLoanSimple(address(0), address(tokenA), 0, emptyParams);
  }

  function test_simple_flashloan() public {
    bytes memory emptyParams;
    MockFlashLoanSimpleReceiver mockFlashSimpleReceiver = new MockFlashLoanSimpleReceiver(pool);
    _generateFlashloanCondition();

    uint256 premium = poolFactory.flashLoanPremiumToProtocol();
    vm.startPrank(alice);

    vm.expectEmit(true, true, true, true);
    emit PoolEventsLib.FlashLoan(address(mockFlashSimpleReceiver), alice, address(tokenA), 100 ether, 0);
    emit Transfer(address(0), address(mockFlashSimpleReceiver), 100 ether * premium);

    pool.flashLoanSimple(address(mockFlashSimpleReceiver), address(tokenA), 100 ether, emptyParams);
    vm.stopPrank();

    poolFactory.setFlashloanPremium(2);
    premium = poolFactory.flashLoanPremiumToProtocol();
    assertEq(premium, 2);

    vm.startPrank(alice);

    vm.expectEmit(true, true, true, true);
    emit PoolEventsLib.FlashLoan(address(mockFlashSimpleReceiver), alice, address(tokenA), 100 ether, (100 ether * premium) / 10_000);
    emit Transfer(address(0), address(mockFlashSimpleReceiver), (100 ether * premium) / 10_000);

    pool.flashLoanSimple(address(mockFlashSimpleReceiver), address(tokenA), 100 ether, emptyParams);
    vm.stopPrank();
  }

  function _generateFlashloanCondition() internal {
    _mintAndApprove(bob, tokenA, 5000 ether, address(pool));
    _mintAndApprove(bob, tokenC, 2500 ether, address(pool));

    vm.startPrank(bob);
    pool.supplySimple(address(tokenA), bob, 2000 ether, 0);
    pool.supplySimple(address(tokenC), bob, 1000 ether, 0);

    vm.stopPrank();
  }
}
