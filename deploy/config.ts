import { getAddress, parseEther, ZeroAddress } from "ethers";

export const config = {
  bsc_testnet: {
    usduAdmin: ZeroAddress,
    stakedUsduAdmin: ZeroAddress,
    stakedUsduRewarder: ZeroAddress,
    mintingAdmin: ZeroAddress,
    maxMintPerBlock: parseEther("10200000"),
    maxRedeemPerBlock: parseEther("2000000"),
    weth: getAddress("0xae13d989dac2f0debff460ac112a837c89baa7cd"),
    assets: [getAddress("0x42e3D7f4cfE3B94BCeF3EBaEa832326AcB40C142")],
    tokenConfig: [
      {
        tokenType: 0,
        isActive: true,
        maxMintPerBlock: parseEther("10200000"),
        maxRedeemPerBlock: parseEther("2000000"),
      },
    ],
    custodians: [],
  },
  bsc_mainnet: {
    usduAdmin: getAddress("0x8E3811B4Dc5022AB9C8Afbb54Be4Aa23780C62b3"),
    stakedUsduAdmin: getAddress("0x179650b38B20773393c3a10B3b55ba57780BDBD9"),
    stakedUsduRewarder: getAddress("0xE59965162286D67308e2ebb6c34E0e18caEAA4F9"),
    mintingAdmin: getAddress("0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8"),
    maxMintPerBlock: parseEther("10200000"),
    maxRedeemPerBlock: parseEther("2000000"),
    weth: getAddress("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"),
    assets: [
      getAddress("0x55d398326f99059fF775485246999027B3197955"), // BNB_USDT
      getAddress("0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"), // BNB_USDC
    ],
    tokenConfig: [
      {
        tokenType: 0,
        isActive: true,
        maxMintPerBlock: parseEther("200000000"),
        maxRedeemPerBlock: parseEther("10000000"),
      },
      {
        tokenType: 0,
        isActive: true,
        maxMintPerBlock: parseEther("200000000"),
        maxRedeemPerBlock: parseEther("10000000"),
      },
    ],
    custodians: [getAddress("0xB464C9890604926bd5Fa7b66Bf15d26BCD0eD3A9")],
  },
  eth_sepolia: {
    usduAdmin: ZeroAddress,
    stakedUsduAdmin: ZeroAddress,
    stakedUsduRewarder: ZeroAddress,
    mintingAdmin: ZeroAddress,
    maxMintPerBlock: parseEther("10200000"),
    maxRedeemPerBlock: parseEther("2000000"),
    weth: getAddress("0x7b79995e5f793a07bc00c21412e50ecae098e7f9"),
    assets: [getAddress("0x3DCbd62a22F0172AA0b6aC9989DfBcb9A3b021DC")],
    tokenConfig: [
      {
        tokenType: 0,
        isActive: true,
        maxMintPerBlock: parseEther("10200000"),
        maxRedeemPerBlock: parseEther("2000000"),
      },
    ],
    custodians: [],
  },
};
