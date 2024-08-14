import { parseUnits } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const args = [
    parseUnits('0.45', 27).toString(),
    '0',
    parseUnits('0.07', 27).toString(),
    parseUnits('0.3', 27).toString(),
  ];
  const deployment = await deploy('DefaultReserveInterestRateStrategy', {
    from: deployer,
    contract: 'DefaultReserveInterestRateStrategy',
    args,
    autoMine: true,
    log: true,
  });

  await hre.run('verify:verify', {
    address: deployment.address,
    constructorArguments: args,
  });
}

main.tags = ['DefaultReserveInterestRateStrategy'];
export default main;
