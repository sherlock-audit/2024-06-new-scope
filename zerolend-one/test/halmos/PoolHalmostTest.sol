// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import './helpers/BasePoolHalmosTest.sol';

/// @title Pool Halmos Tests
/// @author ZeroLend
/// @notice Runs basic formal verification tests on the Pool contract
/// @custom:halmos --solver-timeout-assertion 0
contract PoolHalmosTest is BasePoolHalmosTest {
  /// @notice Check that there is always less borrow than supply on the market. This is a solvency test.
  /// @param selector The function selector to call.
  /// @param caller The address of the caller.
  function check_borrowLessThanSupply(bytes4 selector, address caller) public {
    (uint256 supplyBefore,,,) = pool.marketBalances(address(loan));
    (,, uint256 debtBefore,) = pool.marketBalances(address(collateral));

    // fund the caller
    loan.mint(caller, 100e18);
    collateral.mint(caller, 100e18);

    // give approvals
    vm.startPrank(caller);
    loan.approve(address(pool), type(uint256).max);
    collateral.approve(address(pool), type(uint256).max);
    vm.stopPrank();

    vm.assume(debtBefore <= supplyBefore);

    _callPool(selector, caller);

    (uint256 supplyAfter,,,) = pool.marketBalances(address(loan));
    (,, uint256 debtAfter,) = pool.marketBalances(address(collateral));

    assert(debtAfter <= supplyAfter); // Borrow should be less than supply
  }

  // /// @notice Tests the internal borrow and supply variables of the pool contract. The goal here is to
  // /// ensure that no matter happens in the contract, the pool's internal accounting variables
  // /// always adds up to the `erc20.balance(pool)` values.
  // /// @param action1 An arbitary action (supply, borrow etc...)
  // /// @param caller1 The address of the first caller.
  // function check_poolAccountingVariables(bytes4 action1, address caller1) public {
  //   // fund the callers
  //   collateral.mint(caller1, 100e18);
  //   loan.mint(caller1, 100e18);

  //   // give approvals for caller 1
  //   vm.startPrank(caller1);
  //   loan.approve(address(pool), type(uint256).max);
  //   collateral.approve(address(pool), type(uint256).max);
  //   vm.stopPrank();

  //   // execute a random call
  //   _callPool(action1, caller1);

  //   // wait for some days (to accure some interest) and update the reserves
  //   skip(86_400 * 100);
  //   pool.forceUpdateReserves();

  //   // ensure that the internal accounting variables always match
  //   (uint256 loanSupply,, uint256 loanDebt,) = pool.marketBalances(address(loan));
  //   assert(loan.balanceOf(address(pool)) == loanSupply - loanDebt);

  //   (uint256 collateralSupply,, uint256 collateralDebt,) = pool.marketBalances(address(loan));
  //   assert(collateral.balanceOf(address(pool)) <= collateralSupply - collateralDebt);
  // }

  // /// @notice This check ensures that the math between shares and assets is always correct and adds up
  // /// to the `erc20.balanceOf(...)` values for the user and for the pool.
  // /// @param action1 An arbitary action (supply, borrow etc...)
  // /// @param action2 A second arbitary action (supply, borrow etc...)
  // /// @param caller1 The address of the first caller.
  // /// @param caller2 The address of the second caller.
  // function check_poolSharesMath(bytes4 action1, bytes4 action2, address caller1, address caller2) public {
  //   // ensure that the internal accounting variables always match
  //   // (uint256 loanSupply, uint256 loanShares, uint256 loanDebt, uint256 loanDebtShares) = pool.marketBalances(address(loan));
  //   // do the math between supply and shares
  // }
}
