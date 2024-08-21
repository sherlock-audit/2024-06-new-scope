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

import {INFTPositionManager} from '../../interfaces/INFTPositionManager.sol';
import {NFTPositionManagerStorage} from './NFTPositionManagerStorage.sol';
import {MulticallUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol';

abstract contract NFTPositionManagerGetters is MulticallUpgradeable, NFTPositionManagerStorage {
  /// @inheritdoc INFTPositionManager
  function positions(uint256 tokenId) external view returns (Position memory) {
    return _positions[tokenId];
  }
}
