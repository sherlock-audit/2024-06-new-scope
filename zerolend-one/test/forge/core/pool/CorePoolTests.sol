// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Pool} from '../../../../contracts/core/pool/Pool.sol';

import {PoolFactory} from '../../../../contracts/core/pool/PoolFactory.sol';
import {PoolConfigurator} from '../../../../contracts/core/pool/manager/PoolConfigurator.sol';
import {PoolErrorsLib} from '../../../../contracts/interfaces/errors/PoolErrorsLib.sol';
import {PoolEventsLib} from '../../../../contracts/interfaces/events/PoolEventsLib.sol';

import {DefaultReserveInterestRateStrategy} from '../../../../contracts/periphery/ir/DefaultReserveInterestRateStrategy.sol';

import {MintableERC20} from '../../../../contracts/mocks/MintableERC20.sol';

import {Test, console} from '../../../../lib/forge-std/src/Test.sol';
import {MockV3Aggregator} from 'contracts/mocks/MockV3Aggregator.sol';

import {WETH9Mocked} from 'contracts/mocks/WETH9Mocked.sol';

abstract contract CorePoolTests is Test {
  PoolFactory public poolFactory;
  Pool public poolImplementation;
  PoolConfigurator public configurator;

  DefaultReserveInterestRateStrategy public irStrategy;

  MintableERC20 public tokenA;
  MintableERC20 public tokenB;
  MintableERC20 public tokenC;

  WETH9Mocked public wethToken;

  MockV3Aggregator public oracleA;
  MockV3Aggregator public oracleB;
  MockV3Aggregator public oracleC;
  MockV3Aggregator public oracleD;

  uint256 internal constant BLOCK_TIME = 1;

  address public owner = makeAddr('owner');
  address public whale = makeAddr('whale');
  address public ant = makeAddr('ant');
  address public governance = makeAddr('governance');

  function _setUpCorePool() internal {
    poolImplementation = new Pool();

    poolFactory = new PoolFactory(address(poolImplementation));
    configurator = new PoolConfigurator(address(poolFactory));

    poolFactory.setConfigurator(address(configurator));

    // create dummy tokens
    tokenA = new MintableERC20('TOKEN A', 'TOKENA');
    tokenB = new MintableERC20('TOKEN B', 'TOKENB');
    tokenC = new MintableERC20('TOKEN C', 'TOKENC');

    wethToken = new WETH9Mocked();

    oracleA = new MockV3Aggregator(8, 1e8);
    oracleB = new MockV3Aggregator(18, 2 * 1e8);
    oracleC = new MockV3Aggregator(8, 100 * 1e8);
    oracleD = new MockV3Aggregator(6, 3000 * 1e8);

    irStrategy = new DefaultReserveInterestRateStrategy(47 * 1e25, 0, 7 * 1e25, 30 * 1e25);

    vm.label(address(poolFactory), 'PoolFactory');
    vm.label(address(tokenA), 'tokenA');
    vm.label(address(tokenB), 'tokenB');
    vm.label(address(tokenC), 'tokenC');
    vm.label(address(wethToken), 'wethToken');
    vm.label(address(oracleA), 'oracleA');
    vm.label(address(oracleB), 'oracleB');
    vm.label(address(oracleC), 'oracleC');
    vm.label(address(oracleD), 'oracleD');
    vm.label(address(irStrategy), 'irStrategy');
    vm.label(address(configurator), 'configurator');
  }

  /// @dev Rolls & warps the given number of blocks forward the blockchain.
  function _forward(uint256 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * BLOCK_TIME); // Block speed should depend on test network.
  }

  /// @dev Bounds the fuzzing input to a realistic number of blocks.
  function _boundBlocks(uint256 blocks) internal pure returns (uint256) {
    return bound(blocks, 2, type(uint24).max);
  }

  /// @dev Bounds the fuzzing input to a non-zero address.
  /// @dev This function should be used in place of `vm.assume` in invariant test handler functions:
  /// https://github.com/foundry-rs/foundry/issues/4190.
  function _boundAddressNotZero(address input) internal pure returns (address) {
    return address(uint160(bound(uint256(uint160(input)), 1, type(uint160).max)));
  }

  function _appendUintToString(string memory inStr, uint8 v) internal pure returns (string memory) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
      uint8 remainder = v % 10;
      v = v / 10;
      reversed[i++] = bytes1(48 + remainder);
    }
    bytes memory inStrb = bytes(inStr);
    bytes memory s = new bytes(inStrb.length + i);
    uint256 j;
    for (j = 0; j < inStrb.length; j++) {
      s[j] = inStrb[j];
    }
    for (j = 0; j < i; j++) {
      s[j + inStrb.length] = reversed[i - 1 - j];
    }
    return string(s);
  }
}
