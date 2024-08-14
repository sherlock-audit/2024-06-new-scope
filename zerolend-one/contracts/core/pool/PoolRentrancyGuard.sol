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

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @title PoolRentrancyGuard
 * @author ZeroLend
 * @notice This is specialized rentrancy contract that checks the rentrancy state for lending, flashloans and
 * liquidations seperately.
 */
abstract contract PoolRentrancyGuard is Initializable {
  enum RentrancyKind {
    LENDING,
    FLASHLOAN,
    LIQUIDATION
  }

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  /// @notice _status keeps tracks of the various rentrancy statuses
  mapping(RentrancyKind kind => uint256 status) private _status;

  function __PoolRentrancyGuard_init() internal onlyInitializing {
    _status[RentrancyKind.LENDING] = _NOT_ENTERED;
    _status[RentrancyKind.FLASHLOAN] = _NOT_ENTERED;
    _status[RentrancyKind.LIQUIDATION] = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant(RentrancyKind kind) {
    _nonReentrantBefore(kind);
    _;
    _nonReentrantAfter(kind);
  }

  function _nonReentrantBefore(RentrancyKind kind) private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    require(_status[kind] != _ENTERED, 'PoolRentrancyGuard: reentrant call');

    // Any calls to nonReentrant after this point will fail
    _status[kind] = _ENTERED;
  }

  function _nonReentrantAfter(RentrancyKind kind) private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status[kind] = _NOT_ENTERED;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}
