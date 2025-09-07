// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/StakedUSDuV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract StakeDeployment is Script {
  // update accordingly
  address public usduAddress = address(0x8191DC3053Fe4564c17694cB203663d3C07B8960);
  address public rewarder = address(0x3Aa3Fd1B762CaC519D405297CE630beD30430b00);
  address public owner = address(0x3Aa3Fd1B762CaC519D405297CE630beD30430b00);

  function run() public virtual {
    uint256 ownerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
    vm.startBroadcast(ownerPrivateKey);
    StakedUSDuV2 stakedUSDu = new StakedUSDuV2(IERC20(usduAddress), rewarder, owner);
    vm.stopBroadcast();

    console.log("=====> StakedUSDuV2 deployed ....");
    console.log("StakedUSDuV2                          : https://etherscan.io/address/%s", address(stakedUSDu));
  }
}
