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

import {DataTypes, IPool} from '../../interfaces/pool/IPool.sol';

import {ICuratedVaultBase, MarketAllocation, PendingUint192} from '../../interfaces/vaults/ICuratedVaultBase.sol';

import {PendingLib} from './libraries/PendingLib.sol';
import {SharesMathLib} from './libraries/SharesMathLib.sol';
import {UtilsLib} from './libraries/UtilsLib.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {CuratedErrorsLib} from '../../interfaces/errors/CuratedErrorsLib.sol';
import {CuratedEventsLib} from '../../interfaces/events/CuratedEventsLib.sol';
import {CuratedVaultSetters} from './CuratedVaultSetters.sol';
import {
  ERC20Upgradeable,
  ERC4626Upgradeable,
  IERC4626Upgradeable,
  MathUpgradeable
} from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol';
import {IERC20, IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

/// @title CuratedVault
/// @author ZeroLend
/// @custom:contact contact@zerolend.xyz
/// @notice ERC4626 compliant vault allowing users to deposit assets to ZeroLend One.
/// @dev This is a proxy contract and is not meant to be deployed directly.
contract CuratedVault is CuratedVaultSetters {
  using UtilsLib for uint256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using SharesMathLib for uint256;
  using PendingLib for PendingUint192;

  constructor() {
    _disableInitializers();
  }

  /// @dev Initializes the contract.
  /// @param _admins The admins of the contract.
  /// @param _initialTimelock The initial timelock.
  /// @param _asset The address of the underlying asset.
  /// @param _name The name of the vault.
  /// @param _symbol The symbol of the vault.
  function initialize(
    address[] memory _admins,
    address[] memory _curators,
    address[] memory _guardians,
    address[] memory _allocators,
    uint256 _initialTimelock,
    address _asset,
    string memory _name,
    string memory _symbol
  ) external initializer {
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init(_name);
    __ERC4626_init(IERC20Upgradeable(_asset));
    __Multicall_init();
    __CuratedVaultRoles_init(_admins, _curators, _guardians, _allocators);

    DECIMALS_OFFSET = uint8(uint256(18).zeroFloorSub(IERC20Metadata(_asset).decimals()));
    _checkTimelockBounds(_initialTimelock);
    _setTimelock(_initialTimelock);

    positionId = keccak256(abi.encodePacked(address(this), 'index', uint256(0)));
  }

  /// @dev Makes sure conditions are met to accept a pending value.
  /// @dev Reverts if:
  /// - there's no pending value;
  /// - the timelock has not elapsed since the pending value has been submitted.
  modifier afterTimelock(uint256 validAt) {
    if (validAt == 0) revert CuratedErrorsLib.NoPendingValue();
    if (block.timestamp < validAt) revert CuratedErrorsLib.TimelockNotElapsed();
    _;
  }

  /* ONLY OWNER FUNCTIONS */

  /// @inheritdoc ICuratedVaultBase
  function setSkimRecipient(address newSkimRecipient) external onlyOwner {
    if (newSkimRecipient == skimRecipient) revert CuratedErrorsLib.AlreadySet();
    skimRecipient = newSkimRecipient;
    emit CuratedEventsLib.SetSkimRecipient(newSkimRecipient);
  }

  /// @inheritdoc ICuratedVaultBase
  function submitTimelock(uint256 newTimelock) external onlyOwner {
    if (newTimelock == timelock) revert CuratedErrorsLib.AlreadySet();
    if (pendingTimelock.validAt != 0) revert CuratedErrorsLib.AlreadyPending();
    _checkTimelockBounds(newTimelock);

    if (newTimelock > timelock) {
      _setTimelock(newTimelock);
    } else {
      // Safe "unchecked" cast because newTimelock <= MAX_TIMELOCK.
      pendingTimelock.update(uint184(newTimelock), timelock);
      emit CuratedEventsLib.SubmitTimelock(newTimelock);
    }
  }

  /// @inheritdoc ICuratedVaultBase
  function setFee(uint256 newFee) external onlyOwner {
    if (newFee == fee) revert CuratedErrorsLib.AlreadySet();
    if (newFee > MAX_FEE) revert CuratedErrorsLib.MaxFeeExceeded();
    if (newFee != 0 && feeRecipient == address(0)) revert CuratedErrorsLib.ZeroFeeRecipient();

    // Accrue fee using the previous fee set before changing it.
    _updateLastTotalAssets(_accrueFee());

    // Safe "unchecked" cast because newFee <= MAX_FEE.
    fee = uint96(newFee);

    emit CuratedEventsLib.SetFee(_msgSender(), fee);
  }

  /// @inheritdoc ICuratedVaultBase
  function setFeeRecipient(address newFeeRecipient) external onlyOwner {
    if (newFeeRecipient == feeRecipient) revert CuratedErrorsLib.AlreadySet();
    if (newFeeRecipient == address(0) && fee != 0) revert CuratedErrorsLib.ZeroFeeRecipient();

    // Accrue fee to the previous fee recipient set before changing it.
    _updateLastTotalAssets(_accrueFee());

    feeRecipient = newFeeRecipient;

    emit CuratedEventsLib.SetFeeRecipient(newFeeRecipient);
  }

  /* ONLY curator FUNCTIONS */

  /// @inheritdoc ICuratedVaultBase
  function submitCap(IPool pool, uint256 newSupplyCap) external onlyCuratorRole {
    if (pendingCap[pool].validAt != 0) revert CuratedErrorsLib.AlreadyPending();
    if (config[pool].removableAt != 0) revert CuratedErrorsLib.PendingRemoval();
    uint256 supplyCap = config[pool].cap;
    if (newSupplyCap == supplyCap) revert CuratedErrorsLib.AlreadySet();

    if (newSupplyCap < supplyCap) {
      _setCap(pool, newSupplyCap.toUint184());
    } else {
      pendingCap[pool].update(newSupplyCap.toUint184(), timelock);
      emit CuratedEventsLib.SubmitCap(_msgSender(), pool, newSupplyCap);
    }
  }

  /// @inheritdoc ICuratedVaultBase
  function submitMarketRemoval(IPool pool) external onlyCuratorRole {
    if (config[pool].removableAt != 0) revert CuratedErrorsLib.AlreadyPending();
    if (config[pool].cap != 0) revert CuratedErrorsLib.NonZeroCap();
    if (!config[pool].enabled) revert CuratedErrorsLib.MarketNotEnabled(pool);
    if (pendingCap[pool].validAt != 0) revert CuratedErrorsLib.PendingCap(pool);

    // Safe "unchecked" cast because timelock <= MAX_TIMELOCK.
    config[pool].removableAt = uint64(block.timestamp + timelock);
    emit CuratedEventsLib.SubmitMarketRemoval(_msgSender(), pool);
  }

  /* ONLY allocator FUNCTIONS */

  /// @inheritdoc ICuratedVaultBase
  function setSupplyQueue(IPool[] calldata newSupplyQueue) external onlyAllocator {
    uint256 length = newSupplyQueue.length;

    if (length > MAX_QUEUE_LENGTH) revert CuratedErrorsLib.MaxQueueLengthExceeded();

    for (uint256 i; i < length; ++i) {
      IERC20(asset()).forceApprove(address(newSupplyQueue[i]), type(uint256).max);
      if (config[newSupplyQueue[i]].cap == 0) revert CuratedErrorsLib.UnauthorizedMarket(newSupplyQueue[i]);
    }

    supplyQueue = newSupplyQueue;
    emit CuratedEventsLib.SetSupplyQueue(_msgSender(), newSupplyQueue);
  }

  /// @inheritdoc ICuratedVaultBase
  function updateWithdrawQueue(uint256[] calldata indexes) external onlyAllocator {
    uint256 newLength = indexes.length;
    uint256 currLength = withdrawQueue.length;

    bool[] memory seen = new bool[](currLength);
    IPool[] memory newWithdrawQueue = new IPool[](newLength);

    for (uint256 i; i < newLength; ++i) {
      uint256 prevIndex = indexes[i];

      // If prevIndex >= currLength, it will revert CuratedErrorsLib.with native "Index out of bounds".
      IPool pool = withdrawQueue[prevIndex];
      if (seen[prevIndex]) revert CuratedErrorsLib.DuplicateMarket(pool);
      seen[prevIndex] = true;

      newWithdrawQueue[i] = pool;
    }

    for (uint256 i; i < currLength; ++i) {
      if (!seen[i]) {
        IPool pool = withdrawQueue[i];

        if (config[pool].cap != 0) revert CuratedErrorsLib.InvalidMarketRemovalNonZeroCap(pool);
        if (pendingCap[pool].validAt != 0) revert CuratedErrorsLib.PendingCap(pool);
        if (pool.supplyShares(asset(), positionId) != 0) {
          if (config[pool].removableAt == 0) revert CuratedErrorsLib.InvalidMarketRemovalNonZeroSupply(pool);
          if (block.timestamp < config[pool].removableAt) {
            revert CuratedErrorsLib.InvalidMarketRemovalTimelockNotElapsed(pool);
          }
        }

        delete config[pool];
      }
    }

    withdrawQueue = newWithdrawQueue;
    emit CuratedEventsLib.SetWithdrawQueue(_msgSender(), newWithdrawQueue);
  }

  /// @inheritdoc ICuratedVaultBase
  function reallocate(MarketAllocation[] calldata allocations) external onlyAllocator {
    uint256 totalSupplied;
    uint256 totalWithdrawn;

    for (uint256 i; i < allocations.length; ++i) {
      MarketAllocation memory allocation = allocations[i];
      IPool pool = allocation.market;

      (uint256 supplyAssets, uint256 supplyShares) = _accruedSupplyBalance(pool);
      uint256 toWithdraw = supplyAssets.zeroFloorSub(allocation.assets);

      if (toWithdraw > 0) {
        if (!config[pool].enabled) revert CuratedErrorsLib.MarketNotEnabled(pool);

        // Guarantees that unknown frontrunning donations can be withdrawn, in order to disable a market.
        uint256 shares;
        if (allocation.assets == 0) {
          shares = supplyShares;
          toWithdraw = 0;
        }

        DataTypes.SharesType memory burnt = pool.withdrawSimple(asset(), address(this), toWithdraw, 0);
        emit CuratedEventsLib.ReallocateWithdraw(_msgSender(), pool, burnt.assets, burnt.shares);
        totalWithdrawn += burnt.assets;
      } else {
        uint256 suppliedAssets =
          allocation.assets == type(uint256).max ? totalWithdrawn.zeroFloorSub(totalSupplied) : allocation.assets.zeroFloorSub(supplyAssets);

        if (suppliedAssets == 0) continue;

        uint256 supplyCap = config[pool].cap;
        if (supplyCap == 0) revert CuratedErrorsLib.UnauthorizedMarket(pool);

        if (supplyAssets + suppliedAssets > supplyCap) revert CuratedErrorsLib.SupplyCapExceeded(pool);

        // The market's loan asset is guaranteed to be the vault's asset because it has a non-zero supply cap.
        IERC20(asset()).forceApprove(address(pool), type(uint256).max);
        DataTypes.SharesType memory minted = pool.supplySimple(asset(), address(this), suppliedAssets, 0);
        emit CuratedEventsLib.ReallocateSupply(_msgSender(), pool, minted.assets, minted.shares);
        totalSupplied += suppliedAssets;
      }
    }

    if (totalWithdrawn != totalSupplied) revert CuratedErrorsLib.InconsistentReallocation();
  }

  /* REVOKE FUNCTIONS */

  /// @inheritdoc ICuratedVaultBase
  function revokePendingTimelock() external onlyGuardian {
    delete pendingTimelock;
    emit CuratedEventsLib.RevokePendingTimelock(_msgSender());
  }

  /// @inheritdoc ICuratedVaultBase
  function revokePendingCap(IPool pool) external onlyCuratorOrGuardian {
    delete pendingCap[pool];
    emit CuratedEventsLib.RevokePendingCap(_msgSender(), pool);
  }

  /// @inheritdoc ICuratedVaultBase
  function revokePendingMarketRemoval(IPool pool) external onlyCuratorOrGuardian {
    delete config[pool].removableAt;
    emit CuratedEventsLib.RevokePendingMarketRemoval(_msgSender(), pool);
  }

  /* EXTERNAL */

  /// @inheritdoc ICuratedVaultBase
  function acceptTimelock() external afterTimelock(pendingTimelock.validAt) {
    _setTimelock(pendingTimelock.value);
  }

  /// @inheritdoc ICuratedVaultBase
  function acceptCap(IPool pool) external afterTimelock(pendingCap[pool].validAt) {
    // Safe "unchecked" cast because pendingCap <= type(uint184).max.
    _setCap(pool, uint184(pendingCap[pool].value));
  }

  /// @inheritdoc ICuratedVaultBase
  function skim(address token) external {
    if (skimRecipient == address(0)) revert CuratedErrorsLib.ZeroAddress();
    uint256 amount = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransfer(skimRecipient, amount);
    emit CuratedEventsLib.Skim(_msgSender(), token, amount);
  }

  /* ERC4626Upgradeable (PUBLIC) */

  /// @inheritdoc IERC4626Upgradeable
  function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
    uint256 newTotalAssets = _accrueFee();

    // Update `lastTotalAssets` to avoid an inconsistent state in a re-entrant context.
    // It is updated again in `_deposit`.
    lastTotalAssets = newTotalAssets;
    shares = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Down);
    _deposit(_msgSender(), receiver, assets, shares);
  }

  /// @inheritdoc IERC4626Upgradeable
  function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
    uint256 newTotalAssets = _accrueFee();

    // Update `lastTotalAssets` to avoid an inconsistent state in a re-entrant context.
    // It is updated again in `_deposit`.
    lastTotalAssets = newTotalAssets;
    assets = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Up);
    _deposit(_msgSender(), receiver, assets, shares);
  }

  /// @inheritdoc IERC4626Upgradeable
  function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
    uint256 newTotalAssets = _accrueFee();

    // Do not call expensive `maxWithdraw` and optimistically withdraw assets.
    shares = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Up);

    // `newTotalAssets - assets` may be a little off from `totalAssets()`.
    _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assets));
    _withdraw(_msgSender(), receiver, owner, assets, shares);
  }

  /// @inheritdoc IERC4626Upgradeable
  function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
    uint256 newTotalAssets = _accrueFee();

    // Do not call expensive `maxRedeem` and optimistically redeem shares.
    assets = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Down);

    // `newTotalAssets - assets` may be a little off from `totalAssets()`.
    _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assets));
    _withdraw(_msgSender(), receiver, owner, assets, shares);
  }

  /// @inheritdoc IERC4626Upgradeable
  function totalAssets() public view override returns (uint256 assets) {
    for (uint256 i; i < withdrawQueue.length; ++i) {
      assets += withdrawQueue[i].getBalanceByPosition(asset(), positionId);
    }
  }

  /// @inheritdoc ICuratedVaultBase
  function depositWithSlippage(uint256 assets, address receiver, uint256 minSharesOut, uint256 deadline) public returns (uint256 sharesOut) {
    require(block.timestamp <= deadline, 'CuratedVault: Deposit expired');

    uint256 newTotalAssets = _accrueFee();
    lastTotalAssets = newTotalAssets;

    sharesOut = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Down);
    require(sharesOut >= minSharesOut, 'CuratedVault: Slippage too high');

    _deposit(_msgSender(), receiver, assets, sharesOut);
    return sharesOut;
  }

  /// @inheritdoc ICuratedVaultBase
  function mintWithSlippage(uint256 shares, address receiver, uint256 maxAssetsIn, uint256 deadline) public returns (uint256 assetsIn) {
    require(block.timestamp <= deadline, 'CuratedVault: Mint expired');

    uint256 newTotalAssets = _accrueFee();
    lastTotalAssets = newTotalAssets;

    assetsIn = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Up);
    require(assetsIn <= maxAssetsIn, 'CuratedVault: Slippage too high');

    _deposit(_msgSender(), receiver, assetsIn, shares);
    return assetsIn;
  }

  /// @inheritdoc ICuratedVaultBase
  function withdrawWithSlippage(
    uint256 assets,
    address receiver,
    address owner,
    uint256 maxSharesBurned,
    uint256 deadline
  ) public returns (uint256 sharesBurned) {
    require(block.timestamp <= deadline, 'CuratedVault: Withdraw expired');

    uint256 newTotalAssets = _accrueFee();
    sharesBurned = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Up);
    require(sharesBurned <= maxSharesBurned, 'CuratedVault: Slippage too high');

    _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assets));
    _withdraw(_msgSender(), receiver, owner, assets, sharesBurned);
    return sharesBurned;
  }

  /// @inheritdoc ICuratedVaultBase
  function redeemWithSlippage(
    uint256 shares,
    address receiver,
    address owner,
    uint256 minAssetsOut,
    uint256 deadline
  ) public returns (uint256 assetsOut) {
    require(block.timestamp <= deadline, 'CuratedVault: Redeem expired');

    uint256 newTotalAssets = _accrueFee();
    assetsOut = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, MathUpgradeable.Rounding.Down);
    require(assetsOut >= minAssetsOut, 'CuratedVault: Slippage too high');

    _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assetsOut));
    _withdraw(_msgSender(), receiver, owner, assetsOut, shares);
    return assetsOut;
  }
}
