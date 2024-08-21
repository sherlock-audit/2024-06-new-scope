import { Libraries } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const getPoolLibraries = async (hre: HardhatRuntimeEnvironment): Promise<Libraries> => {
  const supplyLibraryArtifact = await hre.deployments.get('SupplyLogic');
  const borrowLibraryArtifact = await hre.deployments.get('BorrowLogic');
  const liquidationLibraryArtifact = await hre.deployments.get('LiquidationLogic');
  const flashLoanLogicArtifact = await hre.deployments.get('FlashLoanLogic');
  const poolLogicArtifact = await hre.deployments.get('PoolLogic');

  return {
    LiquidationLogic: liquidationLibraryArtifact.address,
    SupplyLogic: supplyLibraryArtifact.address,
    FlashLoanLogic: flashLoanLogicArtifact.address,
    BorrowLogic: borrowLibraryArtifact.address,
    PoolLogic: poolLogicArtifact.address,
  };
};
