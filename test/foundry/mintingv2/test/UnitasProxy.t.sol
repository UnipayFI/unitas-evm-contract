// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMintingV2.utils.sol";
import "../../../../contracts/StakedUSDuV2.sol";
import "../../../../contracts/UnitasProxy.sol";

contract UnitasProxyTest is UnitasMintingV2Utils {
  StakedUSDuV2 internal staked;
  UnitasProxy internal proxy;

  function setUp() public override {
    super.setUp();

    staked = new StakedUSDuV2(IERC20(address(usduToken)), owner, owner);
    proxy = new UnitasProxy(IUnitasMintingV2(address(UnitasMintingContract)), staked, IUSDu(address(usduToken)), owner);

    vm.startPrank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(address(proxy));
    UnitasMintingContract.grantRole(minterRole, address(proxy));
    proxy.grantRole(proxy.MINT_CALLER_ROLE(), minter);
    proxy.grantRole(proxy.SIGNER_ROLE(), trader1);
    vm.stopPrank();
  }

  function test_isValidSignature_validSigner_returnsMagicValue() public view {
    bytes32 hash = keccak256("UnitasProxyTest");
    IUnitasMintingV2.Signature memory signature = signOrder(trader1PrivateKey, hash, IUnitasMintingV2.SignatureType.EIP1271);

    bytes4 magic = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    assertEq(proxy.isValidSignature(hash, signature.signature_bytes), magic);
  }

  function test_isValidSignature_invalidSigner_returnsInvalid() public view {
    bytes32 hash = keccak256("UnitasProxyTest");
    IUnitasMintingV2.Signature memory signature = signOrder(trader2PrivateKey, hash, IUnitasMintingV2.SignatureType.EIP1271);

    assertEq(proxy.isValidSignature(hash, signature.signature_bytes), bytes4(0xffffffff));
  }

  function test_mintAndStake_success() public {
    address stakeReceiver = trader2;

    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(1),
      benefactor: address(proxy),
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = custodian1;
    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    stETHToken.mint(_stETHToDeposit, address(proxy));

    vm.prank(owner);
    proxy.approveCollateral(address(stETHToken), _stETHToDeposit);

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      trader1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );

    vm.expectCall(
      address(stETHToken),
      abi.encodeCall(IERC20.transferFrom, (address(proxy), custodian1, uint256(_stETHToDeposit)))
    );
    vm.prank(minter);
    uint256 shares = proxy.mintAndStake(order, route, takerSignature, stakeReceiver);

    assertEq(stETHToken.balanceOf(custodian1), _stETHToDeposit);
    assertEq(usduToken.balanceOf(address(proxy)), 0);
    assertEq(staked.balanceOf(stakeReceiver), shares);
    assertEq(shares, _usduToMint);
    assertEq(staked.totalAssets(), _usduToMint);
  }

  function test_mintAndStake_revert_whenCallerMissingRole() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(1),
      benefactor: address(proxy),
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = custodian1;
    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      trader1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );

    vm.expectRevert();
    vm.prank(trader2);
    proxy.mintAndStake(order, route, takerSignature, trader2);
  }

  function test_mintAndStake_revert_whenInvalidSignatureType() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(1),
      benefactor: address(proxy),
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = custodian1;
    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      trader1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP712
    );

    vm.expectRevert(UnitasProxy.InvalidSignatureType.selector);
    vm.prank(minter);
    proxy.mintAndStake(order, route, takerSignature, trader2);
  }

  function test_mintAndStake_revert_whenInvalidBenefactor() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(1),
      benefactor: benefactor,
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = custodian1;
    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      trader1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );

    vm.expectRevert(UnitasProxy.InvalidBenefactor.selector);
    vm.prank(minter);
    proxy.mintAndStake(order, route, takerSignature, trader2);
  }

  function test_mintAndStake_revert_whenInvalidBeneficiary() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.MINT,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(1),
      benefactor: address(proxy),
      beneficiary: beneficiary,
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    address[] memory targets = new address[](1);
    targets[0] = custodian1;
    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature = signOrder(
      trader1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );

    vm.expectRevert(UnitasProxy.InvalidBeneficiary.selector);
    vm.prank(minter);
    proxy.mintAndStake(order, route, takerSignature, trader2);
  }

  function test_approveCollateral_and_rescueERC20_onlyAdmin() public {
    vm.expectRevert();
    vm.prank(trader2);
    proxy.approveCollateral(address(stETHToken), 1);

    vm.expectRevert();
    vm.prank(trader2);
    proxy.rescueERC20(address(stETHToken), trader2, 1);
  }

  function test_rescueERC20_transfersToken() public {
    stETHToken.mint(123, address(proxy));
    assertEq(stETHToken.balanceOf(trader2), 0);

    vm.prank(owner);
    proxy.rescueERC20(address(stETHToken), trader2, 123);

    assertEq(stETHToken.balanceOf(trader2), 123);
  }
}
