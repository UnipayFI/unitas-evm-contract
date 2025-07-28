import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const usdu = await ethers.getContract("USDu")
  const stakedUsdu = await ethers.getContract("StakedUSDuV2")
  await deploy("USDuSilo", {
    from: deployer,
    log: true,
    args: [await stakedUsdu.getAddress(), await usdu.getAddress()],
  })
}

func.id = "usdu_silo"
func.tags = ["USDuSilo"]
func.dependencies = ["USDu", "StakedUSDuV2", "UnitasMinting"]
export default func
