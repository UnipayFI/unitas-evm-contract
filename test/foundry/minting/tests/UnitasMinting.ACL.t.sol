// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMinting.utils.sol";
import "../../../../contracts/interfaces/ISingleAdminAccessControl.sol";

contract UnitasMintingACLTest is UnitasMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_role_authorization() public {
    vm.deal(trader1, 1 ether);
    vm.deal(maker1, 1 ether);
    vm.deal(maker2, 1 ether);
    vm.startPrank(minter);
    stETHToken.mint(1 * 1e18, maker1);
    stETHToken.mint(1 * 1e18, trader1);
    vm.expectRevert(OnlyMinterErr);
    usduToken.mint(address(maker2), 2000 * 1e18);
    vm.expectRevert(OnlyMinterErr);
    usduToken.mint(address(trader2), 2000 * 1e18);
  }

  function test_redeem_notRedeemer_revert() public {
    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.startPrank(minter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(minter), " is missing role ", vm.toString(redeemerRole)
        )
      )
    );
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);
  }

  function test_fuzz_notMinter_cannot_mint(address nonMinter) public {
    (
      IUnitasMinting.Order memory mintOrder,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.assume(nonMinter != minter);
    vm.startPrank(nonMinter);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(nonMinter), " is missing role ", vm.toString(minterRole)
        )
      )
    );
    UnitasMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usduToken.balanceOf(beneficiary), 0);
  }

  function test_fuzz_nonOwner_cannot_add_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.expectRevert();
    vm.prank(nonOwner);
    UnitasMintingContract.addSupportedAsset(asset);
    assertFalse(UnitasMintingContract.isSupportedAsset(asset));
  }

  function test_fuzz_nonOwner_cannot_remove_supportedAsset_revert(address nonOwner) public {
    vm.assume(nonOwner != owner);
    address asset = address(20);
    vm.prank(owner);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    UnitasMintingContract.addSupportedAsset(asset);
    assertTrue(UnitasMintingContract.isSupportedAsset(asset));

    vm.expectRevert();
    vm.prank(nonOwner);
    UnitasMintingContract.removeSupportedAsset(asset);
    assertTrue(UnitasMintingContract.isSupportedAsset(asset));
  }

  function test_minter_canTransfer_custody() public {
    vm.startPrank(owner);
    stETHToken.mint(1000, address(UnitasMintingContract));
    UnitasMintingContract.addCustodianAddress(beneficiary);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectEmit(true, true, true, true);
    emit CustodyTransfer(beneficiary, address(stETHToken), 1000);
    UnitasMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
    assertEq(stETHToken.balanceOf(beneficiary), 1000);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0);
  }

  function test_fuzz_nonMinter_cannot_transferCustody_revert(address nonMinter) public {
    vm.assume(nonMinter != minter);
    stETHToken.mint(1000, address(UnitasMintingContract));

    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(nonMinter), " is missing role ", vm.toString(minterRole)
        )
      )
    );
    vm.prank(nonMinter);
    UnitasMintingContract.transferToCustody(beneficiary, address(stETHToken), 1000);
  }

  /**
   * Gatekeeper tests
   */
  function test_gatekeeper_can_remove_minter() public {
    vm.prank(gatekeeper);

    UnitasMintingContract.removeMinterRole(minter);
    assertFalse(UnitasMintingContract.hasRole(minterRole, minter));
  }

  function test_gatekeeper_can_remove_redeemer() public {
    vm.prank(gatekeeper);

    UnitasMintingContract.removeRedeemerRole(redeemer);
    assertFalse(UnitasMintingContract.hasRole(redeemerRole, redeemer));
  }

  function test_fuzz_not_gatekeeper_cannot_remove_minter_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UnitasMintingContract.removeMinterRole(minter);
    assertTrue(UnitasMintingContract.hasRole(minterRole, minter));
  }

  function test_fuzz_not_gatekeeper_cannot_remove_redeemer_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UnitasMintingContract.removeRedeemerRole(redeemer);
    assertTrue(UnitasMintingContract.hasRole(redeemerRole, redeemer));
  }

  function test_gatekeeper_cannot_add_minters_revert() public {
    vm.startPrank(gatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(gatekeeper), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.grantRole(minterRole, bob);
    assertFalse(UnitasMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
  }

  function test_gatekeeper_can_disable_mintRedeem() public {
    vm.startPrank(gatekeeper);
    UnitasMintingContract.disableMintRedeem();

    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.prank(minter);
    vm.expectRevert(MaxMintPerBlockExceeded);
    UnitasMintingContract.mint(order, route, takerSignature);

    vm.prank(redeemer);
    vm.expectRevert(MaxRedeemPerBlockExceeded);
    UnitasMintingContract.redeem(order, takerSignature);

    assertEq(UnitasMintingContract.maxMintPerBlock(), 0, "Minting should be disabled");
    assertEq(UnitasMintingContract.maxRedeemPerBlock(), 0, "Redeeming should be disabled");
  }

  // Ensure that the gatekeeper is not allowed to enable/modify the minting
  function test_gatekeeper_cannot_enable_mint_revert() public {
    test_fuzz_nonAdmin_cannot_enable_mint_revert(gatekeeper);
  }

  // Ensure that the gatekeeper is not allowed to enable/modify the redeeming
  function test_gatekeeper_cannot_enable_redeem_revert() public {
    test_fuzz_nonAdmin_cannot_enable_redeem_revert(gatekeeper);
  }

  function test_fuzz_not_gatekeeper_cannot_disable_mintRedeem_revert(address notGatekeeper) public {
    vm.assume(notGatekeeper != gatekeeper);
    vm.startPrank(notGatekeeper);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ",
          Strings.toHexString(notGatekeeper),
          " is missing role ",
          vm.toString(gatekeeperRole)
        )
      )
    );
    UnitasMintingContract.disableMintRedeem();

    assertTrue(UnitasMintingContract.maxMintPerBlock() > 0);
    assertTrue(UnitasMintingContract.maxRedeemPerBlock() > 0);
  }

  /**
   * Admin tests
   */
  function test_admin_can_disable_mint(bool performCheckMint) public {
    vm.prank(owner);
    UnitasMintingContract.setMaxMintPerBlock(0);

    if (performCheckMint) maxMint_perBlock_exceeded_revert(1e18);

    assertEq(UnitasMintingContract.maxMintPerBlock(), 0, "The minting should be disabled");
  }

  function test_admin_can_disable_redeem(bool performCheckRedeem) public {
    vm.prank(owner);
    UnitasMintingContract.setMaxRedeemPerBlock(0);

    if (performCheckRedeem) maxRedeem_perBlock_exceeded_revert(1e18);

    assertEq(UnitasMintingContract.maxRedeemPerBlock(), 0, "The redeem should be disabled");
  }

  function test_admin_can_enable_mint() public {
    vm.startPrank(owner);
    UnitasMintingContract.setMaxMintPerBlock(0);

    assertEq(UnitasMintingContract.maxMintPerBlock(), 0, "The minting should be disabled");

    // Re-enable the minting
    UnitasMintingContract.setMaxMintPerBlock(_maxMintPerBlock);

    vm.stopPrank();

    executeMint();

    assertTrue(UnitasMintingContract.maxMintPerBlock() > 0, "The minting should be enabled");
  }

  function test_fuzz_nonAdmin_cannot_enable_mint_revert(address notAdmin) public {
    vm.assume(notAdmin != owner);

    test_admin_can_disable_mint(false);

    vm.prank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.setMaxMintPerBlock(_maxMintPerBlock);

    maxMint_perBlock_exceeded_revert(1e18);

    assertEq(UnitasMintingContract.maxMintPerBlock(), 0, "The minting should remain disabled");
  }

  function test_fuzz_nonAdmin_cannot_enable_redeem_revert(address notAdmin) public {
    vm.assume(notAdmin != owner);

    test_admin_can_disable_redeem(false);

    vm.prank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock);

    maxRedeem_perBlock_exceeded_revert(1e18);

    assertEq(UnitasMintingContract.maxRedeemPerBlock(), 0, "The redeeming should remain disabled");
  }

  function test_admin_can_enable_redeem() public {
    vm.startPrank(owner);
    UnitasMintingContract.setMaxRedeemPerBlock(0);

    assertEq(UnitasMintingContract.maxRedeemPerBlock(), 0, "The redeem should be disabled");

    // Re-enable the redeeming
    UnitasMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock);

    vm.stopPrank();

    executeRedeem();

    assertTrue(UnitasMintingContract.maxRedeemPerBlock() > 0, "The redeeming should be enabled");
  }

  function test_admin_can_add_minter() public {
    vm.startPrank(owner);
    UnitasMintingContract.grantRole(minterRole, bob);

    assertTrue(UnitasMintingContract.hasRole(minterRole, bob), "Bob should have the minter role");
    vm.stopPrank();
  }

  function test_admin_can_remove_minter() public {
    test_admin_can_add_minter();

    vm.startPrank(owner);
    UnitasMintingContract.revokeRole(minterRole, bob);

    assertFalse(UnitasMintingContract.hasRole(minterRole, bob), "Bob should no longer have the minter role");

    vm.stopPrank();
  }

  function test_admin_can_add_gatekeeper() public {
    vm.startPrank(owner);
    UnitasMintingContract.grantRole(gatekeeperRole, bob);

    assertTrue(UnitasMintingContract.hasRole(gatekeeperRole, bob), "Bob should have the gatekeeper role");
    vm.stopPrank();
  }

  function test_admin_can_remove_gatekeeper() public {
    test_admin_can_add_gatekeeper();

    vm.startPrank(owner);
    UnitasMintingContract.revokeRole(gatekeeperRole, bob);

    assertFalse(UnitasMintingContract.hasRole(gatekeeperRole, bob), "Bob should no longer have the gatekeeper role");

    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_remove_minter(address notAdmin) public {
    test_admin_can_add_minter();

    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.revokeRole(minterRole, bob);

    assertTrue(UnitasMintingContract.hasRole(minterRole, bob), "Bob should maintain the minter role");
    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_remove_gatekeeper(address notAdmin) public {
    test_admin_can_add_gatekeeper();

    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.revokeRole(gatekeeperRole, bob);

    assertTrue(UnitasMintingContract.hasRole(gatekeeperRole, bob), "Bob should maintain the gatekeeper role");

    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_add_minter(address notAdmin) public {
    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.grantRole(minterRole, bob);

    assertFalse(UnitasMintingContract.hasRole(minterRole, bob), "Bob should lack the minter role");
    vm.stopPrank();
  }

  function test_fuzz_notAdmin_cannot_add_gatekeeper(address notAdmin) public {
    vm.assume(notAdmin != owner);
    vm.startPrank(notAdmin);
    vm.expectRevert(
      bytes(
        string.concat(
          "AccessControl: account ", Strings.toHexString(notAdmin), " is missing role ", vm.toString(adminRole)
        )
      )
    );
    UnitasMintingContract.grantRole(gatekeeperRole, bob);

    assertFalse(UnitasMintingContract.hasRole(gatekeeperRole, bob), "Bob should lack the gatekeeper role");

    vm.stopPrank();
  }

  function test_base_transferAdmin() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, newOwner));

    vm.prank(newOwner);
    UnitasMintingContract.acceptAdmin();
    assertFalse(UnitasMintingContract.hasRole(adminRole, owner));
    assertTrue(UnitasMintingContract.hasRole(adminRole, newOwner));
  }

  function test_transferAdmin_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert();
    UnitasMintingContract.transferAdmin(randomer);
  }

  function test_grantRole_AdminRoleExternally() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UnitasMintingContract.grantRole(adminRole, randomer);
    vm.stopPrank();
  }

  function test_revokeRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(
      "AccessControl: account 0xc91041eae7bf78e1040f4abd7b29908651f45546 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UnitasMintingContract.revokeRole(adminRole, owner);
  }

  function test_revokeRole_AdminRole() public {
    vm.startPrank(owner);
    vm.expectRevert();
    UnitasMintingContract.revokeRole(adminRole, owner);
  }

  function test_renounceRole_notAdmin() public {
    vm.startPrank(randomer);
    vm.expectRevert(InvalidAdminChange);
    UnitasMintingContract.renounceRole(adminRole, owner);
  }

  function test_renounceRole_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    UnitasMintingContract.renounceRole(adminRole, owner);
  }

  function test_revoke_AdminRole() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAdminChange);
    UnitasMintingContract.revokeRole(adminRole, owner);
  }

  function test_grantRole_nonAdminRole() public {
    vm.prank(owner);
    UnitasMintingContract.grantRole(minterRole, randomer);
    assertTrue(UnitasMintingContract.hasRole(minterRole, randomer));
  }

  function test_revokeRole_nonAdminRole() public {
    vm.startPrank(owner);
    UnitasMintingContract.grantRole(minterRole, randomer);
    UnitasMintingContract.revokeRole(minterRole, randomer);
    vm.stopPrank();
    assertFalse(UnitasMintingContract.hasRole(minterRole, randomer));
  }

  function test_renounceRole_nonAdminRole() public {
    vm.prank(owner);
    UnitasMintingContract.grantRole(minterRole, randomer);
    vm.prank(randomer);
    UnitasMintingContract.renounceRole(minterRole, randomer);
    assertFalse(UnitasMintingContract.hasRole(minterRole, randomer));
  }

  function testCanRepeatedlyTransferAdmin() public {
    vm.startPrank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    UnitasMintingContract.transferAdmin(randomer);
    vm.stopPrank();
  }

  function test_renounceRole_forDifferentAccount() public {
    vm.prank(randomer);
    vm.expectRevert("AccessControl: can only renounce roles for self");
    UnitasMintingContract.renounceRole(minterRole, owner);
  }

  function testCancelTransferAdmin() public {
    vm.startPrank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    UnitasMintingContract.transferAdmin(address(0));
    vm.stopPrank();
    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, address(0)));
    assertFalse(UnitasMintingContract.hasRole(adminRole, newOwner));
  }

  function test_admin_cannot_transfer_self() public {
    vm.startPrank(owner);
    vm.expectRevert(InvalidAdminChange);
    UnitasMintingContract.transferAdmin(owner);
    vm.stopPrank();
    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
  }

  function testAdminCanCancelTransfer() public {
    vm.startPrank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    UnitasMintingContract.transferAdmin(address(0));
    vm.stopPrank();

    vm.prank(newOwner);
    vm.expectRevert(ISingleAdminAccessControl.NotPendingAdmin.selector);
    UnitasMintingContract.acceptAdmin();

    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, address(0)));
    assertFalse(UnitasMintingContract.hasRole(adminRole, newOwner));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.startPrank(owner);
    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    UnitasMintingContract.renounceRole(adminRole, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    UnitasMintingContract.revokeRole(adminRole, owner);
    vm.stopPrank();
    assertEq(UnitasMintingContract.owner(), owner);
    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    assertEq(UnitasMintingContract.owner(), owner);
    assertTrue(UnitasMintingContract.hasRole(adminRole, owner));
    assertNotEq(UnitasMintingContract.owner(), newOwner);
    assertFalse(UnitasMintingContract.hasRole(adminRole, newOwner));
  }

  function testCanTransferOwnership() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UnitasMintingContract.acceptAdmin();
    assertTrue(UnitasMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, owner));
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    vm.startPrank(newOwner);
    UnitasMintingContract.acceptAdmin();
    UnitasMintingContract.grantRole(gatekeeperRole, bob);
    vm.stopPrank();
    assertTrue(UnitasMintingContract.hasRole(adminRole, newOwner));
    assertTrue(UnitasMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantPerformOwnerActions() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UnitasMintingContract.acceptAdmin();
    assertTrue(UnitasMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UnitasMintingContract.grantRole(gatekeeperRole, bob);
    assertFalse(UnitasMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(owner);
    UnitasMintingContract.transferAdmin(newOwner);
    vm.prank(newOwner);
    UnitasMintingContract.acceptAdmin();
    assertTrue(UnitasMintingContract.hasRole(adminRole, newOwner));
    assertFalse(UnitasMintingContract.hasRole(adminRole, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    UnitasMintingContract.transferAdmin(bob);
    assertFalse(UnitasMintingContract.hasRole(adminRole, bob));
  }

  function testNonAdminCanRenounceRoles() public {
    vm.prank(owner);
    UnitasMintingContract.grantRole(gatekeeperRole, bob);
    assertTrue(UnitasMintingContract.hasRole(gatekeeperRole, bob));

    vm.prank(bob);
    UnitasMintingContract.renounceRole(gatekeeperRole, bob);
    assertFalse(UnitasMintingContract.hasRole(gatekeeperRole, bob));
  }

  function testCorrectInitConfig() public {
    UnitasMinting unitasMinting2 =
      new UnitasMinting(IUSDu(address(usduToken)), assets, custodians, randomer, _maxMintPerBlock, _maxRedeemPerBlock);
    assertFalse(unitasMinting2.hasRole(adminRole, owner));
    assertNotEq(unitasMinting2.owner(), owner);
    assertTrue(unitasMinting2.hasRole(adminRole, randomer));
    assertEq(unitasMinting2.owner(), randomer);
  }
}
