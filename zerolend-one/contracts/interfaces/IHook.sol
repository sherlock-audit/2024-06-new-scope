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

interface IHook {
  function afterInitialize(address pool) external returns (bytes4);

  function beforeSupply(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function afterSupply(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function beforeWithdraw(DataTypes.ExecuteWithdrawParams memory params) external;

  function afterWithdraw(DataTypes.ExecuteWithdrawParams memory params) external;

  function beforeRepay(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function afterRepay(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function beforeBorrow(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function afterBorrow(address sender, bytes32 position, address asset, address pool, uint256 amount, bytes calldata hookData) external;

  function beforeFlashloan(
    address sender,
    address receiver,
    address asset,
    uint256 amount,
    bytes calldata params,
    address pool,
    bytes calldata hookData
  ) external;

  function afterFlashloan(
    address sender,
    address receiver,
    address asset,
    uint256 amount,
    bytes calldata params,
    address pool,
    bytes calldata hookData
  ) external;

  function beforeLiquidate(
    address liquidator,
    bytes32 position,
    address collateralAsset,
    address debtAsset,
    uint256 debtToCover,
    address pool,
    bytes calldata hookData
  ) external;

  function afterLiquidate(
    address liquidator,
    bytes32 position,
    address collateralAsset,
    address debtAsset,
    uint256 debtToCover,
    address pool,
    bytes calldata hookData
  ) external;
}
