import { ZeroAddress } from "ethers"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { config } from "./config"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  let admin
  const network = hre.network.name as keyof typeof config
  if (!network) {
    throw new Error("Network not found")
  }
  const networkConfig = config[network]
  if (!networkConfig) {
    throw new Error("Network config not found")
  }
  if (networkConfig.usduAdmin === ZeroAddress) {
    admin = deployer
  } else {
    admin = networkConfig.usduAdmin
  }

  await deploy("USDu", {
    from: deployer,
    log: true,
    args: [admin],
  })
}

func.id = "usdu"
func.tags = ["USDu"]
export default func
