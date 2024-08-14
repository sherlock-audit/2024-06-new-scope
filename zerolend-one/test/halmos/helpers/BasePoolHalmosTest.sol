// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {DataTypes, Pool} from '../../../contracts/core/pool/Pool.sol';
import {MintableERC20} from '../../../contracts/mocks/MintableERC20.sol';

import {DefaultReserveInterestRateStrategy} from '../../../contracts/periphery/ir/DefaultReserveInterestRateStrategy.sol';
import {MockV3Aggregator} from 'contracts/mocks/MockV3Aggregator.sol';

import {Test} from '../../../lib/forge-std/src/Test.sol';

import {console} from '../../../lib/forge-std/src/console.sol';
import {SymTest} from '../../../lib/halmos-cheatcodes/src/SymTest.sol';

/// @title Pool Halmos Tests
/// @author ZeroLend
/// @notice Runs basic formal verification tests on the Pool contract
/// @custom:halmos --solver-timeout-assertion 0
contract BasePoolHalmosTest is SymTest, Test {
  Pool internal pool;
  DefaultReserveInterestRateStrategy public irStrategy;
  MintableERC20 internal loan;
  MintableERC20 internal collateral;
  MockV3Aggregator internal oracleLoan;
  MockV3Aggregator internal oracleCollateral;

  // used by the pool to calculate fees
  uint256 public reserveFactor = 0;
  uint256 public flashLoanPremiumToProtocol = 0;
  uint256 public liquidationProtocolFeePercentage = 0;

  address internal owner;

  function setUp() public virtual {
    owner = svm.createAddress('owner');

    // create dummy tokens
    loan = new MintableERC20('TOKEN A', 'TOKENA');
    collateral = new MintableERC20('TOKEN B', 'TOKENB');

    oracleLoan = new MockV3Aggregator(8, 1e8);
    oracleCollateral = new MockV3Aggregator(18, 2 * 1e8);
    irStrategy = new DefaultReserveInterestRateStrategy(47 * 1e25, 0, 7 * 1e25, 30 * 1e25);

    pool = new Pool();
    pool.initialize(_poolInitParams());

    uint256 loanAmount = svm.createUint256('loanAmount');
    uint256 collateralAmount = svm.createUint256('collateralAmount');
    vm.assume(loanAmount > 0 && collateralAmount > 0);

    // mint some tokens
    loan.mint(owner, loanAmount);
    collateral.mint(owner, collateralAmount);

    // fund the pool
    vm.startPrank(owner);

    loan.approve(address(pool), type(uint256).max);
    collateral.approve(address(pool), type(uint256).max);

    pool.supplySimple(address(loan), owner, loanAmount, 0);
    pool.supplySimple(address(collateral), owner, collateralAmount, 0);
    vm.stopPrank();
  }

  function _poolInitParams() private view returns (DataTypes.InitPoolParams memory p) {
    address[] memory assets = new address[](2);
    assets[0] = address(loan);
    assets[1] = address(collateral);

    address[] memory admins = new address[](1);
    assets[0] = address(owner);

    address[] memory rateStrategyAddresses = new address[](2);
    rateStrategyAddresses[0] = address(irStrategy);
    rateStrategyAddresses[1] = address(irStrategy);

    address[] memory sources = new address[](2);
    sources[0] = address(oracleLoan);
    sources[1] = address(oracleCollateral);

    DataTypes.InitReserveConfig[] memory configurationLocal = new DataTypes.InitReserveConfig[](2);
    configurationLocal[0] = _config(false);
    configurationLocal[1] = _config(true);

    p = DataTypes.InitPoolParams({
      proxyAdmin: address(this),
      revokeProxy: false,
      admins: admins,
      emergencyAdmins: new address[](0),
      riskAdmins: new address[](0),
      hook: address(0),
      assets: assets,
      rateStrategyAddresses: rateStrategyAddresses,
      sources: sources,
      configurations: configurationLocal
    });
  }

  function _config(bool borrowable) private pure returns (DataTypes.InitReserveConfig memory c) {
    c = DataTypes.InitReserveConfig({
      ltv: 7500,
      liquidationThreshold: 8000,
      liquidationBonus: 10_500,
      decimals: 18,
      frozen: false,
      borrowable: borrowable,
      borrowCap: 0,
      supplyCap: 0
    });
  }

  function _callPool(bytes4 selector, address caller) internal {
    vm.assume(
      selector == pool.supplySimple.selector || selector == pool.repaySimple.selector || selector == pool.withdrawSimple.selector
        || selector == pool.borrowSimple.selector
    );

    uint256 amount = svm.createUint256('amount');
    uint256 index = svm.createUint256('index');
    address dest = svm.createAddress('dest');

    vm.prank(caller);
    (bool success,) = address(pool).call(abi.encodePacked(selector, abi.encode(address(loan), dest, amount, index)));
    vm.assume(success);
  }
}
