import { HardhatRuntimeEnvironment } from 'hardhat/types';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const factory = await deployments.get('PoolFactory');
  const args = [factory.address, deployer];

  const deployment = await deploy('PoolConfigurator', {
    from: deployer,
    contract: 'PoolConfigurator',
    args: args,
    autoMine: true,
    log: true,
  });

  await hre.run('verify:verify', {
    address: deployment.address,
    constructorArguments: deployment.args,
  });
}

main.tags = ['PoolConfigurator'];
export default main;
