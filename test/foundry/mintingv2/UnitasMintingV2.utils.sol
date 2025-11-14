// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "forge-std/console.sol";
import "./UnitasMintingV2BaseSetup.sol";

// These functions are reused across multiple files
contract UnitasMintingV2Utils is UnitasMintingV2BaseSetup {
  function maxMint_perBlock_exceeded_revert(uint128 excessiveMintAmount) public {
    // This amount is always greater than the allowed max mint per block
    (, , uint128 maxMintPerBlock, ) = UnitasMintingContract.tokenConfig(address(stETHToken));

    vm.assume(excessiveMintAmount > (maxMintPerBlock));
    (
      IUnitasMintingV2.Order memory order,
      IUnitasMintingV2.Signature memory takerSignature,
      IUnitasMintingV2.Route memory route
    ) = mint_setup(excessiveMintAmount, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    vm.expectRevert(MaxMintPerBlockExceeded);
    UnitasMintingContract.mint(order, route, takerSignature);

    assertEq(usduToken.balanceOf(beneficiary), 0, "The beneficiary balance should be 0");
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0, "The usdu minting stETH balance should be 0");
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in stETH balance");
  }

  function maxRedeem_perBlock_exceeded_revert(uint128 excessiveRedeemAmount) public {
    // Set the max mint per block to the same value as the max redeem in order to get to the redeem
    vm.prank(owner);
    UnitasMintingContract.setMaxMintPerBlock(excessiveRedeemAmount, address(stETHToken));

    (IUnitasMintingV2.Order memory redeemOrder, IUnitasMintingV2.Signature memory takerSignature2) = redeem_setup(
      excessiveRedeemAmount,
      _stETHToDeposit,
      stETHToken,
      1,
      false
    );

    vm.startPrank(redeemer);
    vm.expectRevert(MaxRedeemPerBlockExceeded);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit, "Mismatch in stETH balance");
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in stETH balance");
    assertEq(usduToken.balanceOf(beneficiary), excessiveRedeemAmount, "Mismatch in USDu balance");

    vm.stopPrank();
  }

  function executeMint(IERC20 collateralAsset) public {
    (
      IUnitasMintingV2.Order memory order,
      IUnitasMintingV2.Signature memory takerSignature,
      IUnitasMintingV2.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, collateralAsset, 1, false);

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
  }

  function executeRedeem(IERC20 collateralAsset) public {
    (IUnitasMintingV2.Order memory redeemOrder, IUnitasMintingV2.Signature memory takerSignature2) = redeem_setup(
      _usduToMint,
      _stETHToDeposit,
      collateralAsset,
      1,
      false
    );
    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);
  }
}
