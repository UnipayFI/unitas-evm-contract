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
    version: "0.8.27",
    settings: {
        viaIR: true,
        optimizer: {
            enabled: true,
            runs: 20,
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
    etherscan: {
        apiKey: {
            bsc_testnet: process.env.BSCSCAN_API_KEY,
            bsc_mainnet: process.env.BSCSCAN_API_KEY,
            eth_sepolia: process.env.ETHERSCAN_API_KEY
        },
        customChains: [
            {
                network: "bsc_mainnet",
                chainId: 56,
                urls: {
                    apiURL: "https://api.etherscan.io/v2/api?chainid=56",
                    browserURL: "https://bscscan.com"
                }
            }
        ]
    },
    abiExporter: {
        runOnCompile: true,
    },
};

export default config;
