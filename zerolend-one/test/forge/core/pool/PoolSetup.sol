// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {DataTypes} from '../../../../contracts/core/pool/configuration/DataTypes.sol';
import {IPool} from '../../../../contracts/interfaces/pool/IPool.sol';

import './CorePoolTests.sol';
import {ArrayLib} from './helpers/ArrayLib.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

abstract contract PoolSetup is CorePoolTests {
  using ArrayLib for address[];

  IPool internal pool;

  uint256 internal constant HIGH_COLLATERAL_AMOUNT = 1e35;
  uint256 internal constant MIN_TEST_AMOUNT = 100;
  uint256 internal constant MAX_TEST_AMOUNT = 1e28;
  uint256 internal constant MIN_TEST_SHARES = MIN_TEST_AMOUNT * 1e6;
  uint256 internal constant MAX_TEST_SHARES = MAX_TEST_AMOUNT * 1e6;
  uint256 internal constant MIN_TEST_LLTV = 0.01 ether;
  uint256 internal constant MAX_TEST_LLTV = 0.99 ether;
  uint256 internal constant DEFAULT_TEST_LLTV = 0.8 ether;
  uint256 internal constant MIN_COLLATERAL_PRICE = 1e3;
  uint256 internal constant MAX_COLLATERAL_PRICE = 1e18;
  uint256 internal constant MAX_COLLATERAL_ASSETS = 1e28;

  bytes32 pos;

  function _setUpPool() internal {
    _setUpCorePool();
    poolFactory.createPool(_basicPoolInitParams());
    IPool poolAddr = poolFactory.pools(0);
    pool = IPool(address(poolAddr));

    pos = keccak256(abi.encodePacked(address(owner), 'index', uint256(0)));
  }

  function _basicPoolInitParams() internal view returns (DataTypes.InitPoolParams memory p) {
    address[] memory assets = new address[](4);
    assets[0] = address(tokenA);
    assets[1] = address(tokenB);
    assets[2] = address(tokenC);
    assets[3] = address(wethToken);

    address[] memory rateStrategyAddresses = new address[](4);
    rateStrategyAddresses[0] = address(irStrategy);
    rateStrategyAddresses[1] = address(irStrategy);
    rateStrategyAddresses[2] = address(irStrategy);
    rateStrategyAddresses[3] = address(irStrategy);

    address[] memory sources = new address[](4);
    sources[0] = address(oracleA);
    sources[1] = address(oracleB);
    sources[2] = address(oracleC);
    sources[3] = address(oracleD);

    DataTypes.InitReserveConfig memory config = _basicConfig();

    DataTypes.InitReserveConfig[] memory configurationLocal = new DataTypes.InitReserveConfig[](4);
    configurationLocal[0] = config;
    configurationLocal[1] = config;
    configurationLocal[2] = config;
    configurationLocal[3] = config;

    address[] memory admins = new address[](1);
    admins[0] = address(this);

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

  function _basicConfig() internal pure returns (DataTypes.InitReserveConfig memory c) {
    c = DataTypes.InitReserveConfig({
      ltv: 7500,
      liquidationThreshold: 8000,
      liquidationBonus: 10_500,
      decimals: 18,
      frozen: false,
      borrowable: true,
      borrowCap: 0,
      supplyCap: 0
    });
  }

  function _mintAndApprove(address user, MintableERC20 token, uint256 amount, address toApprove) public {
    vm.startPrank(user);
    token.mint(user, amount);
    token.approve(toApprove, amount);
    vm.stopPrank();
  }

  function _supply(address user, MintableERC20 token, uint256 amount) internal {
    _mintAndApprove(user, token, amount, address(pool));
    vm.prank(user);
    pool.supplySimple(address(token), user, amount, 0);
  }

  function _borrow(address user, MintableERC20 token, uint256 amount) internal {
    vm.prank(user);
    pool.borrowSimple(address(token), user, amount, 0);
  }

  function _supplyCollateralForBorrower(MintableERC20 collateral, address borrower) internal {
    _mintAndApprove(borrower, collateral, HIGH_COLLATERAL_AMOUNT, address(pool));
    vm.prank(borrower);
    pool.supplySimple(address(collateral), borrower, HIGH_COLLATERAL_AMOUNT, 0);
  }

  function _randomCandidate(address[] memory candidates, uint256 seed) internal pure returns (address) {
    if (candidates.length == 0) return address(0);
    return candidates[seed % candidates.length];
  }

  function _randomNonZero(address[] memory users, uint256 seed) internal pure returns (address) {
    users = users.removeAll(address(0));
    return _randomCandidate(users, seed);
  }

  function _boundHealthyPosition(
    uint256 amountCollateral,
    uint256 amountBorrowed,
    uint256 priceCollateral
  ) internal pure returns (uint256, uint256, uint256) {
    priceCollateral = bound(priceCollateral, MIN_COLLATERAL_PRICE, MAX_COLLATERAL_PRICE);
    amountBorrowed = bound(amountBorrowed, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);

    // uint256 minCollateral = amountBorrowed.wDivUp(marketParams.lltv).mulDivUp(ORACLE_PRICE_SCALE, priceCollateral);

    // if (minCollateral <= MAX_COLLATERAL_ASSETS) {
    //   amountCollateral = bound(amountCollateral, minCollateral, MAX_COLLATERAL_ASSETS);
    // } else {
    //   amountCollateral = MAX_COLLATERAL_ASSETS;
    //   amountBorrowed = Math.min(
    //     amountBorrowed.wMulDown(marketParams.lltv).mulDivDown(priceCollateral, ORACLE_PRICE_SCALE),
    //     MAX_TEST_AMOUNT
    //   );
    // }

    // vm.assume(amountBorrowed > 0);
    // vm.assume(amountCollateral < type(uint256).max / priceCollateral);
    return (amountCollateral, amountBorrowed, priceCollateral);
  }
}
