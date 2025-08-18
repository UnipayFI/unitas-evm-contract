import { ZeroAddress } from "ethers"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { config } from "./config"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  let admin;
  let rewarder;
  const network = hre.network.name as keyof typeof config
  if (!network) {
    throw new Error("Network not found")
  }
  const networkConfig = config[network]
  if (!networkConfig) {
    throw new Error("Network config not found")
  }
  if (networkConfig.stakedUsduAdmin === ZeroAddress) {
    admin = deployer
  } else {
    admin = networkConfig.stakedUsduAdmin
  }
  if (networkConfig.stakedUsduRewarder === ZeroAddress) {
    rewarder = deployer
  } else {
    rewarder = networkConfig.stakedUsduRewarder
  }
  const wbnb = networkConfig.weth
  const usdu = await ethers.getContract("USDu")
  const globalConfig = {
    globalMaxMintPerBlock: networkConfig.maxMintPerBlock,
    globalMaxRedeemPerBlock: networkConfig.maxRedeemPerBlock,
  }
  console.log("globalConfig", globalConfig)
  const tokenConfig = networkConfig.tokenConfig
  const assets = networkConfig.assets
  let custodians: string[] = networkConfig.custodians
  if (custodians.length === 0) {
    custodians = [deployer]
  }
  console.log("custodians", custodians)
  await deploy("UnitasMintingV2", {
    from: deployer,
    log: true,
    args: [
      await usdu.getAddress(),
      wbnb,
      assets,
      tokenConfig,
      globalConfig,
      custodians,
      admin,
    ],
  })
}

func.id = "unitas_mintingv2"
func.tags = ["UnitasMintingV2"]
func.dependencies = ["USDu"]
export default func