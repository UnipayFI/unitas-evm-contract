import { getAddress, parseEther, ZeroAddress } from "ethers"

export const config = {
    bsc_testnet: {
        usduAdmin: ZeroAddress,
        stakedUsduAdmin: ZeroAddress,
        stakedUsduRewarder: ZeroAddress,
        mintingAdmin: ZeroAddress,
        maxMintPerBlock: parseEther("10200000"),
        maxRedeemPerBlock: parseEther("2000000"),
        weth: getAddress("0xae13d989dac2f0debff460ac112a837c89baa7cd"),
        assets: [
            getAddress("0x337610d27c682e347c9cd60bd4b3b107c9d34ddd"),
            getAddress("0xfe146E53b08E4204A26E3cC5037077bAa52EB174"),
        ],
        tokenConfig: [
            {
                tokenType: 0,
                isActive: true,
                maxMintPerBlock: parseEther("10200000"),
                maxRedeemPerBlock: parseEther("2000000"),
            },
        ],
        custodians: [
        ],
    },
    bsc_mainnet: {
        usduAdmin: ZeroAddress,
        stakedUsduAdmin: ZeroAddress,
        stakedUsduRewarder: ZeroAddress,
        mintingAdmin: ZeroAddress,
        maxMintPerBlock: parseEther("10200000"),
        maxRedeemPerBlock: parseEther("2000000"),
        weth: getAddress("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"),
        assets: [
            getAddress("0x2b90e061a517db2bbd7e39ef7f733fd234b494ca"),
        ],
        tokenConfig: [
            {
                tokenType: 0,
                isActive: true,
                maxMintPerBlock: parseEther("10200000"),
                maxRedeemPerBlock: parseEther("2000000"),
            },
        ],
        custodians: [
        ],
    },
    eth_sepolia: {
        usduAdmin: ZeroAddress,
        stakedUsduAdmin: ZeroAddress,
        stakedUsduRewarder: ZeroAddress,
        mintingAdmin: ZeroAddress,
        maxMintPerBlock: parseEther("10200000"),
        maxRedeemPerBlock: parseEther("2000000"),
        weth: getAddress("0x7b79995e5f793a07bc00c21412e50ecae098e7f9"),
        assets: [
            getAddress("0x3DCbd62a22F0172AA0b6aC9989DfBcb9A3b021DC"),
        ],
        tokenConfig: [
            {
                tokenType: 0,
                isActive: true,
                maxMintPerBlock: parseEther("10200000"),
                maxRedeemPerBlock: parseEther("2000000"),
            },
        ],
        custodians: [
        ],
    }
}
