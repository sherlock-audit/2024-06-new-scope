// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {MathLib, WAD} from '../../../../../contracts/core/vaults/libraries/MathLib.sol';

import {IPool} from '../../../../../contracts/interfaces/pool/IPool.sol';
import {ICuratedVault} from '../../../../../contracts/interfaces/vaults/ICuratedVault.sol';

import {DefaultReserveInterestRateStrategy, MintableERC20, MockV3Aggregator} from '../../pool/CorePoolTests.sol';
import {DataTypes, PoolSetup} from '../../pool/PoolSetup.sol';

import {console} from '../../../../../lib/forge-std/src/console.sol';

uint256 constant BLOCK_TIME = 1;
uint256 constant MIN_TEST_ASSETS = 1e8;
uint256 constant MAX_TEST_ASSETS = 1e18 * 1000;
uint184 constant CAP = type(uint128).max;
uint256 constant NB_MARKETS = 3 + 1;

abstract contract BaseVaultTest is PoolSetup {
  using MathLib for uint256;

  // address internal OWNER = makeAddr('Owner');
  address internal supplier = makeAddr('supplier');
  address internal borrower = makeAddr('borrower');
  address internal repayer = makeAddr('repayer');
  address internal onBehalf = makeAddr('onBehalf');
  address internal receiver = makeAddr('receiver');
  address internal allocator = makeAddr('allocator');
  address internal curator = makeAddr('curator');
  address internal guardian = makeAddr('guardian');
  address internal feeRecipient = makeAddr('feeRecipient');
  address internal skimRecipient = makeAddr('skimRecipient');

  IPool[] internal allMarkets;
  IPool internal idleMarket;

  MintableERC20 internal loanToken;
  MintableERC20 internal collateralToken;
  MockV3Aggregator internal oracle;

  function _setUpBaseVault() internal {
    _setUpPool();

    loanToken = tokenA;
    collateralToken = tokenB;
    oracle = oracleA;

    // vm.label(address(morpho), 'Morpho');
    vm.label(address(loanToken), 'loanToken');
    vm.label(address(collateralToken), 'collateralToken');
    vm.label(address(oracle), 'oracle');
    vm.label(address(irStrategy), 'irStrategy');
    oracle.updateAnswer(1e8);

    // init the idle market
    _setupIdleMarket();

    // init markets
    for (uint8 i = 0; i < NB_MARKETS; i++) {
      IPool market = IPool(poolFactory.createPool(_basicPoolInitParams()));

      vm.label(address(market), _appendUintToString('market-', i));

      // give approvals
      vm.startPrank(supplier);
      loanToken.approve(address(market), type(uint256).max);
      collateralToken.approve(address(market), type(uint256).max);
      vm.stopPrank();

      vm.prank(borrower);
      collateralToken.approve(address(market), type(uint256).max);

      vm.prank(repayer);
      loanToken.approve(address(market), type(uint256).max);

      allMarkets.push(market);
    }

    allMarkets.push(idleMarket); // Must be pushed last.
  }

  function _setupIdleMarket() private {
    address[] memory idleAssets = new address[](1);
    address[] memory idleStrategies = new address[](1);
    address[] memory idleOracles = new address[](1);
    DataTypes.InitReserveConfig[] memory configurationLocal = new DataTypes.InitReserveConfig[](1);

    idleAssets[0] = address(loanToken);
    idleStrategies[0] = address(irStrategy);
    idleOracles[0] = address(oracle);
    configurationLocal[0] = _basicConfig();

    idleMarket = IPool(
      poolFactory.createPool(
        DataTypes.InitPoolParams({
          proxyAdmin: address(this),
          revokeProxy: false,
          admins: new address[](0),
          emergencyAdmins: new address[](0),
          riskAdmins: new address[](0),
          hook: address(0),
          assets: idleAssets,
          rateStrategyAddresses: idleStrategies,
          sources: idleOracles,
          configurations: configurationLocal
        })
      )
    );

    vm.label(address(idleMarket), 'market-IDLE');
  }

  function _accrueInterest(IPool pool) internal {
    pool.forceUpdateReserve(address(loanToken));
    pool.forceUpdateReserve(address(collateralToken));
  }

  /// @dev Returns a random market params from the list of markets enabled on Blue (except the idle market).
  function _randomMarketParams(uint256 seed) internal view returns (IPool) {
    return allMarkets[seed % (allMarkets.length - 1)];
  }

  function _removeAll(address[] memory inputs, address removed) internal pure returns (address[] memory result) {
    result = new address[](inputs.length);

    uint256 nbAddresses;
    for (uint256 i; i < inputs.length; ++i) {
      address input = inputs[i];
      if (input != removed) {
        result[nbAddresses] = input;
        ++nbAddresses;
      }
    }

    assembly {
      mstore(result, nbAddresses)
    }
  }
}
