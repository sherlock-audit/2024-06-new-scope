// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz
// Telegram: https://t.me/zerolendxyz

import {ReserveConfiguration} from '../../core/pool/configuration/ReserveConfiguration.sol';
import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';

import {IAggregatorV3Interface} from 'contracts/interfaces/IAggregatorV3Interface.sol';

import {INFTPositionManager} from '../../interfaces/INFTPositionManager.sol';
import {IPoolConfigurator} from '../../interfaces/IPoolConfigurator.sol';
import {IRevokableBeaconProxy} from '../../interfaces/IRevokableBeaconProxy.sol';
import {DataTypes, IPool} from '../../interfaces/pool/IPool.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

contract UIHelper {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPoolFactory public factory;
  INFTPositionManager public manager;
  IPoolConfigurator public configurator;

  struct ReserveConfig {
    address asset;
    address interestRateStrategy;
    address oracle;
    bool borrowable;
    bool collateral;
    bool frozen;
    string name;
    string symbol;
    uint256 borrowCap;
    uint256 decimals;
    uint256 liquidationBonus;
    uint256 liquidationThreshold;
    uint256 ltv;
    uint256 supplyCap;
    uint256 balanceOnchain;
    uint256 totalSupplyOnchain;
    uint128 liquidityIndex;
    uint128 liquidityRate;
    uint128 borrowIndex;
    uint128 borrowRate;
    uint40 reserveLastUpdateTimestamp;
    uint256 debtShares;
    uint256 supplyShares;
    uint128 underlyingBalance;
    uint256 debtAssets;
    uint256 supplyAssets;
    uint256 latestPrice;
  }

  struct PoolConfig {
    address hook;
    address proxyAdmin;
    address[] emergencyAdmins;
    address[] poolAdmins;
    address[] riskAdmins;
    bool proxyRevoked;
    ReserveConfig[] reserves;
    uint16 reservesCount;
  }

  struct NftPositions {
    uint256 tokenId;
    address pool;
    uint256 healthFactor;
    INFTPositionManager.Asset[] assets;
    bool isBurnAllowed;
  }

  constructor(address _factory, address _configurator, address _manager) {
    factory = IPoolFactory(_factory);
    configurator = IPoolConfigurator(_configurator);
    manager = INFTPositionManager(_manager);
  }

  function getPoolAssetConfig(IPool pool, address asset) public view returns (ReserveConfig memory config) {
    DataTypes.ReserveConfigurationMap memory configRaw = pool.getConfiguration(asset);
    DataTypes.ReserveData memory data = pool.getReserveData(asset);
    DataTypes.ReserveSupplies memory supplies = pool.getTotalSupplyRaw(asset);

    config.borrowable = configRaw.getBorrowingEnabled();
    config.frozen = configRaw.getFrozen();
    config.borrowCap = configRaw.getBorrowCap();
    config.decimals = configRaw.getDecimals();
    config.liquidationBonus = configRaw.getLiquidationBonus();
    config.liquidationThreshold = configRaw.getLiquidationThreshold();
    config.ltv = configRaw.getLtv();
    config.supplyCap = configRaw.getSupplyCap();

    config.collateral = config.ltv > 0;

    config.name = IERC20Metadata(asset).name();
    config.symbol = IERC20Metadata(asset).symbol();
    config.balanceOnchain = IERC20(asset).balanceOf(address(pool));
    config.totalSupplyOnchain = IERC20(asset).totalSupply();

    config.liquidityIndex = data.liquidityIndex;
    config.liquidityRate = data.liquidityRate;
    config.borrowIndex = data.borrowIndex;
    config.borrowRate = data.borrowRate;

    config.debtShares = supplies.debtShares;
    config.debtAssets = pool.totalDebt(asset);
    config.supplyShares = supplies.supplyShares;
    config.supplyAssets = pool.totalAssets(asset);
    config.underlyingBalance = supplies.underlyingBalance;

    config.asset = asset;
    config.interestRateStrategy = data.interestRateStrategyAddress;
    config.oracle = data.oracle;

    (, int256 price,,,) = IAggregatorV3Interface(data.oracle).latestRoundData();

    config.latestPrice = uint256(price);
  }

  function getPoolFullConfigByIndex(uint256 start, uint256 end) public view returns (PoolConfig[] memory configs) {
    uint256 count = factory.poolsLength();
    if (end > count) end = count;
    if (start >= end) return configs;

    configs = new PoolConfig[](end - start);
    for (uint256 i = start; i < end; i++) {
      IPool pool = factory.pools(i);
      configs[i - start] = getPoolFullConfig(pool);
    }
  }

  function getPoolFullConfig(IPool pool) public view returns (PoolConfig memory config) {
    address[] memory reserves = pool.getReservesList();
    IRevokableBeaconProxy proxy = IRevokableBeaconProxy(address(pool));

    config.hook = address(pool.getHook());
    config.reservesCount = uint16(reserves.length);
    config.reserves = new ReserveConfig[](reserves.length);

    for (uint256 i = 0; i < reserves.length; i++) {
      config.reserves[i] = getPoolAssetConfig(pool, reserves[i]);
    }

    // details about the pool as a proxy
    config.proxyAdmin = proxy.admin();
    config.proxyRevoked = proxy.isBeaconRevoked();

    // find all the admins and send it back
    config.poolAdmins = getAllRoles(pool, configurator, configurator.POOL_ADMIN_ROLE());
    config.emergencyAdmins = getAllRoles(pool, configurator, configurator.EMERGENCY_ADMIN_ROLE());
    config.riskAdmins = getAllRoles(pool, configurator, configurator.RISK_ADMIN_ROLE());
  }

  function getAllRoles(IPool _pool, IPoolConfigurator _configurator, bytes32 role) public view returns (address[] memory users) {
    bytes32 poolRole = _configurator.getRoleFromPool(_pool, role);
    uint256 count = _configurator.getRoleMemberCount(poolRole);
    users = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      users[i] = _configurator.getRoleMember(poolRole, i);
    }
  }

  function getNftPositions(address user) public view returns (NftPositions[] memory positions) {
    uint256 count = manager.balanceOf(user);
    positions = new NftPositions[](count);

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = manager.tokenOfOwnerByIndex(user, i);
      INFTPositionManager.Position memory position = manager.positions(tokenId);
      INFTPositionManager.Asset[] memory _assets = getNftPosition(tokenId);

      positions[i].pool = position.pool;
      positions[i].tokenId = tokenId;
      positions[i].assets = _assets;
    }
  }

  /**
   * @notice Returns the balances of the user for the given tokens
   * @dev If the token address is 0x0, it will return the balance of the user in ETH
   * @param user The user to get the balances for
   * @param tokens The tokens to get the balances for
   */
  function getBalances(address user, address[] memory tokens) public view returns (uint256[] memory balances) {
    balances = new uint256[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == address(0)) balances[i] = user.balance;
      else balances[i] = IERC20(tokens[i]).balanceOf(user);
    }
  }

  function getNftPosition(uint256 tokenId) public view returns (INFTPositionManager.Asset[] memory assets) {
    INFTPositionManager.Position memory position = manager.positions(tokenId);

    IPool pool = IPool(position.pool);
    address[] memory _assets = pool.getReservesList();
    uint256 length = _assets.length;

    assets = new INFTPositionManager.Asset[](length);
    for (uint256 i; i < length;) {
      address asset = assets[i].asset = _assets[i];
      assets[i].balance = pool.getBalance(asset, address(manager), tokenId);
      assets[i].debt = pool.getDebt(asset, address(manager), tokenId);
      unchecked {
        ++i;
      }
    }

    return assets;
  }
}
