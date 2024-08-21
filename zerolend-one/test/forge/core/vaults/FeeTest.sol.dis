// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ConstantsLib} from '../../../../contracts/core/vaults/libraries/ConstantsLib.sol';
import './helpers/IntegrationVaultTest.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

uint256 constant FEE = 0.2 ether; // 20%

contract FeeTest is IntegrationVaultTest {
  using Math for uint256;
  using MathLib for uint256;

  function setUp() public {
    _setUpVault();

    _setFee(FEE);

    for (uint256 i; i < NB_MARKETS; ++i) {
      // Create some debt on the market to accrue interest.
      IPool pool = allMarkets[i];

      loanToken.mint(supplier, MAX_TEST_ASSETS);

      vm.prank(supplier);
      pool.supplySimple(address(loanToken), onBehalf, MAX_TEST_ASSETS, 0);

      uint256 collateral = uint256(MAX_TEST_ASSETS).wDivUp(0.7 ether);
      collateralToken.mint(borrower, collateral);

      vm.startPrank(borrower);
      pool.supplySimple(address(collateralToken), borrower, collateral, 0);
      pool.borrowSimple(address(loanToken), borrower, MAX_TEST_ASSETS, 0);
      vm.stopPrank();
    }

    _setCap(allMarkets[0], CAP);
    _sortSupplyQueueIdleLast();
  }

  function testSetFee(uint256 fee) public {
    fee = bound(fee, 0, ConstantsLib.MAX_FEE);
    vm.assume(fee != vault.fee());

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.SetFee(owner, fee);
    vm.prank(owner);
    vault.setFee(fee);

    assertEq(vault.fee(), fee, 'fee');
  }

  function _feeShares() internal view returns (uint256) {
    uint256 totalAssetsAfter = vault.totalAssets();
    uint256 interest = totalAssetsAfter - vault.lastTotalAssets();
    uint256 feeAssets = interest.mulDiv(FEE, WAD);

    return feeAssets.mulDiv(vault.totalSupply() + 1, totalAssetsAfter - feeAssets + 1, Math.Rounding.Down);
  }

  function testAccrueFeeWithinABlock(uint256 deposited, uint256 withdrawn) public {
    deposited = bound(deposited, MIN_TEST_ASSETS + 1, MAX_TEST_ASSETS);
    // The deposited amount is rounded down on Morpho and thus cannot be withdrawn in a block in most cases.
    withdrawn = bound(withdrawn, MIN_TEST_ASSETS, deposited - 1);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    vm.prank(onBehalf);
    vault.withdraw(withdrawn, receiver, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertApproxEqAbs(vault.balanceOf(feeRecipient), 0, 1, 'vault.balanceOf(feeRecipient)');
  }

  function testDepositAccrueFee(uint256 deposited, uint256 newDeposit, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    newDeposit = bound(newDeposit, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    loanToken.mint(supplier, newDeposit);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);

    vm.prank(supplier);
    vault.deposit(newDeposit, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
  }

  function testMintAccrueFee(uint256 deposited, uint256 newDeposit, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    newDeposit = bound(newDeposit, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    uint256 shares = vault.convertToShares(newDeposit);

    loanToken.mint(supplier, newDeposit);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);

    vm.prank(supplier);
    vault.mint(shares, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
  }

  function testRedeemAccrueFee(uint256 deposited, uint256 withdrawn, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    withdrawn = bound(withdrawn, MIN_TEST_ASSETS, deposited);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    uint256 shares = vault.convertToShares(withdrawn);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);

    vm.prank(onBehalf);
    vault.redeem(shares, receiver, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
  }

  function testWithdrawAccrueFee(uint256 deposited, uint256 withdrawn, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    withdrawn = bound(withdrawn, MIN_TEST_ASSETS, deposited);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);

    vm.prank(onBehalf);
    vault.withdraw(withdrawn, receiver, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
  }

  function testSetFeeAccrueFee(uint256 deposited, uint256 fee, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    fee = bound(fee, 0, FEE - 1);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);

    _setFee(fee);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
  }

  function testSetFeeRecipientAccrueFee(uint256 deposited, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets1');

    _forward(blocks);

    uint256 feeShares = _feeShares();
    vm.assume(feeShares != 0);

    vm.expectEmit(address(vault));
    emit CuratedEventsLib.AccrueInterest(vault.totalAssets(), feeShares);
    emit CuratedEventsLib.UpdateLastTotalAssets(vault.totalAssets());
    emit CuratedEventsLib.SetFeeRecipient(address(1));

    vm.prank(owner);
    vault.setFeeRecipient(address(1));

    assertApproxEqAbs(vault.lastTotalAssets(), vault.totalAssets(), 1, 'lastTotalAssets2');
    assertEq(vault.balanceOf(feeRecipient), feeShares, 'vault.balanceOf(feeRecipient)');
    assertEq(vault.balanceOf(address(1)), 0, 'vault.balanceOf(address(1))');
  }

  // todo
  // function testSetFeeNotOwner(uint256 fee) public {
  //   vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
  //   vault.setFee(fee);
  // }

  function testSetFeeMaxFeeExceeded(uint256 fee) public {
    fee = bound(fee, ConstantsLib.MAX_FEE + 1, type(uint256).max);

    vm.prank(owner);
    vm.expectRevert(CuratedErrorsLib.MaxFeeExceeded.selector);
    vault.setFee(fee);
  }

  function testSetFeeAlreadySet() public {
    vm.prank(owner);
    vm.expectRevert(CuratedErrorsLib.AlreadySet.selector);
    vault.setFee(FEE);
  }

  function testSetFeeZeroFeeRecipient(uint256 fee) public {
    fee = bound(fee, 1, ConstantsLib.MAX_FEE);

    vm.startPrank(owner);

    vault.setFee(0);
    vault.setFeeRecipient(address(0));

    vm.expectRevert(CuratedErrorsLib.ZeroFeeRecipient.selector);
    vault.setFee(fee);

    vm.stopPrank();
  }

  function testSetFeeRecipientAlreadySet() public {
    vm.prank(owner);
    vm.expectRevert(CuratedErrorsLib.AlreadySet.selector);
    vault.setFeeRecipient(feeRecipient);
  }

  function testSetZeroFeeRecipientWithFee() public {
    vm.prank(owner);
    vm.expectRevert(CuratedErrorsLib.ZeroFeeRecipient.selector);
    vault.setFeeRecipient(address(0));
  }

  function testConvertToAssetsWithFeeAndInterest(uint256 deposited, uint256 assets, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    assets = bound(assets, 1, MAX_TEST_ASSETS);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    uint256 sharesBefore = vault.convertToShares(assets);

    _forward(blocks);

    uint256 feeShares = _feeShares();
    uint256 expectedShares = assets.mulDiv(vault.totalSupply() + feeShares + 1, vault.totalAssets() + 1, Math.Rounding.Down);
    uint256 shares = vault.convertToShares(assets);

    assertEq(shares, expectedShares, 'shares');
    assertLt(shares, sharesBefore, 'shares decreased');
  }

  function testConvertToSharesWithFeeAndInterest(uint256 deposited, uint256 shares, uint256 blocks) public {
    deposited = bound(deposited, MIN_TEST_ASSETS, MAX_TEST_ASSETS);
    shares = bound(shares, 1, MAX_TEST_ASSETS);
    blocks = _boundBlocks(blocks);

    loanToken.mint(supplier, deposited);

    vm.prank(supplier);
    vault.deposit(deposited, onBehalf);

    uint256 assetsBefore = vault.convertToAssets(shares);

    _forward(blocks);

    uint256 feeShares = _feeShares();
    uint256 expectedAssets = shares.mulDiv(vault.totalAssets() + 1, vault.totalSupply() + feeShares + 1, Math.Rounding.Down);
    uint256 assets = vault.convertToAssets(shares);

    assertEq(assets, expectedAssets, 'assets');
    assertGe(assets, assetsBefore, 'assets increased');
  }
}
