import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

task(`test-ui-helper`)
  .addParam('pool')
  .setAction(async (params, hre: HardhatRuntimeEnvironment) => {
    const uiHelperD = await hre.deployments.get('UIHelper');
    const uiHelper = await hre.ethers.getContractAt('UIHelper', uiHelperD.address);

    const config = await uiHelper.getPoolFullConfig(params.pool);

    console.log('config.emergencyAdmins', config.emergencyAdmins);
    console.log('config.poolAdmins', config.poolAdmins);
    console.log('config.riskAdmins', config.riskAdmins);
    console.log('config.hook', config.hook);
    console.log('config.proxyAdmin', config.proxyAdmin);
    console.log('config.proxyRevoked', config.proxyRevoked);

    for (let index = 0; index < config.reserves.length; index++) {
      const element = {
        asset: config.reserves[index].asset,
        interestRateStrategy: config.reserves[index].interestRateStrategy,
        oracle: config.reserves[index].oracle,
        borrowable: config.reserves[index].borrowable,
        frozen: config.reserves[index].frozen,
        borrowCap: config.reserves[index].borrowCap,
        decimals: config.reserves[index].decimals,
        liquidationBonus: config.reserves[index].liquidationBonus,
        liquidationThreshold: config.reserves[index].liquidationThreshold,
        ltv: config.reserves[index].ltv,
        supplyCap: config.reserves[index].supplyCap,
      };
      console.log('config.reserves', index, element);
    }
  });
