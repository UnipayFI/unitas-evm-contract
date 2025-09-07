// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import "../contracts/USDu.sol";
import "../contracts/interfaces/IUnitasMinting.sol";
import "../contracts/UnitasMinting.sol";
import "../contracts/USDu.sol";

contract GrantMinter is Script {
  address public unitasMintingAddress;

  function run() public virtual {
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(ownerPrivateKey);
    // update to correct UnitasMinting address
    unitasMintingAddress = address(0x8543703e1e9d4bCe16ae1C6f73c43F7CEBF99808);
    USDu usduToken = USDu(address(0x400835DB609170D1c268bF0d8039b3644Cf7793B));

    // update array size and grantee addresses

    usduToken.setMinter(unitasMintingAddress);

    vm.stopBroadcast();
  }
}
