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

struct MarketAllocation {
  /// @notice The market to allocate.
  IPool market;
  /// @notice The amount of assets to allocate.
  uint256 assets;
}

struct MarketConfig {
  /// @notice The maximum amount of assets that can be allocated to the market.
  uint184 cap;
  /// @notice Whether the market is in the withdraw queue.
  bool enabled;
  /// @notice The timestamp at which the market can be instantly removed from the withdraw queue.
  uint64 removableAt;
}

struct PendingUint192 {
  /// @notice The pending value to set.
  uint192 value;
  /// @notice The timestamp at which the pending value becomes valid.
  uint64 validAt;
}

struct PendingAddress {
  /// @notice The pending value to set.
  address value;
  /// @notice The timestamp at which the pending value becomes valid.
  uint64 validAt;
}

/// @dev This interface is used for factorizing ICuratedVaultStaticTyping and ICuratedVault.
/// @dev Consider using the ICuratedVault interface instead of this one.
interface ICuratedVaultBase {
  /// @notice Emitted when a new vault is created.
  /// @param vault The address of the vault.
  /// @param caller The caller of the function.
  /// @param initialOwner The initial owner of the vault.
  /// @param initialTimelock The initial timelock of the vault.
  /// @param asset The address of the underlying asset.
  /// @param name The name of the vault.
  /// @param symbol The symbol of the vault.
  /// @param salt The salt used for the vault's CREATE2 address.
  event CreateVault(
    address indexed vault,
    address indexed caller,
    address initialOwner,
    uint256 initialTimelock,
    address indexed asset,
    string name,
    string symbol,
    bytes32 salt
  );

  function DECIMALS_OFFSET() external view returns (uint8);

  /// @notice Stores whether an address is an allocator or not.
  function isAllocator(address target) external view returns (bool);

  /// @notice The current fee.
  function fee() external view returns (uint96);

  /// @notice The fee recipient.
  function feeRecipient() external view returns (address);

  /// @notice The skim recipient.
  function skimRecipient() external view returns (address);

  /// @notice The current timelock.
  function timelock() external view returns (uint256);

  /// @notice The current position id used in various pools.
  function positionId() external view returns (bytes32);

  /// @dev Stores the order of markets on which liquidity is supplied upon deposit.
  /// @dev Can contain any market. A market is skipped as soon as its supply cap is reached.
  function supplyQueue(uint256) external view returns (IPool);

  /// @notice Returns the length of the supply queue.
  function supplyQueueLength() external view returns (uint256);

  /// @dev Stores the order of markets from which liquidity is withdrawn upon withdrawal.
  /// @dev Always contain all non-zero cap markets as well as all markets on which the vault supplies liquidity,
  /// without duplicate.
  function withdrawQueue(uint256) external view returns (IPool);

  /// @notice Returns the length of the withdraw queue.
  function withdrawQueueLength() external view returns (uint256);

  /// @notice Stores the total assets managed by this vault when the fee was last accrued.
  /// @dev May be greater than `totalAssets()` due to removal of markets with non-zero supply or socialized bad debt.
  /// This difference will decrease the fee accrued until one of the functions updating `lastTotalAssets` is
  /// triggered (deposit/mint/withdraw/redeem/setFee/setFeeRecipient).
  function lastTotalAssets() external view returns (uint256);

  /// @notice Submits a `newTimelock`.
  /// @dev Warning: Reverts if a timelock is already pending. Revoke the pending timelock to overwrite it.
  /// @dev In case the new timelock is higher than the current one, the timelock is set immediately.
  function submitTimelock(uint256 newTimelock) external;

  /// @notice Accepts the pending timelock.
  function acceptTimelock() external;

  /// @notice Revokes the pending timelock.
  /// @dev Does not revert if there is no pending timelock.
  function revokePendingTimelock() external;

  /// @notice Submits a `newSupplyCap` for the market defined by `marketParams`.
  /// @dev Warning: Reverts if a cap is already pending. Revoke the pending cap to overwrite it.
  /// @dev Warning: Reverts if a market removal is pending.
  /// @dev In case the new cap is lower than the current one, the cap is set immediately.
  function submitCap(IPool pool, uint256 newSupplyCap) external;

  /// @notice Accepts the pending cap of the market defined by `marketParams`.
  function acceptCap(IPool pool) external;

  /// @notice Revokes the pending cap of the market defined by `id`.
  /// @dev Does not revert if there is no pending cap.
  function revokePendingCap(IPool id) external;

  /// @notice Submits a forced market removal from the vault, eventually losing all funds supplied to the market.
  /// @notice Funds can be recovered by enabling this market again and withdrawing from it (using `reallocate`),
  /// but funds will be distributed pro-rata to the shares at the time of withdrawal, not at the time of removal.
  /// @notice This forced removal is expected to be used as an emergency process in case a market constantly reverts.
  /// To softly remove a sane market, the curator role is expected to bundle a reallocation that empties the market
  /// first (using `reallocate`), followed by the removal of the market (using `updateWithdrawQueue`).
  /// @dev Warning: Removing a market with non-zero supply will instantly impact the vault's price per share.
  /// @dev Warning: Reverts for non-zero cap or if there is a pending cap. Successfully submitting a zero cap will
  /// prevent such reverts.
  function submitMarketRemoval(IPool pool) external;

  /// @notice Revokes the pending removal of the market defined by `id`.
  /// @dev Does not revert if there is no pending market removal.
  function revokePendingMarketRemoval(IPool id) external;

  /// @notice Skims the vault `token` balance to `skimRecipient`.
  function skim(address) external;

  /// @notice Sets the `fee` to `newFee`.
  function setFee(uint256 newFee) external;

  /// @notice Sets `feeRecipient` to `newFeeRecipient`.
  function setFeeRecipient(address newFeeRecipient) external;

  /// @notice Sets `skimRecipient` to `newSkimRecipient`.
  function setSkimRecipient(address newSkimRecipient) external;

  /// @notice Sets `supplyQueue` to `newSupplyQueue`.
  /// @param newSupplyQueue is an array of enabled markets, and can contain duplicate markets, but it would only
  /// increase the cost of depositing to the vault.
  function setSupplyQueue(IPool[] calldata newSupplyQueue) external;

  /// @notice Updates the withdraw queue. Some markets can be removed, but no market can be added.
  /// @notice Removing a market requires the vault to have 0 supply on it, or to have previously submitted a removal
  /// for this market (with the function `submitMarketRemoval`).
  /// @notice Warning: Anyone can supply on behalf of the vault so the call to `updateWithdrawQueue` that expects a
  /// market to be empty can be griefed by a front-run. To circumvent this, the allocator can simply bundle a
  /// reallocation that withdraws max from this market with a call to `updateWithdrawQueue`.
  /// @dev Warning: Removing a market with supply will decrease the fee accrued until one of the functions updating
  /// `lastTotalAssets` is triggered (deposit/mint/withdraw/redeem/setFee/setFeeRecipient).
  /// @dev Warning: `updateWithdrawQueue` is not idempotent. Submitting twice the same tx will change the queue twice.
  /// @param indexes The indexes of each market in the previous withdraw queue, in the new withdraw queue's order.
  function updateWithdrawQueue(uint256[] calldata indexes) external;

  /// @notice Reallocates the vault's liquidity so as to reach a given allocation of assets on each given market.
  /// @notice The allocator can withdraw from any market, even if it's not in the withdraw queue, as long as the loan
  /// token of the market is the same as the vault's asset.
  /// @dev The behavior of the reallocation can be altered by state changes, including:
  /// - Deposits on the vault that supplies to markets that are expected to be supplied to during reallocation.
  /// - Withdrawals from the vault that withdraws from markets that are expected to be withdrawn from during
  /// reallocation.
  /// - Donations to the vault on markets that are expected to be supplied to during reallocation.
  /// - Withdrawals from markets that are expected to be withdrawn from during reallocation.
  /// @dev Sender is expected to pass `assets = type(uint256).max` with the last MarketAllocation of `allocations` to
  /// supply all the remaining withdrawn liquidity, which would ensure that `totalWithdrawn` = `totalSupplied`.
  function reallocate(MarketAllocation[] calldata allocations) external;

  /// @notice Deposits assets into the vault with slippage protection
  /// @param assets The amount of assets to deposit
  /// @param receiver The address that will receive the minted shares
  /// @param minSharesOut The minimum number of shares that must be received for the transaction to succeed
  /// @param deadline The timestamp after which the transaction will revert
  /// @return sharesOut The actual number of shares minted
  function depositWithSlippage(
    uint256 assets,
    address receiver,
    uint256 minSharesOut,
    uint256 deadline
  ) external returns (uint256 sharesOut);

  /// @notice Mints shares from the vault with slippage protection
  /// @param shares The number of shares to mint
  /// @param receiver The address that will receive the minted shares
  /// @param maxAssetsIn The maximum amount of assets that can be taken for the transaction to succeed
  /// @param deadline The timestamp after which the transaction will revert
  /// @return assetsIn The actual amount of assets deposited
  function mintWithSlippage(uint256 shares, address receiver, uint256 maxAssetsIn, uint256 deadline) external returns (uint256 assetsIn);

  /// @notice Withdraws assets from the vault with slippage protection
  /// @param assets The amount of assets to withdraw
  /// @param receiver The address that will receive the withdrawn assets
  /// @param owner The address that owns the shares to be burned
  /// @param maxSharesBurned The maximum number of shares that can be burned for the transaction to succeed
  /// @param deadline The timestamp after which the transaction will revert
  /// @return sharesBurned The actual number of shares burned
  function withdrawWithSlippage(
    uint256 assets,
    address receiver,
    address owner,
    uint256 maxSharesBurned,
    uint256 deadline
  ) external returns (uint256 sharesBurned);

  /// @notice Redeems shares from the vault with slippage protection
  /// @param shares The number of shares to redeem
  /// @param receiver The address that will receive the redeemed assets
  /// @param owner The address that owns the shares to be redeemed
  /// @param minAssetsOut The minimum amount of assets that must be received for the transaction to succeed
  /// @param deadline The timestamp after which the transaction will revert
  /// @return assetsOut The actual amount of assets withdrawn
  function redeemWithSlippage(
    uint256 shares,
    address receiver,
    address owner,
    uint256 minAssetsOut,
    uint256 deadline
  ) external returns (uint256 assetsOut);
}
