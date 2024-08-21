import { parseUnits } from 'ethers';
import { ethers } from 'hardhat';

export async function deployCore() {
  const [owner, whale, ant, governance] = await ethers.getSigners();

  const PositionBalanceConfiguration = await ethers.getContractFactory(
    'PositionBalanceConfiguration'
  );
  const positionBalanceConfiguration = await PositionBalanceConfiguration.deploy();

  const BorrowLogic = await ethers.getContractFactory('BorrowLogic');
  const FlashLoanLogic = await ethers.getContractFactory('FlashLoanLogic');
  const LiquidationLogic = await ethers.getContractFactory('LiquidationLogic');
  const WETH9Mocked = await ethers.getContractFactory('WETH9Mocked');
  const PoolLogic = await ethers.getContractFactory('PoolLogic');
  const SupplyLogic = await ethers.getContractFactory('SupplyLogic', {
    libraries: { PositionBalanceConfiguration: positionBalanceConfiguration.target },
  });
  const PoolFactory = await ethers.getContractFactory('PoolFactory');
  const CuratedVaultFactory = await ethers.getContractFactory('CuratedVaultFactory');
  const CuratedVault = await ethers.getContractFactory('CuratedVault');
  const PoolConfigurator = await ethers.getContractFactory('PoolConfigurator');
  const MintableERC20 = await ethers.getContractFactory('MintableERC20');
  const MockV3Aggregator = await ethers.getContractFactory('MockV3Aggregator');
  const DefaultReserveInterestRateStrategy = await ethers.getContractFactory(
    'DefaultReserveInterestRateStrategy'
  );

  const borrowLogic = await BorrowLogic.deploy();
  const flashLoanLogic = await FlashLoanLogic.deploy();
  const liquidationLogic = await LiquidationLogic.deploy();
  const poolLogic = await PoolLogic.deploy();
  const supplyLogic = await SupplyLogic.deploy();

  const libraries = {
    PositionBalanceConfiguration: positionBalanceConfiguration.target,
    BorrowLogic: borrowLogic.target,
    FlashLoanLogic: flashLoanLogic.target,
    LiquidationLogic: liquidationLogic.target,
    PoolLogic: poolLogic.target,
    SupplyLogic: supplyLogic.target,
  };

  const Pool = await ethers.getContractFactory('Pool', { libraries });

  // deploy pool
  const poolImpl = await Pool.deploy();
  const poolFactory = await PoolFactory.deploy(poolImpl.target);
  const configurator = await PoolConfigurator.deploy(poolFactory.target);
  await poolFactory.setConfigurator(configurator.target);

  // deploy vault
  const curatedVaultImpl = await CuratedVault.deploy();
  const curatedVaultFactory = await CuratedVaultFactory.deploy(curatedVaultImpl.target);

  // create dummy tokens
  const tokenA = await MintableERC20.deploy('TOKEN A', 'TOKENA');
  const tokenB = await MintableERC20.deploy('TOKEN B', 'TOKENB');
  const weth = await WETH9Mocked.deploy();
  const tokenC = await MintableERC20.deploy('TOKEN C', 'TOKENC');

  // create dummy oracles
  const oracleA = await MockV3Aggregator.deploy(8, 5000);
  const oracleB = await MockV3Aggregator.deploy(8, 2000);
  const oracleC = await MockV3Aggregator.deploy(8, 1500);

  const irStrategy = await DefaultReserveInterestRateStrategy.deploy(
    parseUnits('0.45', 27).toString(),
    '0',
    parseUnits('0.07', 27).toString(),
    parseUnits('0.3', 27).toString()
  );

  return {
    owner,
    whale,
    ant,
    configurator,
    governance,
    irStrategy,
    weth,
    poolImpl,
    poolFactory,
    curatedVaultFactory,
    curatedVaultImpl,
    tokenA,
    tokenB,
    tokenC,
    oracleA,
    oracleB,
    oracleC,
    libraries,
  };
}
