// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {TokenConfiguration} from '../../../../contracts/core/pool/configuration/TokenConfiguration.sol';
import {WadRayMath} from '../../../../contracts/core/pool/utils/WadRayMath.sol';
import {IPoolFactory} from './../../../../contracts/interfaces/IPoolFactory.sol';
import './PoolSetup.sol';

contract PoolSharesTest is PoolSetup {
  using TokenConfiguration for address;

  bytes32 antPosition;

  function setUp() public {
    _setUpPool();
    antPosition = ant.getPositionId(0);
  }

  function testUserSupplyShares(uint256 amount) public {
    amount = bound(amount, 1e4, MAX_COLLATERAL_ASSETS);

    _supply(ant, tokenA, amount);

    uint256 assets = pool.supplyAssets(address(tokenA), antPosition);
    uint256 shares = pool.supplyShares(address(tokenA), antPosition);
    assertEq(shares, amount);
    assertEq(assets, amount);
  }

  function testUserSupplySharesAfterInterest(uint256 supplyAmount, uint256 borrowAmount) public {
    supplyAmount = bound(supplyAmount, 10e18, 10e24);
    borrowAmount = bound(borrowAmount, 1e16, supplyAmount / 10);

    _supply(ant, tokenA, supplyAmount);
    _borrow(ant, tokenA, borrowAmount);

    // accumulate interest for 1000 blocks
    _forward(1000);
    pool.forceUpdateReserves();

    // shares should remain the same but assets should increase
    uint256 assets = pool.supplyAssets(address(tokenA), antPosition);
    uint256 shares = pool.supplyShares(address(tokenA), antPosition);
    assertEq(shares, supplyAmount);
    assertGt(assets, supplyAmount);
  }
}
