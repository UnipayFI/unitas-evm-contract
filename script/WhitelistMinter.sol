// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import "../contracts/USDu.sol";
import "../contracts/interfaces/IUnitasMinting.sol";
import "../contracts/UnitasMinting.sol";

contract WhitelistMinters is Script {
  address public unitasMintingAddress;

  function run() public virtual {
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(ownerPrivateKey);
    // update to correct UnitasMinting address
    unitasMintingAddress = address(0x980C680a90631c8Ea49fA37B47AbC3154219EC1a);
    UnitasMinting unitasMinting = UnitasMinting(payable(unitasMintingAddress));
    bytes32 unitasMintingMinterRole = keccak256("MINTER_ROLE");

    // update array size and grantee addresses
    // ETH Execution Nodes
    address[] memory grantees = new address[](2);
    grantees[0] = address(0x13d2e29D174D075fA63cBc335a85d4a39bC71d5b);
    grantees[1] = address(0x1D475DD6312D21B80eb6123937FE7AbC4640adA5);
    grantees[1] = address(0x9a073D235A8D2C37854Da6f6A8F075C916debe06);

    for (uint256 i = 0; i < grantees.length; ++i) {
      if (!unitasMinting.hasRole(unitasMintingMinterRole, grantees[i])) {
        unitasMinting.grantRole(unitasMintingMinterRole, grantees[i]);
      }
    }
    vm.stopBroadcast();
  }
}
