// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMinting.utils.sol";

contract UnitasMintingBlockLimitsTest is UnitasMintingUtils {
  /**
   * Max mint per block tests
   */

  // Ensures that the minted per block amount raises accordingly
  // when multiple mints are performed
  function test_multiple_mints() public {
    uint256 maxMintAmount = UnitasMintingContract.maxMintPerBlock();
    uint256 firstMintAmount = maxMintAmount / 4;
    uint256 secondMintAmount = maxMintAmount / 2;
    (
      IUnitasMinting.Order memory aOrder,
      IUnitasMinting.Signature memory aTakerSignature,
      IUnitasMinting.Route memory aRoute
    ) = mint_setup(firstMintAmount, _stETHToDeposit, 1, false);

    vm.prank(minter);
    UnitasMintingContract.mint(aOrder, aRoute, aTakerSignature);

    vm.prank(owner);
    stETHToken.mint(_stETHToDeposit, benefactor);

    (
      IUnitasMinting.Order memory bOrder,
      IUnitasMinting.Signature memory bTakerSignature,
      IUnitasMinting.Route memory bRoute
    ) = mint_setup(secondMintAmount, _stETHToDeposit, 2, true);
    vm.prank(minter);
    UnitasMintingContract.mint(bOrder, bRoute, bTakerSignature);

    assertEq(
      UnitasMintingContract.mintedPerBlock(block.number), firstMintAmount + secondMintAmount, "Incorrect minted amount"
    );
    assertTrue(
      UnitasMintingContract.mintedPerBlock(block.number) < maxMintAmount, "Mint amount exceeded without revert"
    );
  }

  function test_fuzz_maxMint_perBlock_exceeded_revert(uint256 excessiveMintAmount) public {
    // This amount is always greater than the allowed max mint per block
    vm.assume(excessiveMintAmount > UnitasMintingContract.maxMintPerBlock());

    maxMint_perBlock_exceeded_revert(excessiveMintAmount);
  }

  function test_fuzz_mint_maxMint_perBlock_exceeded_revert(uint256 excessiveMintAmount) public {
    vm.assume(excessiveMintAmount > UnitasMintingContract.maxMintPerBlock());
    (
      IUnitasMinting.Order memory mintOrder,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(excessiveMintAmount, _stETHToDeposit, 1, false);

    // maker
    vm.startPrank(minter);
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usduToken.balanceOf(beneficiary), 0);

    vm.expectRevert(MaxMintPerBlockExceeded);
    // minter passes in permit signature data
    UnitasMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(
      stETHToken.balanceOf(benefactor),
      _stETHToDeposit,
      "The benefactor stEth balance should be the same as the minted stEth"
    );
    assertEq(usduToken.balanceOf(beneficiary), 0, "The beneficiary USDu balance should be 0");
  }

  function test_fuzz_nextBlock_mint_is_zero(uint256 mintAmount) public {
    vm.assume(mintAmount < UnitasMintingContract.maxMintPerBlock() && mintAmount > 0);
    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    vm.roll(block.number + 1);

    assertEq(
      UnitasMintingContract.mintedPerBlock(block.number), 0, "The minted amount should reset to 0 in the next block"
    );
  }

  function test_fuzz_maxMint_perBlock_setter(uint256 newMaxMintPerBlock) public {
    vm.assume(newMaxMintPerBlock > 0);

    uint256 oldMaxMintPerBlock = UnitasMintingContract.maxMintPerBlock();

    vm.prank(owner);
    vm.expectEmit();
    emit MaxMintPerBlockChanged(oldMaxMintPerBlock, newMaxMintPerBlock);

    UnitasMintingContract.setMaxMintPerBlock(newMaxMintPerBlock);

    assertEq(UnitasMintingContract.maxMintPerBlock(), newMaxMintPerBlock, "The max mint per block setter failed");
  }

  /**
   * Max redeem per block tests
   */

  // Ensures that the redeemed per block amount raises accordingly
  // when multiple mints are performed
  function test_multiple_redeem() public {
    uint256 maxRedeemAmount = UnitasMintingContract.maxRedeemPerBlock();
    uint256 firstRedeemAmount = maxRedeemAmount / 4;
    uint256 secondRedeemAmount = maxRedeemAmount / 2;

    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(firstRedeemAmount, _stETHToDeposit, 1, false);

    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    vm.prank(owner);
    stETHToken.mint(_stETHToDeposit, benefactor);

    (IUnitasMinting.Order memory bRedeemOrder, IUnitasMinting.Signature memory bTakerSignature2) =
      redeem_setup(secondRedeemAmount, _stETHToDeposit, 2, true);

    vm.prank(redeemer);
    UnitasMintingContract.redeem(bRedeemOrder, bTakerSignature2);

    assertEq(
      UnitasMintingContract.mintedPerBlock(block.number),
      firstRedeemAmount + secondRedeemAmount,
      "Incorrect minted amount"
    );
    assertTrue(
      UnitasMintingContract.redeemedPerBlock(block.number) < maxRedeemAmount, "Redeem amount exceeded without revert"
    );
  }

  function test_fuzz_maxRedeem_perBlock_exceeded_revert(uint256 excessiveRedeemAmount) public {
    // This amount is always greater than the allowed max redeem per block
    vm.assume(excessiveRedeemAmount > UnitasMintingContract.maxRedeemPerBlock());

    // Set the max mint per block to the same value as the max redeem in order to get to the redeem
    vm.prank(owner);
    UnitasMintingContract.setMaxMintPerBlock(excessiveRedeemAmount);

    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(excessiveRedeemAmount, _stETHToDeposit, 1, false);

    vm.startPrank(redeemer);
    vm.expectRevert(MaxRedeemPerBlockExceeded);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit, "Mismatch in stETH balance");
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in stETH balance");
    assertEq(usduToken.balanceOf(beneficiary), excessiveRedeemAmount, "Mismatch in USDu balance");

    vm.stopPrank();
  }

  function test_fuzz_nextBlock_redeem_is_zero(uint256 redeemAmount) public {
    vm.assume(redeemAmount < UnitasMintingContract.maxRedeemPerBlock() && redeemAmount > 0);
    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(redeemAmount, _stETHToDeposit, 1, false);

    vm.startPrank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    vm.roll(block.number + 1);

    assertEq(
      UnitasMintingContract.redeemedPerBlock(block.number), 0, "The redeemed amount should reset to 0 in the next block"
    );
    vm.stopPrank();
  }

  function test_fuzz_maxRedeem_perBlock_setter(uint256 newMaxRedeemPerBlock) public {
    vm.assume(newMaxRedeemPerBlock > 0);

    uint256 oldMaxRedeemPerBlock = UnitasMintingContract.maxMintPerBlock();

    vm.prank(owner);
    vm.expectEmit();
    emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, newMaxRedeemPerBlock);
    UnitasMintingContract.setMaxRedeemPerBlock(newMaxRedeemPerBlock);

    assertEq(UnitasMintingContract.maxRedeemPerBlock(), newMaxRedeemPerBlock, "The max redeem per block setter failed");
  }
}
