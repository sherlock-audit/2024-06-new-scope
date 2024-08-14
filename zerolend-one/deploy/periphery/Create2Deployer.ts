import { HardhatRuntimeEnvironment } from 'hardhat/types';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const deployment = await deploy('Create2Deployer', {
    from: deployer,
    contract: 'Create2Deployer',
    autoMine: true,
    log: true,
  });

  await hre.run('verify:verify', {
    address: deployment.address,
  });
}

main.tags = ['Create2Deployer'];
export default main;
