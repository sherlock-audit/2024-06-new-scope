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

import {DataTypes} from '../core/pool/configuration/DataTypes.sol';

import {IPoolConfigurator} from './IPoolConfigurator.sol';
import {IPool} from './pool/IPool.sol';
import {IBeacon} from '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';

interface IPoolFactory is IBeacon {
  event PoolCreated(IPool indexed pool, uint256 indexed index, address indexed creator, DataTypes.InitPoolParams params);
  event ImplementationUpdated(address indexed old, address indexed updated, address owner);
  event TreasuryUpdated(address indexed old, address indexed updated, address owner);
  event ReserveFactorUpdated(uint256 indexed old, uint256 indexed updated, address owner);
  event ConfiguratorUpdated(address indexed old, address indexed updated, address owner);
  event FlashLoanPremiumToProtocolUpdated(uint256 indexed old, uint256 indexed updated, address owner);
  event LiquidationProtocolFeePercentageUpdated(uint256 old, uint256 indexed updated, address owner);

  function configurator() external view returns (IPoolConfigurator);

  function createPool(DataTypes.InitPoolParams memory params) external returns (IPool pool);

  function setConfigurator(address impl) external;

  function flashLoanPremiumToProtocol() external view returns (uint256);

  function liquidationProtocolFeePercentage() external view returns (uint256);

  function pools(uint256 index) external view returns (IPool);

  function isPool(address pool) external view returns (bool);

  function poolsLength() external view returns (uint256);

  function reserveFactor() external view returns (uint256);

  function setFlashloanPremium(uint256 updated) external;

  function setImplementation(address updated) external;

  function setLiquidationProtcolFeePercentage(uint256 updated) external;

  function setReserveFactor(uint256 updated) external;

  function setTreasury(address updated) external;

  function treasury() external view returns (address);
}
