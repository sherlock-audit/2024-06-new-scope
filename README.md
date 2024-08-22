
# New Scope contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum and Linea primarily. And after that any EVM-compatible network.
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of [weird tokens](https://github.com/d-xo/weird-erc20) you want to integrate?
Any token that follows the ERC20 token standard. Even non-compliant ones like USDT, BNB etc... are fine.
___

### Q: Are there any limitations on values set by admins (or other roles) in the codebase, including restrictions on array lengths?
No
___

### Q: Are there any limitations on values set by admins (or other roles) in protocols you integrate with, including restrictions on array lengths?
No
___

### Q: For permissioned functions, please list all checks and requirements that will be made before calling the function.
Essentially we expect all permissioned actors to behave rationally. 

There are two set of actors. Actors who manage pools and actors who mange vaults. If an action done by one party causes the other party to suffer losses we'd want to consider that.
___

### Q: Is the codebase expected to comply with any EIPs? Can there be/are there any deviations from the specification?
The CuratorVault should follow the ERC4626 standard.
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, arbitrage bots, etc.)?
There are liquidation bots that run off-chain to execute liquidations similar to how liquidations work on Aave. 
___

### Q: Are there any hardcoded values that you intend to change before (some) deployments?
None.
___

### Q: If the codebase is to be deployed on an L2, what should be the behavior of the protocol in case of sequencer issues (if applicable)? Should Sherlock assume that the Sequencer won't misbehave, including going offline?
Sequencer issues can be ignored.
___

### Q: Should potential issues, like broken assumptions about function behavior, be reported if they could pose risks in future integrations, even if they might not be an issue in the context of the scope? If yes, can you elaborate on properties/invariants that should hold?
Yes.
___

### Q: Please discuss any design choices you made.
We took the aave codebase since it was well written up and documented and stripped out most of the un-necessary features such as isolation mode, e-mode etc etc... and then added our own features into it.

We also took the metamorpho codebase and ported it to work with the lending codebase.

We also introduced hooks (inspired from Uniswap V3). Hooks could have the potential to introduce bugs and possible rugs into the protocol. We would want to ignore hooks from the scope.
___

### Q: Please list any known issues and explicitly state the acceptable risks for each known issue.
There is a known issue of liquidity mis-allocation between the vault and the individual pool. This can be ignored as we expect risk managers to be aware of changes to supply caps on the pools they provide liquidity for.

See HAL-18 (page 34) on https://github.com/zerolend/audits/blob/main/halborn/Zerolend-One%20Audit.pdf

We also suspect a possible inflation attack with the vaults as described with the openzepplin's doc on ERC4626: https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack if this can be proven then it'll be a valid bug
___

### Q: We will report issues where the core protocol functionality is inaccessible for at least 7 days. Would you like to override this value?
Yes.
___

### Q: Please provide links to previous audits (if any).
https://github.com/zerolend/audits/blob/main/halborn/Zerolend-One%20Audit.pdf We just recently concluded an audit with Halborn. This report is the draft but it's going to be close to the final one.
___

### Q: Please list any relevant protocol resources.
High-level Docs: https://docs-one.zerolend.xyz/
Source code docs: https://github.com/zerolend/zerolend-one/wiki (We try to give as much as documentation on each contract and their respective functions)
Github Doc: https://github.com/zerolend/zerolend-one (The readme has a simple diagram showcasing how the different modules work)
___

### Q: Additional audit information.
We suspect some decimal precision issues between the vault and the pool as the shares/asset accounting used by both contracts are different. The pool uses ray (1e26) for share precision and the vaults use 


___



# Audit scope


[zerolend-one @ 6b681f2a16be20cb2d43e544c164f913a8db1cb8](https://github.com/zerolend/zerolend-one/tree/6b681f2a16be20cb2d43e544c164f913a8db1cb8)
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

