
# New Scope contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

# Audit scope


[zerolend-one @ 2352764af0f31ca01c789726dbfb3c562d1222c1](https://github.com/zerolend/zerolend-one/tree/2352764af0f31ca01c789726dbfb3c562d1222c1)
- [zerolend-one/contracts/core/flashloan/FlashLoanReceiverBase.sol](zerolend-one/contracts/core/flashloan/FlashLoanReceiverBase.sol)
- [zerolend-one/contracts/core/pool/Pool.sol](zerolend-one/contracts/core/pool/Pool.sol)
- [zerolend-one/contracts/core/pool/PoolFactory.sol](zerolend-one/contracts/core/pool/PoolFactory.sol)
- [zerolend-one/contracts/core/pool/PoolGetters.sol](zerolend-one/contracts/core/pool/PoolGetters.sol)
- [zerolend-one/contracts/core/pool/PoolRentrancyGuard.sol](zerolend-one/contracts/core/pool/PoolRentrancyGuard.sol)
- [zerolend-one/contracts/core/pool/PoolSetters.sol](zerolend-one/contracts/core/pool/PoolSetters.sol)
- [zerolend-one/contracts/core/pool/PoolStorage.sol](zerolend-one/contracts/core/pool/PoolStorage.sol)
- [zerolend-one/contracts/core/pool/configuration/DataTypes.sol](zerolend-one/contracts/core/pool/configuration/DataTypes.sol)
- [zerolend-one/contracts/core/pool/configuration/PositionBalanceConfiguration.sol](zerolend-one/contracts/core/pool/configuration/PositionBalanceConfiguration.sol)
- [zerolend-one/contracts/core/pool/configuration/ReserveConfiguration.sol](zerolend-one/contracts/core/pool/configuration/ReserveConfiguration.sol)
- [zerolend-one/contracts/core/pool/configuration/ReserveSuppliesConfiguration.sol](zerolend-one/contracts/core/pool/configuration/ReserveSuppliesConfiguration.sol)
- [zerolend-one/contracts/core/pool/configuration/TokenConfiguration.sol](zerolend-one/contracts/core/pool/configuration/TokenConfiguration.sol)
- [zerolend-one/contracts/core/pool/configuration/UserConfiguration.sol](zerolend-one/contracts/core/pool/configuration/UserConfiguration.sol)
- [zerolend-one/contracts/core/pool/logic/BorrowLogic.sol](zerolend-one/contracts/core/pool/logic/BorrowLogic.sol)
- [zerolend-one/contracts/core/pool/logic/FlashLoanLogic.sol](zerolend-one/contracts/core/pool/logic/FlashLoanLogic.sol)
- [zerolend-one/contracts/core/pool/logic/GenericLogic.sol](zerolend-one/contracts/core/pool/logic/GenericLogic.sol)
- [zerolend-one/contracts/core/pool/logic/LiquidationLogic.sol](zerolend-one/contracts/core/pool/logic/LiquidationLogic.sol)
- [zerolend-one/contracts/core/pool/logic/PoolLogic.sol](zerolend-one/contracts/core/pool/logic/PoolLogic.sol)
- [zerolend-one/contracts/core/pool/logic/ReserveLogic.sol](zerolend-one/contracts/core/pool/logic/ReserveLogic.sol)
- [zerolend-one/contracts/core/pool/logic/SupplyLogic.sol](zerolend-one/contracts/core/pool/logic/SupplyLogic.sol)
- [zerolend-one/contracts/core/pool/logic/ValidationLogic.sol](zerolend-one/contracts/core/pool/logic/ValidationLogic.sol)
- [zerolend-one/contracts/core/pool/manager/PoolConfigurator.sol](zerolend-one/contracts/core/pool/manager/PoolConfigurator.sol)
- [zerolend-one/contracts/core/pool/manager/PoolManager.sol](zerolend-one/contracts/core/pool/manager/PoolManager.sol)
- [zerolend-one/contracts/core/pool/utils/MathUtils.sol](zerolend-one/contracts/core/pool/utils/MathUtils.sol)
- [zerolend-one/contracts/core/pool/utils/PercentageMath.sol](zerolend-one/contracts/core/pool/utils/PercentageMath.sol)
- [zerolend-one/contracts/core/pool/utils/WadRayMath.sol](zerolend-one/contracts/core/pool/utils/WadRayMath.sol)
- [zerolend-one/contracts/core/positions/NFTPositionManager.sol](zerolend-one/contracts/core/positions/NFTPositionManager.sol)
- [zerolend-one/contracts/core/positions/NFTPositionManagerGetters.sol](zerolend-one/contracts/core/positions/NFTPositionManagerGetters.sol)
- [zerolend-one/contracts/core/positions/NFTPositionManagerSetters.sol](zerolend-one/contracts/core/positions/NFTPositionManagerSetters.sol)
- [zerolend-one/contracts/core/positions/NFTPositionManagerStorage.sol](zerolend-one/contracts/core/positions/NFTPositionManagerStorage.sol)
- [zerolend-one/contracts/core/positions/NFTRewardsDistributor.sol](zerolend-one/contracts/core/positions/NFTRewardsDistributor.sol)
- [zerolend-one/contracts/core/proxy/RevokableBeaconProxy.sol](zerolend-one/contracts/core/proxy/RevokableBeaconProxy.sol)
- [zerolend-one/contracts/core/vaults/CuratedVault.sol](zerolend-one/contracts/core/vaults/CuratedVault.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultBase.sol](zerolend-one/contracts/core/vaults/CuratedVaultBase.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultFactory.sol](zerolend-one/contracts/core/vaults/CuratedVaultFactory.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultGetters.sol](zerolend-one/contracts/core/vaults/CuratedVaultGetters.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultRoles.sol](zerolend-one/contracts/core/vaults/CuratedVaultRoles.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultSetters.sol](zerolend-one/contracts/core/vaults/CuratedVaultSetters.sol)
- [zerolend-one/contracts/core/vaults/CuratedVaultStorage.sol](zerolend-one/contracts/core/vaults/CuratedVaultStorage.sol)
- [zerolend-one/contracts/core/vaults/libraries/ConstantsLib.sol](zerolend-one/contracts/core/vaults/libraries/ConstantsLib.sol)
- [zerolend-one/contracts/core/vaults/libraries/MathLib.sol](zerolend-one/contracts/core/vaults/libraries/MathLib.sol)
- [zerolend-one/contracts/core/vaults/libraries/PendingLib.sol](zerolend-one/contracts/core/vaults/libraries/PendingLib.sol)
- [zerolend-one/contracts/core/vaults/libraries/SharesMathLib.sol](zerolend-one/contracts/core/vaults/libraries/SharesMathLib.sol)
- [zerolend-one/contracts/core/vaults/libraries/UtilsLib.sol](zerolend-one/contracts/core/vaults/libraries/UtilsLib.sol)


