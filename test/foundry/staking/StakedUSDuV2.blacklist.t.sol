// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable var-name-mixedcase  */
/* solhint-disable func-name-mixedcase  */

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "../../../contracts/USDu.sol";
import "../../../contracts/StakedUSDuV2.sol";
import "../../../contracts/interfaces/IUSDu.sol";
import "../../../contracts/interfaces/IERC20Events.sol";

contract StakedUSDuV2CooldownBlacklistTest is Test, IERC20Events {
  USDu public usduToken;
  StakedUSDuV2 public stakedUSDu;
  SigUtils public sigUtilsUSDu;
  SigUtils public sigUtilsStakedUSDu;
  uint256 public _amount = 100 ether;

  address public owner;
  address public alice;
  address public bob;
  address public greg;

  bytes32 SOFT_RESTRICTED_STAKER_ROLE;
  bytes32 FULL_RESTRICTED_STAKER_ROLE;
  bytes32 DEFAULT_ADMIN_ROLE;
  bytes32 BLACKLIST_MANAGER_ROLE;
  bytes32 REWARDER_ROLE;

  event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  event LockedAmountRedistributed(address indexed from, address indexed to, uint256 amountToDistribute);

  function setUp() public virtual {
    usduToken = new USDu(address(this));

    alice = makeAddr("alice");
    bob = makeAddr("bob");
    greg = makeAddr("greg");
    owner = makeAddr("owner");

    usduToken.setMinter(address(this));

    vm.startPrank(owner);
    stakedUSDu = new StakedUSDuV2(IUSDu(address(usduToken)), makeAddr("rewarder"), owner);
    vm.stopPrank();

    FULL_RESTRICTED_STAKER_ROLE = keccak256("FULL_RESTRICTED_STAKER_ROLE");
    SOFT_RESTRICTED_STAKER_ROLE = keccak256("SOFT_RESTRICTED_STAKER_ROLE");
    DEFAULT_ADMIN_ROLE = 0x00;
    BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    REWARDER_ROLE = keccak256("REWARDER_ROLE");
  }

  function _mintApproveDeposit(address staker, uint256 amount, bool expectRevert) internal {
    usduToken.mint(staker, amount);

    vm.startPrank(staker);
    usduToken.approve(address(stakedUSDu), amount);

    uint256 sharesBefore = stakedUSDu.balanceOf(staker);
    if (expectRevert) {
      vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    } else {
      vm.expectEmit(true, true, true, false);
      emit Deposit(staker, staker, amount, amount);
    }
    stakedUSDu.deposit(amount, staker);
    uint256 sharesAfter = stakedUSDu.balanceOf(staker);
    if (expectRevert) {
      assertEq(sharesAfter, sharesBefore);
    } else {
      assertApproxEqAbs(sharesAfter - sharesBefore, amount, 1);
    }
    vm.stopPrank();
  }

  function _redeem(address staker, uint256 amount, bool expectRevert) internal {
    uint256 balBefore = usduToken.balanceOf(staker);

    vm.startPrank(staker);

    if (expectRevert) {
      vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    } else {}

    stakedUSDu.cooldownAssets(amount, staker);
    (uint104 cooldownEnd, uint256 assetsOut) = stakedUSDu.cooldowns(staker);

    vm.warp(cooldownEnd + 1);

    stakedUSDu.unstake(staker);
    vm.stopPrank();

    uint256 balAfter = usduToken.balanceOf(staker);

    if (expectRevert) {
      assertEq(balBefore, balAfter);
    } else {
      assertApproxEqAbs(assetsOut, balAfter - balBefore, 1);
    }
  }

  function testStakeFlowCommonUser() public {
    _mintApproveDeposit(greg, _amount, false);

    assertEq(usduToken.balanceOf(greg), 0);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), _amount);
    assertEq(stakedUSDu.balanceOf(greg), _amount);

    _redeem(greg, _amount, false);

    assertEq(usduToken.balanceOf(greg), _amount);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), 0);
    assertEq(stakedUSDu.balanceOf(greg), 0);
  }

  /**
   * Soft blacklist: mints not allowed. Burns or transfers are allowed
   */
  function test_softBlacklist_deposit_reverts() public {
    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _mintApproveDeposit(alice, _amount, true);
  }

  function test_softBlacklist_withdraw_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _redeem(alice, _amount, false);
  }

  function test_softBlacklist_transfer_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.prank(alice);
    stakedUSDu.transfer(bob, _amount);
  }

  function test_softBlacklist_transferFrom_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.prank(alice);
    stakedUSDu.approve(bob, _amount);

    vm.prank(bob);
    stakedUSDu.transferFrom(alice, bob, _amount);
  }

  /**
   * Full blacklist: mints, burns or transfers are not allowed
   */
  function test_fullBlacklist_deposit_reverts() public {
    // Alice full blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _mintApproveDeposit(alice, _amount, true);
  }

  function test_fullBlacklist_withdraw_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _redeem(alice, _amount, true);
  }

  function test_fullBlacklist_transfer_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    vm.prank(alice);
    stakedUSDu.transfer(bob, _amount);
  }

  function test_fullBlacklist_transferFrom_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.prank(alice);
    stakedUSDu.approve(bob, _amount);

    vm.prank(bob);

    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDu.transferFrom(alice, bob, _amount);
  }

  function test_fullBlacklist_can_not_be_transfer_recipient() public {
    _mintApproveDeposit(alice, _amount, false);
    _mintApproveDeposit(bob, _amount, false);

    // Alice full blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    vm.prank(bob);
    stakedUSDu.transfer(alice, _amount);
  }

  function test_fullBlacklist_user_can_not_burn_and_donate_to_vault() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice full blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.expectRevert(bytes("ERC20: transfer to the zero address"));
    vm.prank(alice);
    stakedUSDu.transfer(address(0), _amount);
  }

  /**
   * Soft and Full blacklist: mints, burns or transfers are not allowed
   */
  function test_softFullBlacklist_deposit_reverts() public {
    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _mintApproveDeposit(alice, _amount, true);

    // Alice full blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();
    _mintApproveDeposit(alice, _amount, true);
  }

  function test_softFullBlacklist_withdraw_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _redeem(alice, _amount / 3, false);

    // Alice full blacklisted
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    _redeem(alice, _amount / 3, true);
  }

  function test_softFullBlacklist_transfer_pass() public {
    _mintApproveDeposit(alice, _amount, false);

    // Alice soft blacklisted can transfer
    vm.startPrank(owner);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.prank(alice);
    stakedUSDu.transfer(bob, _amount / 3);

    // Alice full blacklisted cannot transfer
    vm.startPrank(owner);
    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.stopPrank();

    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    vm.prank(alice);
    stakedUSDu.transfer(bob, _amount / 3);
  }

  /**
   * redistributeLockedAmount
   */
  function test_redistributeLockedAmount() public {
    _mintApproveDeposit(alice, _amount, false);
    uint256 aliceStakedBalance = stakedUSDu.balanceOf(alice);
    uint256 previousTotalSupply = stakedUSDu.totalSupply();
    assertEq(aliceStakedBalance, _amount);

    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);

    vm.expectEmit(true, true, true, true);
    emit LockedAmountRedistributed(alice, bob, _amount);

    stakedUSDu.redistributeLockedAmount(alice, bob);

    vm.stopPrank();

    assertEq(stakedUSDu.balanceOf(alice), 0);
    assertEq(stakedUSDu.balanceOf(bob), _amount);
    assertEq(stakedUSDu.totalSupply(), previousTotalSupply);
  }

  function testCanBurnOnRedistribute() public {
    _mintApproveDeposit(alice, _amount, false);
    uint256 aliceStakedBalance = stakedUSDu.balanceOf(alice);
    uint256 previousTotalSupply = stakedUSDu.totalSupply();
    assertEq(aliceStakedBalance, _amount);

    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);

    stakedUSDu.redistributeLockedAmount(alice, address(0));

    vm.stopPrank();

    assertEq(stakedUSDu.balanceOf(alice), 0);
    assertEq(stakedUSDu.totalSupply(), previousTotalSupply - _amount);
  }

  /**
   * Access control
   */
  function test_renounce_reverts() public {
    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    vm.expectRevert();
    stakedUSDu.renounceRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.expectRevert();
    stakedUSDu.renounceRole(SOFT_RESTRICTED_STAKER_ROLE, alice);
  }

  function test_grant_role() public {
    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    assertEq(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice), true);
    assertEq(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, alice), true);
  }

  function test_revoke_role() public {
    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    assertEq(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice), true);
    assertEq(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, alice), true);

    stakedUSDu.revokeRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.revokeRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    assertEq(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice), false);
    assertEq(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, alice), false);

    vm.stopPrank();
  }

  function test_revoke_role_by_other_reverts() public {
    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    vm.startPrank(bob);

    vm.expectRevert();
    stakedUSDu.revokeRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.expectRevert();
    stakedUSDu.revokeRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    assertEq(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice), true);
    assertEq(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, alice), true);
  }

  function test_revoke_role_by_myself_reverts() public {
    vm.startPrank(owner);

    stakedUSDu.grantRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    stakedUSDu.grantRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    vm.startPrank(alice);

    vm.expectRevert();
    stakedUSDu.revokeRole(FULL_RESTRICTED_STAKER_ROLE, alice);
    vm.expectRevert();
    stakedUSDu.revokeRole(SOFT_RESTRICTED_STAKER_ROLE, alice);

    vm.stopPrank();

    assertEq(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice), true);
    assertEq(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, alice), true);
  }

  function testAdminCannotRenounce() public {
    vm.startPrank(owner);

    vm.expectRevert(IStakedUSDu.OperationNotAllowed.selector);
    stakedUSDu.renounceRole(DEFAULT_ADMIN_ROLE, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    stakedUSDu.revokeRole(DEFAULT_ADMIN_ROLE, owner);

    vm.stopPrank();

    assertTrue(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertEq(stakedUSDu.owner(), owner);
  }

  function testBlacklistManagerCanBlacklist() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    vm.startPrank(alice);
    stakedUSDu.addToBlacklist(bob, true);
    assertTrue(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, bob));

    stakedUSDu.addToBlacklist(bob, false);
    assertTrue(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, bob));
    vm.stopPrank();
  }

  function testBlacklistManagerCannotRedistribute() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    _mintApproveDeposit(bob, 1000 ether, false);
    assertEq(stakedUSDu.balanceOf(bob), 1000 ether);

    vm.startPrank(alice);
    stakedUSDu.addToBlacklist(bob, true);
    assertTrue(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, bob));
    vm.expectRevert(
      "AccessControl: account 0x328809bc894f92807417d2dad6b7c998c1afdac6 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedUSDu.redistributeLockedAmount(bob, alice);
    assertEq(stakedUSDu.balanceOf(bob), 1000 ether);
    vm.stopPrank();
  }

  function testBlackListManagerCannotAddOthers() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    vm.prank(alice);
    vm.expectRevert(
      "AccessControl: account 0x328809bc894f92807417d2dad6b7c998c1afdac6 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, bob);
  }

  function testBlacklistManagerCanUnblacklist() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    vm.startPrank(alice);
    stakedUSDu.addToBlacklist(bob, true);
    assertTrue(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, bob));

    stakedUSDu.addToBlacklist(bob, false);
    assertTrue(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, bob));

    stakedUSDu.removeFromBlacklist(bob, true);
    assertFalse(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, bob));

    stakedUSDu.removeFromBlacklist(bob, false);
    assertFalse(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, bob));
    vm.stopPrank();
  }

  function testBlacklistManagerCanNotBlacklistAdmin() public {
    vm.prank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    vm.startPrank(alice);
    vm.expectRevert(IStakedUSDu.CantBlacklistOwner.selector);
    stakedUSDu.addToBlacklist(owner, true);
    vm.expectRevert(IStakedUSDu.CantBlacklistOwner.selector);
    stakedUSDu.addToBlacklist(owner, false);
    vm.stopPrank();

    assertFalse(stakedUSDu.hasRole(FULL_RESTRICTED_STAKER_ROLE, owner));
    assertFalse(stakedUSDu.hasRole(SOFT_RESTRICTED_STAKER_ROLE, owner));
  }

  function testOwnerCanRemoveBlacklistManager() public {
    vm.startPrank(owner);
    stakedUSDu.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
    assertFalse(stakedUSDu.hasRole(DEFAULT_ADMIN_ROLE, alice));

    stakedUSDu.revokeRole(BLACKLIST_MANAGER_ROLE, alice);
    vm.stopPrank();

    assertFalse(stakedUSDu.hasRole(BLACKLIST_MANAGER_ROLE, alice));
  }
}
