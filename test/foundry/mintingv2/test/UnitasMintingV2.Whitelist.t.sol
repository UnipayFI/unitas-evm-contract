// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMintingV2.utils.sol";

contract UnitasMintingV2WhitelistTest is UnitasMintingV2Utils {
  function setUp() public override {
    super.setUp();
    vm.deal(benefactor, _stETHToDeposit);
  }

  function generate_nonce() public view returns (uint120) {
    return uint120(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))));
  }

  function test_whitelist_mint() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint / 2
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      benefactorPrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.prank(owner);
    UnitasMintingContract.removeWhitelistedBenefactor(benefactor);

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    vm.prank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(benefactor);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit);
    assertEq(usduToken.balanceOf(address(beneficiary)), _usduToMint / 2);
  }

  function test_whitelist_redeem() public {
    (
      IUnitasMintingV2.Order memory mintOrder,
      IUnitasMintingV2.Signature memory sig,
      IUnitasMintingV2.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, stETHToken, 1, false);

    vm.prank(minter);
    UnitasMintingContract.mint(mintOrder, route, sig);

    IUnitasMintingV2.Order memory redeemOrder = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 47,
      benefactor: beneficiary,
      beneficiary: benefactor, // switched
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    // taker
    vm.startPrank(beneficiary);
    usduToken.approve(address(UnitasMintingContract), _usduToMint);

    bytes32 redeemDigest = UnitasMintingContract.hashOrder(redeemOrder);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      beneficiaryPrivateKey,
      redeemDigest,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.startPrank(owner);
    vm.expectRevert(InvalidAddress);
    UnitasMintingContract.removeWhitelistedBenefactor(owner);

    UnitasMintingContract.removeWhitelistedBenefactor(beneficiary);
    vm.stopPrank();

    vm.expectRevert(BenefactorNotWhitelisted);
    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature);

    vm.prank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(beneficiary);
    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature);

    assertEq(stETHToken.balanceOf(address(benefactor)), _stETHToDeposit);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0);
    assertEq(usduToken.balanceOf(address(beneficiary)), 0);
  }

  function test_non_whitelisted_beneficiary_mint() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: generate_nonce(),
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint / 2
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      benefactorPrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.expectRevert(BeneficiaryNotApproved);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    vm.prank(benefactor);
    UnitasMintingContract.setApprovedBeneficiary(owner, true);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    // assert balances
    assertEq(stETHToken.balanceOf(address(benefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit);
    assertEq(usduToken.balanceOf(address(owner)), _usduToMint / 2);
  }

  function test_non_whitelisted_beneficiary_redeem() public {
    vm.prank(benefactor);
    UnitasMintingContract.setApprovedBeneficiary(owner, true);
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      usdu_amount: _usduToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    vm.startPrank(benefactor);
    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      benefactorPrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );
    IERC20(address(stETHToken)).approve(address(UnitasMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    IUnitasMintingV2.Order memory redeemOrder = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    // taker
    vm.startPrank(owner);
    usduToken.approve(address(UnitasMintingContract), _usduToMint);

    bytes32 redeemDigest = UnitasMintingContract.hashOrder(redeemOrder);
    IUnitasMintingV2.Signature memory redeemTakerSignature = signOrder(
      ownerPrivateKey,
      redeemDigest,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UnitasMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }

  function test_whitelisted_beneficiary_whitelist_enabled_transfer_redeem() public {
    vm.prank(benefactor);
    UnitasMintingContract.setApprovedBeneficiary(owner, true);
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 3423423,
      benefactor: benefactor,
      beneficiary: owner,
      collateral_asset: address(stETHToken),
      usdu_amount: _usduToMint,
      collateral_amount: _stETHToDeposit
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    vm.startPrank(benefactor);
    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      benefactorPrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );
    IERC20(address(stETHToken)).approve(address(UnitasMintingContract), _stETHToDeposit);
    vm.stopPrank();

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    IUnitasMintingV2.Order memory redeemOrder = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 44524527,
      benefactor: owner,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    // taker
    vm.startPrank(owner);
    usduToken.approve(address(UnitasMintingContract), _usduToMint);

    bytes32 redeemDigest = UnitasMintingContract.hashOrder(redeemOrder);
    IUnitasMintingV2.Signature memory redeemTakerSignature = signOrder(
      ownerPrivateKey,
      redeemDigest,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BenefactorNotWhitelisted);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(owner);
    vm.stopPrank();

    vm.startPrank(redeemer);
    vm.expectRevert(BeneficiaryNotApproved);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
    vm.stopPrank();

    vm.startPrank(owner);
    UnitasMintingContract.setApprovedBeneficiary(beneficiary, true);
    vm.stopPrank();

    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, redeemTakerSignature);
  }
}
