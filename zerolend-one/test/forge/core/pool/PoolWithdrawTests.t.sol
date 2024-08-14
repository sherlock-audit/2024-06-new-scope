// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {MintableERC20} from '../../../../contracts/mocks/MintableERC20.sol';
import {PoolEventsLib, PoolSetup} from './PoolSetup.sol';

contract PoolWithdrawTests is PoolSetup {
  function setUp() public {
    _setUpPool();
  }

  function testWithdrawAmountZero() external {
    vm.expectRevert(bytes('INVALID_AMOUNT'));
    pool.withdrawSimple(address(tokenA), msg.sender, 0, 0);
  }

  function testFailWithdrawZeroAssetAddress() external {
    pool.withdrawSimple(address(0), msg.sender, 50 ether, 0);
  }

  function testFailWithdrawNonExistingToken() external {
    MintableERC20 randomToken = new MintableERC20('TOKEN D', 'TOKEND');

    pool.withdrawSimple(address(randomToken), msg.sender, 50 ether, 0);
  }

  function testRevertsWithdrawInvalidBalance() public {
    uint256 amount = 100e18;

    vm.startPrank(owner);
    tokenA.mint(owner, amount);
    tokenA.approve(address(pool), amount);
    pool.supplySimple(address(tokenA), owner, amount, 0);

    vm.expectRevert(bytes('NOT_ENOUGH_AVAILABLE_USER_BALANCE'));
    pool.withdrawSimple(address(tokenA), owner, 2 * amount, 0);
    vm.stopPrank();
  }

  function testWithdrawEventEmit() external {
    uint256 supplyAmount = 50 ether;
    uint256 mintAmount = 150 ether;
    uint256 withdrawAmount = 50 ether;
    address user = owner;
    uint256 index = 1;
    bytes32 pos = keccak256(abi.encodePacked(user, 'index', index));

    vm.startPrank(owner);
    tokenA.mint(owner, mintAmount);
    tokenA.approve(address(pool), supplyAmount);

    vm.expectEmit(true, true, false, true);
    emit PoolEventsLib.Supply(address(tokenA), pos, supplyAmount);
    pool.supplySimple(address(tokenA), owner, supplyAmount, index);

    assertEq(tokenA.balanceOf(address(pool)), supplyAmount);
    assertEq(tokenA.balanceOf(owner), mintAmount - supplyAmount);

    vm.expectEmit(true, true, true, true);
    emit PoolEventsLib.Withdraw(address(tokenA), pos, owner, withdrawAmount);

    pool.withdrawSimple(address(tokenA), owner, withdrawAmount, index);
    vm.stopPrank();
  }

  function testPoolWithdraw() external {
    uint256 supplyAmount = 50 ether;
    uint256 mintAmount = 150 ether;
    uint256 withdrawAmount = 30 ether;
    uint256 index = 1;

    vm.startPrank(owner);
    tokenA.mint(owner, mintAmount);
    tokenA.approve(address(pool), supplyAmount);

    pool.supplySimple(address(tokenA), owner, supplyAmount, index);

    assertEq(tokenA.balanceOf(address(pool)), supplyAmount, 'Pool Balance Supply');
    assertEq(tokenA.balanceOf(owner), mintAmount - supplyAmount, 'Owner Balance Supply');
    assertEq(pool.getTotalSupplyRaw(address(tokenA)).supplyShares, supplyAmount);
    assertEq(pool.getBalanceRaw(address(tokenA), owner, index).supplyShares, supplyAmount);

    pool.withdrawSimple(address(tokenA), owner, withdrawAmount, index);
    assertEq(tokenA.balanceOf(address(pool)), supplyAmount - withdrawAmount, 'Pool Balance Withdraw');
    assertEq(tokenA.balanceOf(owner), (mintAmount - supplyAmount) + withdrawAmount, 'Owner Balance Withdraw');
    assertEq(pool.getTotalSupplyRaw(address(tokenA)).supplyShares, supplyAmount - withdrawAmount);
    assertEq(pool.getBalanceRaw(address(tokenA), owner, index).supplyShares, supplyAmount - withdrawAmount);
  }
}
