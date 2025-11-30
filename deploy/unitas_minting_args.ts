import { parseEther } from "ethers";

const constructorArgs = [
  "0xeA953eA6634d55dAC6697C436B1e81A679Db5882",
  "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  ["0x55d398326f99059fF775485246999027B3197955", "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"],
  [
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
  {
    globalMaxMintPerBlock: parseEther("10200000"),
    globalMaxRedeemPerBlock: parseEther("2000000"),
  },
  ["0xB464C9890604926bd5Fa7b66Bf15d26BCD0eD3A9"],
  "0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8",
];

export default constructorArgs;
