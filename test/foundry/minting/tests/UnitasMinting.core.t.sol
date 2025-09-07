// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMinting.utils.sol";

contract UnitasMintingCoreTest is UnitasMintingUtils {
  function setUp() public override {
    super.setUp();
  }

  function test_mint() public {
    executeMint();
  }

  function test_redeem() public {
    executeRedeem();
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0, "Mismatch in stETH balance");
    assertEq(stETHToken.balanceOf(beneficiary), _stETHToDeposit, "Mismatch in stETH balance");
    assertEq(usduToken.balanceOf(beneficiary), 0, "Mismatch in USDu balance");
  }

  function test_redeem_invalidNonce_revert() public {
    // Unset the max redeem per block limit
    vm.prank(owner);
    UnitasMintingContract.setMaxRedeemPerBlock(type(uint256).max);

    (IUnitasMinting.Order memory redeemOrder, IUnitasMinting.Signature memory takerSignature2) =
      redeem_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.startPrank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    vm.expectRevert(InvalidNonce);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);
  }

  function test_nativeEth_withdraw() public {
    vm.deal(address(UnitasMintingContract), _stETHToDeposit);

    IUnitasMinting.Order memory order = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 8,
      benefactor: benefactor,
      beneficiary: benefactor,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint256[] memory ratios = new uint256[](1);
    ratios[0] = 10_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(usduToken.balanceOf(benefactor), 0);

    vm.recordLogs();
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();

    assertEq(usduToken.balanceOf(benefactor), _usduToMint);

    //redeem
    IUnitasMinting.Order memory redeemOrder = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.REDEEM,
      expiry: block.timestamp + 10 minutes,
      nonce: 800,
      benefactor: benefactor,
      beneficiary: benefactor,
      collateral_asset: NATIVE_TOKEN,
      usdu_amount: _usduToMint,
      collateral_amount: _stETHToDeposit
    });

    // taker
    vm.startPrank(benefactor);
    usduToken.approve(address(UnitasMintingContract), _usduToMint);

    bytes32 digest3 = UnitasMintingContract.hashOrder(redeemOrder);
    IUnitasMinting.Signature memory takerSignature2 =
      signOrder(benefactorPrivateKey, digest3, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.startPrank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);

    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(usduToken.balanceOf(benefactor), 0);
    assertEq(benefactor.balance, _stETHToDeposit);

    vm.stopPrank();
  }

  function test_fuzz_mint_noSlippage(uint256 expectedAmount) public {
    vm.assume(expectedAmount > 0 && expectedAmount < _maxMintPerBlock);

    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(expectedAmount, _stETHToDeposit, 1, false);

    vm.recordLogs();
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit);
    assertEq(usduToken.balanceOf(beneficiary), expectedAmount);
  }

  function test_multipleValid_custodyRatios_addresses() public {
    uint256 _smallUsduToMint = 1.75 * 10 ** 23;
    IUnitasMinting.Order memory order = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 14,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _smallUsduToMint
    });

    address[] memory targets = new address[](3);
    targets[0] = address(UnitasMintingContract);
    targets[1] = custodian1;
    targets[2] = custodian2;

    uint256[] memory ratios = new uint256[](3);
    ratios[0] = 3_000;
    ratios[1] = 4_000;
    ratios[2] = 3_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.prank(minter);
    vm.expectRevert(InvalidRoute);
    UnitasMintingContract.mint(order, route, takerSignature);

    vm.prank(owner);
    UnitasMintingContract.addCustodianAddress(custodian2);

    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), 0);
    assertEq(usduToken.balanceOf(beneficiary), _smallUsduToMint);

    assertEq(stETHToken.balanceOf(address(custodian1)), (_stETHToDeposit * 4) / 10);
    assertEq(stETHToken.balanceOf(address(custodian2)), (_stETHToDeposit * 3) / 10);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), (_stETHToDeposit * 3) / 10);

    // remove custodian and expect reversion
    vm.prank(owner);
    UnitasMintingContract.removeCustodianAddress(custodian2);

    vm.prank(minter);
    vm.expectRevert(InvalidRoute);
    UnitasMintingContract.mint(order, route, takerSignature);
  }

  function test_fuzz_multipleInvalid_custodyRatios_revert(uint256 ratio1) public {
    ratio1 = bound(ratio1, 0, UINT256_MAX - 7_000);
    vm.assume(ratio1 != 3_000);

    IUnitasMinting.Order memory mintOrder = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 15,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](2);
    targets[0] = address(UnitasMintingContract);
    targets[1] = owner;

    uint256[] memory ratios = new uint256[](2);
    ratios[0] = ratio1;
    ratios[1] = 7_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(mintOrder);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.expectRevert(InvalidRoute);
    vm.prank(minter);
    UnitasMintingContract.mint(mintOrder, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usduToken.balanceOf(beneficiary), 0);

    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0);
    assertEq(stETHToken.balanceOf(owner), 0);
  }

  function test_fuzz_singleInvalid_custodyRatio_revert(uint256 ratio1) public {
    vm.assume(ratio1 != 10_000);

    IUnitasMinting.Order memory order = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 16,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint256[] memory ratios = new uint256[](1);
    ratios[0] = ratio1;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

    vm.expectRevert(InvalidRoute);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);

    assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
    assertEq(usduToken.balanceOf(beneficiary), 0);

    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), 0);
  }

  function test_unsupported_assets_ERC20_revert() public {
    vm.startPrank(owner);
    UnitasMintingContract.removeSupportedAsset(address(stETHToken));
    stETHToken.mint(_stETHToDeposit, benefactor);
    vm.stopPrank();

    IUnitasMinting.Order memory order = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 18,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint256[] memory ratios = new uint256[](1);
    ratios[0] = 10_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.recordLogs();
    vm.expectRevert(UnsupportedAsset);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_unsupported_assets_ETH_revert() public {
    vm.startPrank(owner);
    vm.deal(benefactor, _stETHToDeposit);
    vm.stopPrank();

    IUnitasMinting.Order memory order = IUnitasMinting.Order({
      order_type: IUnitasMinting.OrderType.MINT,
      expiry: block.timestamp + 10 minutes,
      nonce: 19,
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: NATIVE_TOKEN,
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint256[] memory ratios = new uint256[](1);
    ratios[0] = 10_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    // taker
    vm.startPrank(benefactor);
    stETHToken.approve(address(UnitasMintingContract), _stETHToDeposit);

    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    IUnitasMinting.Signature memory takerSignature =
      signOrder(benefactorPrivateKey, digest1, IUnitasMinting.SignatureType.EIP712);
    vm.stopPrank();

    vm.recordLogs();
    vm.expectRevert(UnsupportedAsset);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_expired_orders_revert() public {
    (
      IUnitasMinting.Order memory order,
      IUnitasMinting.Signature memory takerSignature,
      IUnitasMinting.Route memory route
    ) = mint_setup(_usduToMint, _stETHToDeposit, 1, false);

    vm.warp(block.timestamp + 11 minutes);

    vm.recordLogs();
    vm.expectRevert(SignatureExpired);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
    vm.getRecordedLogs();
  }

  function test_add_and_remove_supported_asset() public {
    address asset = address(20);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    vm.startPrank(owner);
    UnitasMintingContract.addSupportedAsset(asset);
    assertTrue(UnitasMintingContract.isSupportedAsset(asset));

    vm.expectEmit(true, false, false, false);
    emit AssetRemoved(asset);
    UnitasMintingContract.removeSupportedAsset(asset);
    assertFalse(UnitasMintingContract.isSupportedAsset(asset));
  }

  function test_cannot_add_asset_already_supported_revert() public {
    address asset = address(20);
    vm.expectEmit(true, false, false, false);
    emit AssetAdded(asset);
    vm.startPrank(owner);
    UnitasMintingContract.addSupportedAsset(asset);
    assertTrue(UnitasMintingContract.isSupportedAsset(asset));

    vm.expectRevert(InvalidAssetAddress);
    UnitasMintingContract.addSupportedAsset(asset);
  }

  function test_cannot_removeAsset_not_supported_revert() public {
    address asset = address(20);
    assertFalse(UnitasMintingContract.isSupportedAsset(asset));

    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    UnitasMintingContract.removeSupportedAsset(asset);
  }

  function test_cannotAdd_addressZero_revert() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    UnitasMintingContract.addSupportedAsset(address(0));
  }

  function test_cannotAdd_USDu_revert() public {
    vm.prank(owner);
    vm.expectRevert(InvalidAssetAddress);
    UnitasMintingContract.addSupportedAsset(address(usduToken));
  }

  function test_sending_redeem_order_to_mint_revert() public {
    (IUnitasMinting.Order memory order, IUnitasMinting.Signature memory takerSignature) =
      redeem_setup(1 ether, 50 ether, 20, false);

    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint256[] memory ratios = new uint256[](1);
    ratios[0] = 10_000;

    IUnitasMinting.Route memory route = IUnitasMinting.Route({addresses: targets, ratios: ratios});

    vm.expectRevert(InvalidOrder);
    vm.prank(minter);
    UnitasMintingContract.mint(order, route, takerSignature);
  }

  function test_sending_mint_order_to_redeem_revert() public {
    (IUnitasMinting.Order memory order, IUnitasMinting.Signature memory takerSignature,) =
      mint_setup(1 ether, 50 ether, 20, false);

    vm.expectRevert(InvalidOrder);
    vm.prank(redeemer);
    UnitasMintingContract.redeem(order, takerSignature);
  }

  function test_receive_eth() public {
    assertEq(address(UnitasMintingContract).balance, 0);
    vm.deal(owner, 10_000 ether);
    vm.prank(owner);
    (bool success,) = address(UnitasMintingContract).call{value: 10_000 ether}("");
    assertTrue(success);
    assertEq(address(UnitasMintingContract).balance, 10_000 ether);
  }
}
