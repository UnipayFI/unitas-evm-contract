// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable func-name-mixedcase  */

import "./MintingBaseSetup.sol";
import "forge-std/console.sol";

// These functions are reused across multiple files
contract UnitasMintingUtils is MintingBaseSetup {
  function maxMint_perBlock_exceeded_revert(uint256 excessiveMintAmount) public {
    // This amount is always greater than the allowed max mint per block
    vm.assume(excessiveMintAmount > UnitasMintingContract.maxMintPerBlock());
    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(excessiveMintAmount, _stETHToDeposit, 1, false);

    vm.prank(minter);
    vm.expectRevert(MaxMintPerBlockExceeded);
    UnitasMintingContract.mint(order, route, takerSignature);

    assertEq(usduToken.balanceOf(beneficiary), 0, "The beneficiary balance should be 0");
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0, "The unitas minting stETH balance should be 0");
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in stETH balance");
  }

  function maxRedeem_perBlock_exceeded_revert(uint256 excessiveRedeemAmount) public {
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

  function executeMint() public {
    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
  }

  function executeRedeem() public {
    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(_usduToMint, _stETHToDeposit, 1, false);
    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);
  }
}
