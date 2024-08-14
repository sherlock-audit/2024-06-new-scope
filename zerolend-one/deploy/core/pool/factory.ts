import { ZeroAddress } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // const poolImpl = await deployments.get('Pool');

  const deployment = await deploy('PoolFactory', {
    from: deployer,
    contract: 'PoolFactory',
    args: [ZeroAddress],
    autoMine: true,
    log: true,
  });

  await hre.run('verify:verify', {
    address: deployment.address,
    constructorArguments: deployment.args,
  });
}

main.tags = ['PoolFactory'];
export default main;
