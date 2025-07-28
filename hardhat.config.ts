import '@nomicfoundation/hardhat-ethers';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import '@openzeppelin/hardhat-upgrades';
import '@typechain/hardhat';
import 'hardhat-abi-exporter'
import 'hardhat-contract-sizer'
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

import dotenv from 'dotenv';
dotenv.config();

const DEFAULT_COMPILER_SETTINGS = {
    version: "0.8.19",
    settings: {
        optimizer: {
            enabled: true,
            runs: 500,
        },
        metadata: {
            bytecodeHash: "none",
        },
    },
};

const config = {
    solidity: {
        compilers: [DEFAULT_COMPILER_SETTINGS],
    },
    namedAccounts: {
        deployer: {
            default: 0
        }
    },
    networks: {
        bsc_testnet: {
            url: process.env.BSC_TESTNET_URL,
            accounts: [process.env.TESTNET_PRIVATE_KEY],
        },
        bsc_mainnet: {
            url: process.env.BSC_MAINNET_URL,
            accounts: [process.env.MAINNET_PRIVATE_KEY],
        },
        eth_sepolia: {
            url: process.env.SEPOLIA_TESTNET_URL,
            accounts: [process.env.TESTNET_PRIVATE_KEY],
        }
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    },
    etherscan: {},
    abiExporter: {
        runOnCompile: true,
    },
};

export default config;
