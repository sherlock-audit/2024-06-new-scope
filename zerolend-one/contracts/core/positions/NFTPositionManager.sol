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
import {IPoolFactory} from '../../interfaces/IPoolFactory.sol';

import {IWETH} from '../../interfaces/IWETH.sol';
import {NFTErrorsLib, NFTPositionManagerSetters} from './NFTPositionManagerSetters.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

/**
 * @title NFTPositionManager
 * @author ZeroLend
 * @dev Manages the minting and burning of NFT positions, which represent liquidity positions in a pool.
 */
contract NFTPositionManager is NFTPositionManagerSetters {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc INFTPositionManager
  function initialize(address _factory, address _staking, address _owner, address _zero, address _weth) external initializer {
    __ERC721Enumerable_init();
    __ERC721_init('ZeroLend One Position', 'ZL-POS-ONE');
    __AccessControlEnumerable_init();
    __NFTRewardsDistributor_init(50_000_000, _staking, 14 days, _zero);
    __ReentrancyGuard_init();
    __Multicall_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);

    factory = IPoolFactory(_factory);
    weth = IWETH(_weth);
    _nextId = 1;
  }

  receive() external payable {
    // nothing
  }

  /// @inheritdoc INFTPositionManager
  function mint(address pool) external returns (uint256 tokenId) {
    require(factory.isPool(pool), 'not a pool');
    tokenId = _nextId;
    _nextId++;
    _positions[tokenId].pool = pool;
    _mint(msg.sender, tokenId);
  }

  /// @inheritdoc INFTPositionManager
  function supply(AssetOperationParams memory params) external {
    if (params.asset == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    IERC20Upgradeable(params.asset).safeTransferFrom(msg.sender, address(this), params.amount);
    _supply(params);
  }

  /// @inheritdoc INFTPositionManager
  function supplyETH(AssetOperationParams memory params) external payable {
    params.asset = address(weth);
    if (msg.value != params.amount) revert NFTErrorsLib.UnequalAmountNotAllowed();
    weth.deposit{value: params.amount}();
    _supply(params);
  }

  /// @inheritdoc INFTPositionManager
  function borrow(AssetOperationParams memory params) external {
    if (params.asset == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    _borrow(params);
  }

  /// @inheritdoc INFTPositionManager
  function borrowETH(AssetOperationParams memory params) external payable {
    params.asset = address(weth);
    address dest = params.target;
    params.target = address(this);
    _borrow(params);
    weth.withdraw(params.amount);
    (bool ok,) = payable(dest).call{value: params.amount}('');
    if (!ok) revert NFTErrorsLib.SendETHFailed(params.amount);
  }

  /// @inheritdoc INFTPositionManager
  function withdraw(AssetOperationParams memory params) external {
    if (params.asset == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    _withdraw(params);
  }

  /// @inheritdoc INFTPositionManager
  function withdrawETH(AssetOperationParams memory params) external payable {
    params.asset = address(weth);
    address dest = params.target;
    params.target = address(this);
    _withdraw(params);
    weth.withdraw(params.amount);
    (bool ok,) = payable(dest).call{value: params.amount}('');
    if (!ok) revert NFTErrorsLib.SendETHFailed(params.amount);
  }

  /// @inheritdoc INFTPositionManager
  function repay(AssetOperationParams memory params) external {
    if (params.asset == address(0)) revert NFTErrorsLib.ZeroAddressNotAllowed();
    IERC20Upgradeable(params.asset).safeTransferFrom(msg.sender, address(this), params.amount);
    _repay(params);
  }

  /// @inheritdoc INFTPositionManager
  function repayETH(AssetOperationParams memory params) external payable {
    params.asset = address(weth);
    if (msg.value != params.amount) revert NFTErrorsLib.UnequalAmountNotAllowed();
    weth.deposit{value: params.amount}();
    _repay(params);
  }

  /// @inheritdoc INFTPositionManager
  function sweep(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (token == address(0)) {
      uint256 bal = address(this).balance;
      payable(msg.sender).transfer(bal);
    } else {
      IERC20Upgradeable erc20 = IERC20Upgradeable(token);
      erc20.safeTransfer(msg.sender, erc20.balanceOf(address(this)));
    }
  }
}
