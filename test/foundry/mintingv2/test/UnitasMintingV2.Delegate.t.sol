// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../UnitasMintingV2.utils.sol";

contract UnitasMintingV2DelegateTest is UnitasMintingV2Utils {
  function setUp() public override {
    super.setUp();
  }

  function testDelegateSuccessfulMint() public {
    (IUnitasMintingV2.Order memory order, , IUnitasMintingV2.Route memory route) = mint_setup(
      _usduToMint,
      _stETHToDeposit,
      stETHToken,
      1,
      false
    );

    // request delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    UnitasMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    UnitasMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUnitasMintingV2.Signature memory trader2Sig = signOrder(
      trader2PrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance before mint"
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
    (IUnitasMintingV2.Order memory order, , IUnitasMintingV2.Route memory route) = mint_setup(
      _usduToMint,
      _stETHToDeposit,
      stETHToken,
      1,
      false
    );

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectRevert(IUnitasMintingV2.DelegationNotInitiated.selector);
    UnitasMintingContract.confirmDelegatedSigner(benefactor);

    vm.prank(trader2);
    IUnitasMintingV2.Signature memory trader2Sig = signOrder(
      trader2PrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(minter, trader2)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    UnitasMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }

  function testDelegateSuccessfulRedeem() public {
    (IUnitasMintingV2.Order memory order, ) = redeem_setup(_usduToMint, _stETHToDeposit, stETHToken, 1, false);

    // request delegation
    vm.prank(beneficiary);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, beneficiary);
    UnitasMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);

    // accept delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, beneficiary);
    UnitasMintingContract.confirmDelegatedSigner(beneficiary);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, beneficiary)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    IUnitasMintingV2.Signature memory trader2Sig = signOrder(
      trader2PrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );

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
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }

  function testDelegateFailureRedeem() public {
    (IUnitasMintingV2.Order memory order, ) = redeem_setup(_usduToMint, _stETHToDeposit, stETHToken, 1, false);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMintingV2.Signature memory trader2Sig = signOrder(
      trader2PrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      _stETHToDeposit,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), _usduToMint, "Mismatch in beneficiary USDu balance before mint");

    // assert that the delegation is rejected
    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(redeemer, trader2)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.REJECTED),
      "The delegation status should be rejected"
    );

    vm.prank(redeemer);
    vm.expectRevert(InvalidEIP712Signature);
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
    (IUnitasMintingV2.Order memory order, , IUnitasMintingV2.Route memory route) = mint_setup(
      _usduToMint,
      _stETHToDeposit,
      stETHToken,
      1,
      false
    );

    // delegate request
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerInitiated(trader2, benefactor);
    UnitasMintingContract.setDelegatedSigner(trader2);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.PENDING),
      "The delegation status should be pending"
    );

    // accept the delegation
    vm.prank(trader2);
    vm.expectEmit();
    emit DelegatedSignerAdded(trader2, benefactor);
    UnitasMintingContract.confirmDelegatedSigner(benefactor);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.ACCEPTED),
      "The delegation status should be accepted"
    );

    // remove the delegation
    vm.prank(benefactor);
    vm.expectEmit();
    emit DelegatedSignerRemoved(trader2, benefactor);
    UnitasMintingContract.removeDelegatedSigner(trader2);

    assertEq(
      uint256(UnitasMintingContract.delegatedSigner(trader2, benefactor)),
      uint256(IUnitasMintingV2.DelegatedSignerStatus.REJECTED),
      "The delegation status should be accepted"
    );

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    vm.prank(trader2);
    IUnitasMintingV2.Signature memory trader2Sig = signOrder(
      trader2PrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance before mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in benefactor stETH balance before mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance before mint");

    vm.prank(minter);
    vm.expectRevert(InvalidEIP712Signature);
    UnitasMintingContract.mint(order, route, trader2Sig);

    assertEq(
      stETHToken.balanceOf(address(UnitasMintingContract)),
      0,
      "Mismatch in Minting contract stETH balance after mint"
    );
    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit, "Mismatch in beneficiary stETH balance after mint");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in beneficiary USDu balance after mint");
  }
}
