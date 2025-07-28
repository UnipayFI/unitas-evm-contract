import { ZeroAddress } from "ethers"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy("MockUSDT", {
    from: deployer,
    log: true,
    args: ["Mock USDT", "mUSDT"],
  })
}

func.id = "mock_usdt"
func.tags = ["MockUSDT"]
export default func
