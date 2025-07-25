// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "../../../contracts/USDu.sol";
import "../../../contracts/StakedUSDu.sol";
import "../../../contracts/interfaces/IStakedUSDu.sol";
import "../../../contracts/interfaces/IUSDu.sol";
import "../../../contracts/interfaces/IERC20Events.sol";
import "../../../contracts/interfaces/ISingleAdminAccessControl.sol";

contract StakedUSDuACL is Test, IERC20Events {
  USDu public usduToken;
  StakedUSDu public stakedUSDu;
  SigUtils public sigUtilsUSDu;
  SigUtils public sigUtilsStakedUSDu;

  address public owner;
  address public rewarder;
  address public alice;
  address public newOwner;
  address public greg;

  bytes32 public DEFAULT_ADMIN_ROLE;
  bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
  bytes32 public constant FULL_RESTRICTED_STAKER_ROLE = keccak256("FULL_RESTRICTED_STAKER_ROLE");

  event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  event RewardsReceived(uint256 indexed amount, uint256 newVestingUSDuAmount);

  function setUp() public virtual {
    usduToken = new USDu(address(this));

    alice = vm.addr(0xB44DE);
    newOwner = vm.addr(0x1DE);
    greg = vm.addr(0x6ED);
    owner = vm.addr(0xA11CE);
    rewarder = vm.addr(0x1DEA);
    vm.label(alice, "alice");
    vm.label(newOwner, "newOwner");
    vm.label(greg, "greg");
    vm.label(owner, "owner");
    vm.label(rewarder, "rewarder");

    vm.prank(owner);
    stakedUSDu = new StakedUSDu(IUSDu(address(usduToken)), rewarder, owner);

    DEFAULT_ADMIN_ROLE = stakedUSDu.DEFAULT_ADMIN_ROLE();

    sigUtilsUSDu = new SigUtils(usduToken.DOMAIN_SEPARATOR());
    sigUtilsStakedUSDu = new SigUtils(stakedUSDu.DOMAIN_SEPARATOR());
  }

  function testCorrectSetup() public view {
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testCancelTransferAdmin() public {
    vm.startPrank(owner);
    stakedUSDu.transferAdmin(newOwner);
    stakedUSDu.transferAdmin(address(0));
    vm.stopPrank();
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function test_admin_cannot_transfer_self() public {
    vm.startPrank(owner);
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    stakedUSDu.transferAdmin(owner);
    vm.stopPrank();
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testAdminCanCancelTransfer() public {
    vm.startPrank(owner);
    stakedUSDu.transferAdmin(newOwner);
    stakedUSDu.transferAdmin(address(0));
    vm.stopPrank();

    vm.prank(newOwner);
    vm.expectRevert(ISingleAdminAccessControl.NotPendingAdmin.selector);
    stakedUSDu.acceptAdmin();

    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.startPrank(owner);
    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDu.renounceRole(DEFAULT_ADMIN_ROLE, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    stakedUSDu.revokeRole(DEFAULT_ADMIN_ROLE, owner);
    vm.stopPrank();
    assertEq(stakedUSDu.owner(), owner);
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(owner);
    stakedUSDu.transferAdmin(newOwner);
    assertEq(stakedUSDu.owner(), owner);
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertNotEq(stakedUSDu.owner(), newOwner);
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function testCanTransferOwnership() public {
    vm.prank(owner);
    stakedUSDu.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedUSDu.acceptAdmin();
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(owner);
    stakedUSDu.transferAdmin(newOwner);
    vm.startPrank(newOwner);
    stakedUSDu.acceptAdmin();
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, newOwner);
    stakedUSDu.addToBlacklist(alice, true);
    vm.stopPrank();
    assertTrue(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice));
  }

  function testOldOwnerCantPerformOwnerActions() public {
    vm.prank(owner);
    stakedUSDu.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedUSDu.acceptAdmin();
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertFalse(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(owner);
    stakedUSDu.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedUSDu.acceptAdmin();
    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedUSDu.transferAdmin(alice);
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));
  }

  function testNonAdminCantRenounceRoles() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));

    vm.prank(alice);
    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDu.renounceRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
  }
}
