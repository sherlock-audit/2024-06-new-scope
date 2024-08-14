import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-ethers';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@openzeppelin/hardhat-upgrades';
import '@typechain/hardhat';
import 'hardhat-abi-exporter';
import 'hardhat-contract-sizer';
import 'hardhat-dependency-compiler';
import 'hardhat-deploy';
import 'hardhat-tracer';
import 'solidity-coverage';
import 'solidity-docgen';
import { loadTasks } from './tasks/hardhat-config';

import dotenv from 'dotenv';
dotenv.config();

const defaultAccount = {
  mnemonic:
    process.env.SEED_PHRASE || 'test test test test test test test test test test test junk',
  path: "m/44'/60'/0'/0",
  initialIndex: 0,
  count: 20,
  passphrase: '',
};

// Prevent to load tasks before compilation and typechain
const SKIP_LOAD = process.env.SKIP_LOAD === 'true';
if (!SKIP_LOAD) loadTasks(['tasks']);

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.19',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter: {
    // @ts-ignore
    reportFormat: 'terminal',
    outputFile: 'coverage/gasReport.txt',
    noColors: true,
    forceTerminalOutput: true,
    forceTerminalOutputFormat: 'terminal',
  },
  paths: {
    tests: './test/hardhat',
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      live: false,
      loggingEnabled: false,
      allowBlocksWithSameTimestamp: true,
      allowUnlimitedContractSize: true,
      // forking: {
      //   url: `https://cloudflare-eth.com`,
      // },
    },
    sepolia: {
      url: `https://1rpc.io/sepolia`,
      accounts: defaultAccount,
      saveDeployments: true,
    },
    mainnet: {
      url: `https://cloudflare-eth.com`,
      accounts: defaultAccount,
      saveDeployments: true,
    },
    linea: {
      url: `https://rpc.linea.build`,
      accounts: defaultAccount,
      saveDeployments: true,
    },
  },
  abiExporter: {
    path: './abi',
    runOnCompile: true,
    clear: true,
    spacing: 2,
  },
  docgen: {
    pages: 'files',
    exclude: ['interfaces', 'periphery/interfaces', 'governance', 'mocks'],
  },
  typechain: {
    outDir: 'types',
  },
  namedAccounts: {
    deployer: 0,
  },
  dependencyCompiler: {
    paths: ['@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol'],
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY || '',
      linea: process.env.LINEASCAN_KEY || '',
    },
    customChains: [
      {
        network: 'linea',
        chainId: 59144,
        urls: {
          apiURL: 'https://api.lineascan.build/api',
          browserURL: 'https://lineascan.build',
        },
      },
    ],
  },
};

export default config;
