import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { getPoolLibraries } from '../../helpers/contract-getters';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const deployment = await deploy('Pool', {
    from: deployer,
    contract: 'Pool',
    autoMine: true,
    log: true,
    libraries: await getPoolLibraries(hre),
  });

  await hre.run('verify:verify', {
    address: deployment.address,
    libraries: deployment.libraries,
  });
}

main.tags = ['Pool'];
export default main;
