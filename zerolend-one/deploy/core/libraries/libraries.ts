import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  ...hre
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const supplyLogic = await deploy('SupplyLogic', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
  });

  const borrowLogic = await deploy('BorrowLogic', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
  });

  const liquidationLogic = await deploy('LiquidationLogic', {
    from: deployer,
    log: true,
    deterministicDeployment: false,
  });

  const flashLoanLogic = await deploy('FlashLoanLogic', {
    from: deployer,
    log: true,
    deterministicDeployment: false,
    libraries: {
      BorrowLogic: borrowLogic.address,
    },
  });

  const poolLogic = await deploy('PoolLogic', {
    from: deployer,
    log: true,
    deterministicDeployment: false,
  });

  // await hre.run('verify:verify', { address: supplyLogic.address });
  // await hre.run('verify:verify', { address: poolLogic.address });
  // await hre.run('verify:verify', {
  //   address: flashLoanLogic.address,
  //   libraries: flashLoanLogic.libraries,
  // });
  // await hre.run('verify:verify', { address: liquidationLogic.address });
  // await hre.run('verify:verify', { address: borrowLogic.address });

  return true;
};

func.tags = ['LogicLibraries', 'core', 'logic'];

export default func;
