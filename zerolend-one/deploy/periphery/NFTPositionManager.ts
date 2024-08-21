import { HardhatRuntimeEnvironment } from 'hardhat/types';

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // linea values
  const staking = '0x2666951a62d82860e8e1385581e2fb7669097647';
  const zero = '0x78354f8dccb269a615a7e0a24f9b0718fdc3c7a7';
  const safe = '0x14aAD4668de2115e30A5FeeE42CFa436899CCD8A';
  const weth = '0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f';
  const factory = (await deployments.get('PoolFactory')).address;

  const deployment = await deploy('NFTPositionManager', {
    from: deployer,
    proxy: {
      owner: safe,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            factory, // address _factory,
            staking, // address _staking,
            deployer, // address _owner,
            zero, // address _zero
            weth,
          ],
        },
      },
    },
    contract: 'NFTPositionManager',
    autoMine: true,
    log: true,
  });

  await hre.run('verify:verify', { address: deployment.address });
}

main.tags = ['NFTPositionManager'];
export default main;
