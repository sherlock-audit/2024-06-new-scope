import { task } from 'hardhat/config';
import { waitForTx } from './utils';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

task(`set-pool-configurator`).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
  const factoryD = await hre.deployments.get('PoolFactory');
  const config = await hre.deployments.get('PoolConfigurator');
  const factory = await hre.ethers.getContractAt('PoolFactory', factoryD.address);

  console.log('factory at', factory.target);
  console.log('updating configurator to', config.address);
  const tx = await factory.setConfigurator(config.address);
  await waitForTx(tx);
});
