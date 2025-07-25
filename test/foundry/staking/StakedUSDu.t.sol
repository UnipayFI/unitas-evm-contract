// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "../../../contracts/USDu.sol";
import "../../../contracts/StakedUSDu.sol";
import "../../../contracts/interfaces/IUSDu.sol";
import "../../../contracts/interfaces/IERC20Events.sol";

contract StakedUSDuTest is Test, IERC20Events {
  USDu public usduToken;
  StakedUSDu public stakedUSDu;
  SigUtils public sigUtilsUSDu;
  SigUtils public sigUtilsStakedUSDu;

  address public owner;
  address public rewarder;
  address public alice;
  address public bob;
  address public greg;

  bytes32 REWARDER_ROLE = keccak256("REWARDER_ROLE");

  event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  event RewardsReceived(uint256 indexed amount, uint256 newVestingUSDuAmount);

  function setUp() public virtual {
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

    vm.prank(owner);
    stakedUSDu = new StakedUSDu(IUSDu(address(usduToken)), rewarder, owner);

    sigUtilsUSDu = new SigUtils(usduToken.DOMAIN_SEPARATOR());
    sigUtilsStakedUSDu = new SigUtils(stakedUSDu.DOMAIN_SEPARATOR());

    usduToken.setMinter(address(this));
  }

  function _mintApproveDeposit(address staker, uint256 amount) internal {
    usduToken.mint(staker, amount);

    vm.startPrank(staker);
    usduToken.approve(address(stakedUSDu), amount);

    vm.expectEmit(true, true, true, false);
    emit Deposit(staker, staker, amount, amount);

    stakedUSDu.deposit(amount, staker);
    vm.stopPrank();
  }

  function _redeem(address staker, uint256 amount) internal {
    vm.startPrank(staker);

    vm.expectEmit(true, true, true, false);
    emit Withdraw(staker, staker, staker, amount, amount);

    stakedUSDu.redeem(amount, staker, staker);
    vm.stopPrank();
  }

  function _transferRewards(uint256 amount, uint256 expectedNewVestingAmount) internal {
    usduToken.mint(address(rewarder), amount);
    vm.startPrank(rewarder);

    usduToken.approve(address(stakedUSDu), amount);

    vm.expectEmit(true, false, false, true);
    emit Transfer(rewarder, address(stakedUSDu), amount);
    vm.expectEmit(true, false, false, false);
    emit RewardsReceived(amount, expectedNewVestingAmount);

    stakedUSDu.transferInRewards(amount);

    assertApproxEqAbs(stakedUSDu.getUnvestedAmount(), expectedNewVestingAmount, 1);
    vm.stopPrank();
  }

  function _assertVestedAmountIs(uint256 amount) internal view {
    assertApproxEqAbs(stakedUSDu.totalAssets(), amount, 2);
  }

  function testInitialStake() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);

    assertEq(usduToken.balanceOf(alice), 0);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), amount);
    assertEq(stakedUSDu.balanceOf(alice), amount);
  }

  function testInitialStakeBelowMin() public {
    uint256 amount = 0.99 ether;
    usduToken.mint(alice, amount);
    vm.startPrank(alice);
    usduToken.approve(address(stakedUSDu), amount);
    vm.expectRevert(IStakedUSDu.MinSharesViolation.selector);
    stakedUSDu.deposit(amount, alice);

    assertEq(usduToken.balanceOf(alice), amount);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), 0);
    assertEq(stakedUSDu.balanceOf(alice), 0);
  }

  function testCantWithdrawBelowMinShares() public {
    _mintApproveDeposit(alice, 1 ether);

    vm.startPrank(alice);
    usduToken.approve(address(stakedUSDu), 0.01 ether);
    vm.expectRevert(IStakedUSDu.MinSharesViolation.selector);
    stakedUSDu.redeem(0.5 ether, alice, alice);
  }

  function testCannotStakeWithoutApproval() public {
    uint256 amount = 100 ether;
    usduToken.mint(alice, amount);

    vm.startPrank(alice);
    vm.expectRevert("ERC20: insufficient allowance");
    stakedUSDu.deposit(amount, alice);
    vm.stopPrank();

    assertEq(usduToken.balanceOf(alice), amount);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), 0);
    assertEq(stakedUSDu.balanceOf(alice), 0);
  }

  function testStakeUnstake() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);

    assertEq(usduToken.balanceOf(alice), 0);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), amount);
    assertEq(stakedUSDu.balanceOf(alice), amount);

    _redeem(alice, amount);

    assertEq(usduToken.balanceOf(alice), amount);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), 0);
    assertEq(stakedUSDu.balanceOf(alice), 0);
  }

  function testOnlyRewarderCanReward() public {
    uint256 amount = 100 ether;
    uint256 rewardAmount = 0.5 ether;
    _mintApproveDeposit(alice, amount);

    usduToken.mint(bob, rewardAmount);
    vm.startPrank(bob);

    vm.expectRevert(
      "AccessControl: account 0x72c7a47c5d01bddf9067eabb345f5daabdead13f is missing role 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6"
    );
    stakedUSDu.transferInRewards(rewardAmount);
    vm.stopPrank();
    assertEq(usduToken.balanceOf(alice), 0);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), amount);
    assertEq(stakedUSDu.balanceOf(alice), amount);
    _assertVestedAmountIs(amount);
    assertEq(usduToken.balanceOf(bob), rewardAmount);
  }

  function testStakingAndUnstakingBeforeAfterReward() public {
    uint256 amount = 100 ether;
    uint256 rewardAmount = 100 ether;
    _mintApproveDeposit(alice, amount);
    _transferRewards(rewardAmount, rewardAmount);
    _redeem(alice, amount);
    assertEq(usduToken.balanceOf(alice), amount);
    assertEq(stakedUSDu.totalSupply(), 0);
  }

  function testFuzzNoJumpInVestedBalance(uint256 amount) public {
    vm.assume(amount > 0 && amount < 1e60);
    _transferRewards(amount, amount);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(amount / 2);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), amount);
  }

  function testOwnerCannotRescueUSDu() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);
    bytes4 selector = bytes4(keccak256("InvalidToken()"));
    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(selector));
    stakedUSDu.rescueTokens(address(usduToken), amount, owner);
  }

  function testOwnerCanRescuestUSDu() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);
    vm.prank(alice);
    stakedUSDu.transfer(address(stakedUSDu), amount);
    assertEq(stakedUSDu.balanceOf(owner), 0);
    vm.startPrank(owner);
    stakedUSDu.rescueTokens(address(stakedUSDu), amount, owner);
    assertEq(stakedUSDu.balanceOf(owner), amount);
  }

  function testOwnerCanChangeRewarder() public {
    assertTrue(stakedUSDu.hasRole(REWARDER_ROLE, address(rewarder)));
    address newRewarder = address(0x123);
    vm.startPrank(owner);
    stakedUSDu.revokeRole(REWARDER_ROLE, rewarder);
    stakedUSDu.grantRole(REWARDER_ROLE, newRewarder);
    assertTrue(!stakedUSDu.hasRole(REWARDER_ROLE, address(rewarder)));
    assertTrue(stakedUSDu.hasRole(REWARDER_ROLE, newRewarder));
    vm.stopPrank();

    usduToken.mint(rewarder, 1 ether);
    usduToken.mint(newRewarder, 1 ether);

    vm.startPrank(rewarder);
    usduToken.approve(address(stakedUSDu), 1 ether);
    vm.expectRevert(
      "AccessControl: account 0x5c664540bc6bb6b22e9d1d3d630c73c02edd94b7 is missing role 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6"
    );
    stakedUSDu.transferInRewards(1 ether);
    vm.stopPrank();

    vm.startPrank(newRewarder);
    usduToken.approve(address(stakedUSDu), 1 ether);
    stakedUSDu.transferInRewards(1 ether);
    vm.stopPrank();

    assertEq(usduToken.balanceOf(address(stakedUSDu)), 1 ether);
    assertEq(usduToken.balanceOf(rewarder), 1 ether);
    assertEq(usduToken.balanceOf(newRewarder), 0);
  }

  function testUSDuValuePerStUSDu() public {
    _mintApproveDeposit(alice, 100 ether);
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(150 ether);
    assertEq(stakedUSDu.convertToAssets(1 ether), 1.5 ether - 1);
    assertEq(stakedUSDu.totalSupply(), 100 ether);
    // rounding
    _mintApproveDeposit(bob, 75 ether);
    _assertVestedAmountIs(225 ether);
    assertEq(stakedUSDu.balanceOf(alice), 100 ether);
    assertEq(stakedUSDu.balanceOf(bob), 50 ether);
    assertEq(stakedUSDu.convertToAssets(1 ether), 1.5 ether - 1);

    vm.warp(block.timestamp + 4 hours);

    uint256 vestedAmount = 275 ether;
    _assertVestedAmountIs(vestedAmount);

    assertApproxEqAbs(stakedUSDu.convertToAssets(1 ether), (vestedAmount * 1 ether) / 150 ether, 1);

    // rounding
    _redeem(bob, stakedUSDu.balanceOf(bob));

    _redeem(alice, 100 ether);

    assertEq(stakedUSDu.balanceOf(alice), 0);
    assertEq(stakedUSDu.balanceOf(bob), 0);
    assertEq(stakedUSDu.totalSupply(), 0);

    assertApproxEqAbs(usduToken.balanceOf(alice), (vestedAmount * 2) / 3, 2);

    assertApproxEqAbs(usduToken.balanceOf(bob), vestedAmount / 3, 2);

    assertApproxEqAbs(usduToken.balanceOf(address(stakedUSDu)), 0, 1);
  }

  function testFairStakeAndUnstakePrices() public {
    uint256 aliceAmount = 100 ether;
    uint256 bobAmount = 1000 ether;
    uint256 rewardAmount = 200 ether;
    _mintApproveDeposit(alice, aliceAmount);
    _transferRewards(rewardAmount, rewardAmount);
    vm.warp(block.timestamp + 4 hours);
    _mintApproveDeposit(bob, bobAmount);
    vm.warp(block.timestamp + 4 hours);
    _redeem(alice, aliceAmount);
    _assertVestedAmountIs(bobAmount + (rewardAmount * 5) / 12);
  }

  function testFuzzFairStakeAndUnstakePrices(
    uint256 amount1,
    uint256 amount2,
    uint256 amount3,
    uint256 rewardAmount,
    uint256 waitSeconds
  ) public {
    vm.assume(
      amount1 >= 100 ether && amount2 > 0 && amount3 > 0 && rewardAmount > 0 && waitSeconds <= 9 hours
      // 100 trillion USD with 18 decimals
      && amount1 < 1e32 && amount2 < 1e32 && amount3 < 1e32 && rewardAmount < 1e32
    );

    uint256 totalContributions = amount1;

    _mintApproveDeposit(alice, amount1);

    _transferRewards(rewardAmount, rewardAmount);

    vm.warp(block.timestamp + waitSeconds);

    uint256 vestedAmount;
    if (waitSeconds > 8 hours) {
      vestedAmount = amount1 + rewardAmount;
    } else {
      vestedAmount = amount1 + rewardAmount - (rewardAmount * (8 hours - waitSeconds)) / 8 hours;
    }

    _assertVestedAmountIs(vestedAmount);

    uint256 bobStakedUSDu = (amount2 * (amount1 + 1)) / (vestedAmount + 1);
    if (bobStakedUSDu > 0) {
      _mintApproveDeposit(bob, amount2);
      totalContributions += amount2;
    }

    vm.warp(block.timestamp + waitSeconds);

    if (waitSeconds > 4 hours) {
      vestedAmount = totalContributions + rewardAmount;
    } else {
      vestedAmount = totalContributions + rewardAmount - ((4 hours - waitSeconds) * rewardAmount) / 4 hours;
    }

    _assertVestedAmountIs(vestedAmount);

    uint256 gregStakedUSDu = (amount3 * (stakedUSDu.totalSupply() + 1)) / (vestedAmount + 1);
    if (gregStakedUSDu > 0) {
      _mintApproveDeposit(greg, amount3);
      totalContributions += amount3;
    }

    vm.warp(block.timestamp + 8 hours);

    vestedAmount = totalContributions + rewardAmount;

    _assertVestedAmountIs(vestedAmount);

    uint256 usduPerStakedUSDuBefore = stakedUSDu.convertToAssets(1 ether);
    uint256 bobUnstakeAmount = (stakedUSDu.balanceOf(bob) * (vestedAmount + 1)) / (stakedUSDu.totalSupply() + 1);
    uint256 gregUnstakeAmount = (stakedUSDu.balanceOf(greg) * (vestedAmount + 1)) / (stakedUSDu.totalSupply() + 1);

    if (bobUnstakeAmount > 0) _redeem(bob, stakedUSDu.balanceOf(bob));
    uint256 usduPerStakedUSDuAfter = stakedUSDu.convertToAssets(1 ether);
    if (usduPerStakedUSDuAfter != 0) assertApproxEqAbs(usduPerStakedUSDuAfter, usduPerStakedUSDuBefore, 1 ether);

    if (gregUnstakeAmount > 0) _redeem(greg, stakedUSDu.balanceOf(greg));
    usduPerStakedUSDuAfter = stakedUSDu.convertToAssets(1 ether);
    if (usduPerStakedUSDuAfter != 0) assertApproxEqAbs(usduPerStakedUSDuAfter, usduPerStakedUSDuBefore, 1 ether);

    _redeem(alice, amount1);

    assertEq(stakedUSDu.totalSupply(), 0);
    assertApproxEqAbs(stakedUSDu.totalAssets(), 0, 10 ** 12);
  }

  function testTransferRewardsFailsInsufficientBalance() public {
    usduToken.mint(address(rewarder), 99);
    vm.startPrank(rewarder);

    usduToken.approve(address(stakedUSDu), 100);

    vm.expectRevert("ERC20: transfer amount exceeds balance");
    stakedUSDu.transferInRewards(100);
    vm.stopPrank();
  }

  function testTransferRewardsFailsZeroAmount() public {
    usduToken.mint(address(rewarder), 100);
    vm.startPrank(rewarder);

    usduToken.approve(address(stakedUSDu), 100);

    vm.expectRevert(IStakedUSDu.InvalidAmount.selector);
    stakedUSDu.transferInRewards(0);
    vm.stopPrank();
  }

  function testDecimalsIs18() public view {
    assertEq(stakedUSDu.decimals(), 18);
  }

  function testMintWithSlippageCheck(uint256 amount) public {
    amount = bound(amount, 1 ether, type(uint256).max / 2);
    usduToken.mint(alice, amount * 2);

    assertEq(stakedUSDu.balanceOf(alice), 0);

    vm.startPrank(alice);
    usduToken.approve(address(stakedUSDu), amount);
    vm.expectEmit(true, true, true, true);
    emit Deposit(alice, alice, amount, amount);
    stakedUSDu.mint(amount, alice);

    assertEq(stakedUSDu.balanceOf(alice), amount);

    usduToken.approve(address(stakedUSDu), amount);
    vm.expectEmit(true, true, true, true);
    emit Deposit(alice, alice, amount, amount);
    stakedUSDu.mint(amount, alice);

    assertEq(stakedUSDu.balanceOf(alice), amount * 2);
  }

  function testMintToDiffRecipient() public {
    usduToken.mint(alice, 1 ether);

    vm.startPrank(alice);

    usduToken.approve(address(stakedUSDu), 1 ether);

    stakedUSDu.deposit(1 ether, bob);

    assertEq(stakedUSDu.balanceOf(alice), 0);
    assertEq(stakedUSDu.balanceOf(bob), 1 ether);
  }

  function testCannotTransferRewardsWhileVesting() public {
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(50 ether);
    vm.prank(rewarder);
    vm.expectRevert(IStakedUSDu.StillVesting.selector);
    stakedUSDu.transferInRewards(100 ether);
    _assertVestedAmountIs(50 ether);
    assertEq(stakedUSDu.vestingAmount(), 100 ether);
  }

  function testCanTransferRewardsAfterVesting() public {
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 8 hours);
    _assertVestedAmountIs(100 ether);
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 8 hours);
    _assertVestedAmountIs(200 ether);
  }

  function testDonationAttack() public {
    uint256 initialStake = 1 ether;
    uint256 donationAmount = 10_000_000_000 ether;
    uint256 bobStake = 100 ether;
    _mintApproveDeposit(alice, initialStake);
    assertEq(stakedUSDu.totalSupply(), initialStake);
    usduToken.mint(alice, donationAmount);
    vm.prank(alice);
    usduToken.transfer(address(stakedUSDu), donationAmount);
    assertEq(stakedUSDu.totalSupply(), initialStake);
    assertEq(usduToken.balanceOf(address(stakedUSDu)), initialStake + donationAmount);
    _mintApproveDeposit(bob, bobStake);
    uint256 bobStUSDuBal = stakedUSDu.balanceOf(bob);
    uint256 bobStUSDuExpectedBal = (bobStake * initialStake) / (initialStake + donationAmount);
    assertApproxEqAbs(bobStUSDuBal, bobStUSDuExpectedBal, 1e9);
    assertTrue(bobStUSDuBal > 0);
  }
}
