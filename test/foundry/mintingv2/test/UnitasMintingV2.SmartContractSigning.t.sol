// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMintingV2.utils.sol";

contract UnitasMintingV2ContractSigningTest is UnitasMintingV2Utils {
  function setUp() public override {
    super.setUp();
  }

  function test_multi_sig_eip_1271_mint() public {
    IUnitasMintingV2.Order memory order = createOrder();
    IUnitasMintingV2.Route memory route = createRoute();
    bytes32 digest1 = UnitasMintingContract.hashOrder(order);

    approveERC20(owner);

    submitFirstSignature(digest1);

    vm.prank(minter);
    vm.expectRevert(InvalidEIP1271Signature);
    UnitasMintingContract.mint(
      order,
      route,
      signOrder(smartContractSigner1PrivateKey, digest1, IUnitasMintingV2.SignatureType.EIP1271)
    );

    submitSecondSignature(digest1);

    vm.prank(minter);
    UnitasMintingContract.mint(
      order,
      route,
      signOrder(smartContractSigner2PrivateKey, digest1, IUnitasMintingV2.SignatureType.EIP1271)
    );

    assertEq(stETHToken.balanceOf(address(MultiSigWalletBenefactor)), 0);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), _stETHToDeposit);
    assertEq(usduToken.balanceOf(address(MultiSigWalletBenefactor)), _usduToMint);
  }

  function createOrder() internal view returns (IUnitasMintingV2.Order memory) {
    return
      IUnitasMintingV2.Order({
        order_type: IUnitasMintingV2.OrderType.MINT,
        order_id: generateRandomOrderId(),
        expiry: uint120(block.timestamp + 10 minutes),
        nonce: 1,
        benefactor: mockMultiSigWallet,
        beneficiary: mockMultiSigWallet,
        collateral_asset: address(stETHToken),
        usdu_amount: _usduToMint,
        collateral_amount: _stETHToDeposit
      });
  }

  function createRoute() internal view returns (IUnitasMintingV2.Route memory) {
    address[] memory targets = new address[](1);
    targets[0] = address(UnitasMintingContract);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    return IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });
  }

  function signMessage(uint256 privateKey) internal view returns (bytes memory) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(address(stETHToken), address(UnitasMintingContract), _stETHToDeposit)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
    return _packRsv(r, s, v);
  }

  function approveERC20(address approver) internal {
    vm.prank(approver);
    MultiSigWalletBenefactor.approveERC20(address(stETHToken), address(UnitasMintingContract), _stETHToDeposit);
  }

  function submitFirstSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner1);
    IUnitasMintingV2.Signature memory signature = signOrder(
      smartContractSigner1PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }

  function submitSecondSignature(bytes32 digest) internal {
    vm.startPrank(smartContractSigner2);
    IUnitasMintingV2.Signature memory signature = signOrder(
      smartContractSigner2PrivateKey,
      digest,
      IUnitasMintingV2.SignatureType.EIP1271
    );
    MultiSigWalletBenefactor.submitSignature(digest, signature.signature_bytes);
    vm.stopPrank();
  }
}
