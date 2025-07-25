// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* solhint-disable func-name-mixedcase  */
/* solhint-disable private-vars-leading-underscore  */

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "../../../contracts/USDu.sol";
import "../../../contracts/StakedUSDuV2.sol";
import "../../../contracts/interfaces/IUSDu.sol";
import "../../../contracts/interfaces/IERC20Events.sol";
import "./StakedUSDu.t.sol";

/// @dev Run all StakedUSDuV1 tests against StakedUSDuV2 with cooldown duration zero, to ensure backwards compatibility
contract StakedUSDuV2CooldownDisabledTest is StakedUSDuTest {
  StakedUSDuV2 stakedUSDuV2;

  function setUp() public virtual override {
    usduToken = new USDu(address(this));

    alice = vm.addr(0xB44DE);
    bob = vm.addr(0x1DE);
    greg = vm.addr(0x6ED);
    owner = vm.addr(0xA11CE);
    rewarder = vm.addr(0x1DEA);
    vm.label(alice, "alice");
    vm.label(bob, "bob");
    vm.label(greg, "greg");
    vm.label(owner, "owner");
    vm.label(rewarder, "rewarder");

    vm.startPrank(owner);
    stakedUSDu = new StakedUSDuV2(IUSDu(address(usduToken)), rewarder, owner);
    stakedUSDuV2 = StakedUSDuV2(address(stakedUSDu));

    // Disable cooldown and unstake methods, enable StakedUSDuV1 methods
    stakedUSDuV2.setCooldownDuration(0);
    vm.stopPrank();

    sigUtilsUSDu = new SigUtils(usduToken.DOMAIN_SEPARATOR());
    sigUtilsStakedUSDu = new SigUtils(stakedUSDu.DOMAIN_SEPARATOR());

    usduToken.setMinter(address(this));
  }

  function test_cooldownShares_fails_cooldownDuration_zero() external {
    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDuV2.cooldownShares(0, address(0));
  }

  function test_cooldownAssets_fails_cooldownDuration_zero() external {
    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDuV2.cooldownAssets(0, address(0));
  }
}
