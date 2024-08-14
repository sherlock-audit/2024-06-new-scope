// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// import {IERC20Errors} from '../../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
// import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {IFlashLoanSimpleReceiver} from '../../../../contracts/interfaces/IFlashLoanSimpleReceiver.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import './helpers/IntegrationVaultTest.sol';

contract ERC4626Test is IntegrationVaultTest, IFlashLoanSimpleReceiver {
  function setUp() public {
    _setUpVault();
    _setCap(allMarkets[0], CAP);
    _sortSupplyQueueIdleLast();

    oracleB.updateRoundTimestamp();
    oracle.updateRoundTimestamp();
  }

  // todo test decimals
  // function testDecimals(uint8 decimals) public {
  //   vm.mockCall(address(loanToken), abi.encodeWithSignature('decimals()'), abi.encode(decimals));
  //   console.log('decimals', decimals, loanToken.decimals());
  //   assertEq(vault.decimals(), Math.max(18, decimals), 'decimals');
  // }

  function testMint(uint256 assets) public {
    assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    uint256 shares = vault.convertToShares(assets);
    loanToken.mint(supplier, assets);

    vm.expectEmit();
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets() + assets);
    vm.prank(supplier);
    uint256 deposited = vault.mint(shares, onBehalf);

    assertGt(deposited, 0, 'deposited');
    assertEq(loanToken.balanceOf(address(vault)), 0, 'balanceOf(vault)');
    assertEq(vault.balanceOf(onBehalf), shares, 'balanceOf(onBehalf)');
    assertEq(allMarkets[0].supplyAssets(address(loanToken), vault.positionId()), assets, 'expectedSupplyAssets(vault)');
  }

  function testDeposit(uint256 assets) public {
    assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    loanToken.mint(supplier, assets);

    vm.expectEmit();
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets() + assets);
    vm.prank(supplier);
    uint256 shares = vault.deposit(assets, onBehalf);

    assertGt(shares, 0, 'shares');
    assertEq(loanToken.balanceOf(address(vault)), 0, 'balanceOf(vault)');
    assertEq(vault.balanceOf(onBehalf), shares, 'balanceOf(onBehalf)');
    assertEq(allMarkets[0].supplyAssets(address(loanToken), vault.positionId()), assets, 'expectedSupplyAssets(vault)');
  }

  function testRedeem(uint256 deposited, uint256 redeemed) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    redeemed = bound(redeemed, 0, shares);

    vm.expectEmit();
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets() - vault.convertToAssets(redeemed));

    vm.prank(onBehalf);
    vault.redeem(redeemed, receiver, onBehalf);

    assertEq(loanToken.balanceOf(address(vault)), 0, 'balanceOf(vault)');
    assertEq(vault.balanceOf(onBehalf), shares - redeemed, 'balanceOf(onBehalf)');
  }

  function testWithdraw(uint256 deposited, uint256 withdrawn) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    withdrawn = bound(withdrawn, 0, deposited);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    vm.expectEmit();
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets() - withdrawn);
    vm.prank(onBehalf);
    uint256 redeemed = vault.withdraw(withdrawn, receiver, onBehalf);

    assertEq(loanToken.balanceOf(address(vault)), 0, 'balanceOf(vault)');
    assertEq(vault.balanceOf(onBehalf), shares - redeemed, 'balanceOf(onBehalf)');
  }

  function testWithdrawIdle(uint256 deposited, uint256 withdrawn) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    withdrawn = bound(withdrawn, 0, deposited);

    _setCap(allMarkets[0], 0);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    vm.expectEmit();
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets() - withdrawn);
    vm.prank(onBehalf);
    uint256 redeemed = vault.withdraw(withdrawn, receiver, onBehalf);

    assertEq(loanToken.balanceOf(address(vault)), 0, 'balanceOf(vault)');
    assertEq(vault.balanceOf(onBehalf), shares - redeemed, 'balanceOf(onBehalf)');
    assertEq(_idle(), deposited - withdrawn, 'idle');
  }

  function testRedeemTooMuch(uint256 deposited) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited * 2);

    vm.startPrank(supplier);
    uint256 shares = vault.deposit(deposited, supplier);
    vault.deposit(deposited, onBehalf);
    vm.stopPrank();

    vm.prank(supplier);
    vm.expectRevert(bytes('ERC20: burn amount exceeds balance'));
    vault.redeem(shares + 1, receiver, supplier);
  }

  function testWithdrawAll(uint256 assets) public {
    assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, assets);

    vm.prank(supplier);
    uint256 minted = vault.deposit(assets, onBehalf);

    assertEq(vault.maxWithdraw(onBehalf), assets, 'maxWithdraw(onBehalf)');

    vm.prank(onBehalf);
    uint256 shares = vault.withdraw(assets, receiver, onBehalf);

    assertEq(shares, minted, 'shares');
    assertEq(vault.balanceOf(onBehalf), 0, 'balanceOf(onBehalf)');
    assertEq(loanToken.balanceOf(receiver), assets, 'loanToken.balanceOf(receiver)');
    assertEq(allMarkets[0].supplyAssets(address(loanToken), pos), 0, 'expectedSupplyAssets(vault)');
  }

  function testRedeemAll(uint256 deposited) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 minted = vault.deposit(deposited, onBehalf);

    assertEq(vault.maxRedeem(onBehalf), minted, 'maxRedeem(onBehalf)');

    vm.prank(onBehalf);
    uint256 assets = vault.redeem(minted, receiver, onBehalf);

    assertEq(assets, deposited, 'assets');
    assertEq(vault.balanceOf(onBehalf), 0, 'balanceOf(onBehalf)');
    assertEq(loanToken.balanceOf(receiver), deposited, 'loanToken.balanceOf(receiver)');
    assertEq(allMarkets[0].supplyAssets(address(loanToken), pos), 0, 'expectedSupplyAssets(vault)');
  }

  function testRedeemNotDeposited(uint256 deposited) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    vm.prank(supplier);
    vm.expectRevert(bytes('ERC20: burn amount exceeds balance'));
    vault.redeem(shares, supplier, supplier);
  }

  function testRedeemNotApproved(uint256 deposited) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    vm.prank(receiver);
    vm.expectRevert(bytes('ERC20: insufficient allowance'));
    vault.redeem(shares, receiver, onBehalf);
  }

  function testWithdrawNotApproved(uint256 assets) public {
    assets = bound(assets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, assets);

    vm.prank(supplier);
    vault.deposit(assets, onBehalf);

    vm.prank(receiver);
    vm.expectRevert(bytes('ERC20: insufficient allowance'));
    vault.withdraw(assets, receiver, onBehalf);
  }

  function testTransferFrom(uint256 deposited, uint256 toTransfer) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    toTransfer = bound(toTransfer, 0, shares);

    vm.prank(onBehalf);
    vault.approve(supplier, toTransfer);

    vm.prank(supplier);
    vault.transferFrom(onBehalf, receiver, toTransfer);

    assertEq(vault.balanceOf(onBehalf), shares - toTransfer, 'balanceOf(onBehalf)');
    assertEq(vault.balanceOf(receiver), toTransfer, 'balanceOf(receiver)');
    assertEq(vault.balanceOf(supplier), 0, 'balanceOf(supplier)');
  }

  function testTransferFromNotApproved(uint256 deposited, uint256 amount) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 shares = vault.deposit(deposited, onBehalf);

    amount = bound(amount, 0, shares);

    vm.prank(supplier);
    vm.expectRevert(bytes('ERC20: insufficient allowance'));
    vault.transferFrom(onBehalf, receiver, shares);
  }

  function testWithdrawMoreThanBalanceButLessThanTotalAssets(uint256 deposited, uint256 assets) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.startPrank(supplier);
    vault.deposit(deposited / 2, onBehalf);
    vault.deposit(deposited / 2, supplier);
    vm.stopPrank();

    assets = bound(assets, deposited / 2 + 1, vault.totalAssets());

    vm.expectRevert(bytes('ERC20: burn amount exceeds balance'));
    vm.prank(onBehalf);
    vault.withdraw(assets, receiver, onBehalf);
  }

  function testWithdrawMoreThanTotalAssets(uint256 deposited, uint256 assets) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assets = bound(assets, deposited + 1, type(uint256).max / (deposited + 1));

    vm.prank(onBehalf);
    vm.expectRevert(CuratedErrorsLib.NotEnoughLiquidity.selector);
    vault.withdraw(assets, receiver, onBehalf);
  }

  function testWithdrawMoreThanBalanceAndLiquidity(uint256 deposited, uint256 assets) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assets = bound(assets, deposited + 1, type(uint256).max / (deposited + 1));

    collateralToken.mint(borrower, type(uint128).max);

    // Borrow liquidity.
    vm.startPrank(borrower);
    allMarkets[0].supplySimple(address(collateralToken), borrower, type(uint128).max, 0);
    allMarkets[0].borrowSimple(address(loanToken), borrower, 1, 0);

    vm.startPrank(onBehalf);
    vm.expectRevert(CuratedErrorsLib.NotEnoughLiquidity.selector);
    vault.withdraw(assets, receiver, onBehalf);
  }

  function testTransfer(uint256 deposited, uint256 toTransfer) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    uint256 minted = vault.deposit(deposited, onBehalf);

    toTransfer = bound(toTransfer, 0, minted);

    vm.prank(onBehalf);
    vault.transfer(receiver, toTransfer);

    assertEq(vault.balanceOf(supplier), 0, 'balanceOf(supplier)');
    assertEq(vault.balanceOf(onBehalf), minted - toTransfer, 'balanceOf(onBehalf)');
    assertEq(vault.balanceOf(receiver), toTransfer, 'balanceOf(receiver)');
  }

  function testMaxWithdraw(uint256 depositedAssets, uint256 borrowedAssets) public {
    depositedAssets = bound(depositedAssets, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    borrowedAssets = bound(borrowedAssets, MIN_TEST_ASSETS, depositedAssets);

    loanToken.mint(supplier, depositedAssets);

    vm.prank(supplier);
    vault.deposit(depositedAssets, onBehalf);

    collateralToken.mint(borrower, type(uint128).max);

    vm.startPrank(borrower);
    allMarkets[0].supplySimple(address(collateralToken), borrower, type(uint128).max, 0);
    allMarkets[0].borrowSimple(address(loanToken), borrower, borrowedAssets, 0);

    assertEq(vault.maxWithdraw(onBehalf), depositedAssets - borrowedAssets, 'maxWithdraw(onBehalf)');
  }

  // todo test flashloans
  // function testMaxWithdrawFlashLoan(uint256 supplied, uint256 deposited) public {
  //   supplied = bound(supplied, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
  //   deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);

  //   loanToken.mint(supplier, supplied);

  //   vm.prank(supplier);
  //   allMarkets[0].supplySimple(address(loanToken), onBehalf, type(uint128).max, 0);

  //   loanToken.mint(supplier, deposited);

  //   vm.prank(supplier);
  //   vault.deposit(deposited, onBehalf);

  //   assertGt(vault.maxWithdraw(onBehalf), 0);

  //   loanToken.approve(address(allMarkets[0]), type(uint256).max);
  //   allMarkets[0].flashLoanSimple(address(this), address(loanToken), loanToken.balanceOf(address(allMarkets[0])), hex'');
  // }

  function testMaxDeposit() public {
    _setCap(allMarkets[0], 1 ether);

    IPool[] memory supplyQueue = new IPool[](1);
    supplyQueue[0] = allMarkets[0];

    vm.prank(allocator);
    vault.setSupplyQueue(supplyQueue);

    loanToken.mint(supplier, 1 ether);
    collateralToken.mint(borrower, 2 ether);

    vm.prank(supplier);
    allMarkets[0].supplySimple(address(loanToken), supplier, 1 ether, 0);

    vm.startPrank(borrower);
    allMarkets[0].supplySimple(address(collateralToken), borrower, 2 ether, 0);
    allMarkets[0].borrowSimple(address(loanToken), borrower, 1 ether, 0);
    vm.stopPrank();

    _forward(1000);
    oracleB.updateRoundTimestamp();

    loanToken.mint(supplier, 1 ether);

    vm.prank(supplier);
    vault.deposit(1 ether, onBehalf);

    assertEq(vault.maxDeposit(supplier), 0);
  }

  function executeOperation(address, uint256, uint256, address, bytes calldata) external view returns (bool) {
    assertEq(vault.maxWithdraw(onBehalf), 0);
    return true;
  }
}
