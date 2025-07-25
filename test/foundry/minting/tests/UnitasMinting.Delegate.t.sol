// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../UnitasMinting.utils.sol";

contract UnitasMintingDelegateTest is UnitasMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function testDelegateSuccessfulMint() public {
    (IUnitasMinting.Order memory order,, IUnitasMinting.Route memory route) =
      mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.prank(benefactor);
    UnitasMintingContract.setDelegatedSigner(trader2);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMinting.Signature memory trader2Sig =
      signOrder(trader2PrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), _usduToMint, "Mismatch in beneficiary USDu balance after mint");
  }

  function testDelegateFailureMint() public {
    (IUnitasMinting.Order memory order,, IUnitasMinting.Route memory route) =
      mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    // omit delegation by benefactor

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMinting.Signature memory trader2Sig =
      signOrder(trader2PrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(minter);
    vm.expectRevert(InvalidSignature);
    UnitasMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }

  function testDelegateSuccessfulRedeem() public {
    (IUnitasMinting.Order memory order,) = redeem_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.prank(beneficiary);
    UnitasMintingContract.setDelegatedSigner(trader2);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMinting.Signature memory trader2Sig =
      signOrder(trader2PrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), _usduToMint, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(redeemer);
    UnitasMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }

  function testDelegateFailureRedeem() public {
    (IUnitasMinting.Order memory order,) = redeem_setup(_usduToMint, _stETHToDeposit, 1, false);

    // omit delegation by beneficiary

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMinting.Signature memory trader2Sig =
      signOrder(trader2PrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), _usduToMint, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(redeemer);
    vm.expectRevert(InvalidSignature);
    UnitasMintingContract.redeem(order, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), _usduToMint, "Mismatch in beneficiary USDu balance after mint");
  }

  function testCanUndelegate() public {
    (IUnitasMinting.Order memory order,, IUnitasMinting.Route memory route) =
      mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    // delegate and then undelegate
    vm.startPrank(benefactor);
    UnitasMintingContract.setDelegatedSigner(trader2);
    UnitasMintingContract.removeDelegatedSigner(trader2);
    vm.stopPrank();

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMinting.Signature memory trader2Sig =
      signOrder(trader2PrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(minter);
    vm.expectRevert(InvalidSignature);
    UnitasMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }
}
