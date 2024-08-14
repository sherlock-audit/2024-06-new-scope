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

import {IPool} from '../pool/IPool.sol';

import {ICuratedVaultBase, MarketConfig, PendingAddress, PendingUint192} from './ICuratedVaultBase.sol';
import {ICuratedVaultStaticTyping} from './ICuratedVaultStaticTyping.sol';
import {IERC4626} from '@openzeppelin/contracts/interfaces/IERC4626.sol';
import {IERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';

/// @title ICuratedVault
/// @author ZeroLend
/// @custom:contact contact@zerolend.xyz
/// @dev Use this interface for a vault to have access to all the functions with the appropriate function signatures.
interface ICuratedVault is ICuratedVaultStaticTyping, IERC4626, IERC20Permit {
  /// @notice Returns the current configuration of each market.
  function config(IPool) external view returns (MarketConfig memory);

  /// @notice Returns the pending cap for each market.
  function pendingCap(IPool) external view returns (PendingUint192 memory);

  /// @notice Returns the pending timelock.
  function pendingTimelock() external view returns (PendingUint192 memory);
}
