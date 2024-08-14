// SPDX-License-Identifier: GPL-2.0-or-later
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

import {IPool} from '../../interfaces/pool/IPool.sol';
import {MarketConfig, PendingUint192} from '../../interfaces/vaults/ICuratedVaultBase.sol';
import {ICuratedVaultBase, ICuratedVaultStaticTyping} from '../../interfaces/vaults/ICuratedVaultStaticTyping.sol';

abstract contract CuratedVaultStorage is ICuratedVaultStaticTyping {
  /// @dev the keccak256 hash of the guardian role.
  bytes32 public immutable GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');

  /// @dev the keccak256 hash of the curator role.
  bytes32 public immutable CURATOR_ROLE = keccak256('CURATOR_ROLE');

  /// @dev the keccak256 hash of the allocator role.
  bytes32 public immutable ALLOCATOR_ROLE = keccak256('ALLOCATOR_ROLE');

  /// @notice OpenZeppelin decimals offset used by the ERC4626Upgradeable implementation.
  /// @dev Calculated to be max(0, 18 - underlyingDecimals) at construction, so the initial conversion rate maximizes
  /// precision between shares and assets.
  uint8 public DECIMALS_OFFSET;

  mapping(IPool => MarketConfig) public config;

  /// @inheritdoc ICuratedVaultBase
  uint256 public timelock;

  mapping(IPool => PendingUint192) public pendingCap;

  PendingUint192 public pendingTimelock;

  /// @inheritdoc ICuratedVaultBase
  uint96 public fee;

  /// @inheritdoc ICuratedVaultBase
  address public feeRecipient;

  /// @inheritdoc ICuratedVaultBase
  address public skimRecipient;

  /// @inheritdoc ICuratedVaultBase
  IPool[] public supplyQueue;

  /// @inheritdoc ICuratedVaultBase
  IPool[] public withdrawQueue;

  /// @inheritdoc ICuratedVaultBase
  uint256 public lastTotalAssets;

  /// @inheritdoc ICuratedVaultBase
  bytes32 public positionId;

  /// @dev The maximum delay of a timelock.
  uint256 internal immutable MAX_TIMELOCK = 2 weeks;

  /// @dev The minimum delay of a timelock.
  uint256 internal immutable MIN_TIMELOCK = 1 days;

  /// @dev The maximum number of markets in the supply/withdraw queue.
  uint256 internal immutable MAX_QUEUE_LENGTH = 30;

  /// @dev The maximum fee the vault can have (50%).
  uint256 internal immutable MAX_FEE = 0.5e18;
}
