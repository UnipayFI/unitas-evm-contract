// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMintingV2.utils.sol";

contract UnitasMintingV2StableRatiosTest is UnitasMintingV2Utils {
  function setUp() public override {
    super.setUp();
  }

  function test_stable_ratios_setup() public {
    uint128 stablesDeltaLimitZero = 0; // zero bps allowed (identical USDT and USDu amounts)
    uint128 stablesDeltaLimitPositive = 577; // positive bps allowed

    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimitZero);

    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimitPositive);
  }

  function test_verify_stables_limit() external {
    vm.prank(benefactor);
    USDTToken.mint(25000 * 10 ** 6);

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usduAmount = 1000 * 10 ** 18; // 1,000 USDu

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    address usdtAddress = address(USDTToken);

    assertEq(
      UnitasMintingContract.verifyStablesLimit(
        usdtAmountAtUpperLimit,
        usduAmount,
        usdtAddress,
        IUnitasMintingV2.OrderType.MINT
      ),
      true
    );
    assertEq(
      UnitasMintingContract.verifyStablesLimit(
        usdtAmountAtLowerLimit,
        usduAmount,
        usdtAddress,
        IUnitasMintingV2.OrderType.REDEEM
      ),
      true
    );
  }

  function test_stables_limit_minting_valid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 6); // Ensuring there is enough USDT for testing

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usduAmount = 1000 * 10 ** 18; // 1,000 USDu

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (
      IUnitasMintingV2.Order memory orderLow,
      IUnitasMintingV2.Signature memory signatureLow,
      IUnitasMintingV2.Route memory routeLow
    ) = mint_setup(usduAmount, usdtAmountAtLowerLimit, USDTToken, 1, true);
    vm.prank(minter);
    UnitasMintingContract.mint(orderLow, routeLow, signatureLow);

    (
      IUnitasMintingV2.Order memory orderHigh,
      IUnitasMintingV2.Signature memory signatureHigh,
      IUnitasMintingV2.Route memory routeHigh
    ) = mint_setup(usduAmount, usdtAmountAtUpperLimit, USDTToken, 2, true);
    vm.prank(minter);
    UnitasMintingContract.mint(orderHigh, routeHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(benefactor), 2500 * 10 ** 6 - usdtAmountAtLowerLimit - usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(UnitasMintingContract)), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
  }

  function test_stable_ratios_minting_invalid() public {
    vm.prank(benefactor);
    USDTToken.mint(2500 * 10 ** 18);

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usduAmount = 1000 * 10 ** 18; // 1,000 USDu
    uint128 collateralGreaterBreachStableLimit = 1011 * 10 ** 6;
    (
      IUnitasMintingV2.Order memory aOrder,
      IUnitasMintingV2.Signature memory aTakerSignature,
      IUnitasMintingV2.Route memory aRoute
    ) = mint_setup(usduAmount, collateralGreaterBreachStableLimit, USDTToken, 1, true);

    vm.prank(minter);
    UnitasMintingContract.mint(aOrder, aRoute, aTakerSignature);

    uint128 collateralLessThanBreachesStableLimit = 989 * 10 ** 6;
    (
      IUnitasMintingV2.Order memory bOrder,
      IUnitasMintingV2.Signature memory bTakerSignature,
      IUnitasMintingV2.Route memory bRoute
    ) = mint_setup(usduAmount, collateralLessThanBreachesStableLimit, USDTToken, 2, true);

    vm.expectRevert(InvalidStablePrice);
    vm.prank(minter);
    UnitasMintingContract.mint(bOrder, bRoute, bTakerSignature);
  }

  function test_stables_limit_redeem_valid() public {
    vm.prank(address(UnitasMintingContract));
    usduToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, benefactor); // initial mint

    uint128 stablesDeltaLimit = 100; // 100 bps

    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usduAmount = 1000 * 10 ** 18; // 1,000 USDu

    uint128 usdtAmountAtUpperLimit = 1010 * 10 ** 6; // 100 bps above the USDT amount that should be at the upper bps limit
    uint128 usdtAmountAtLowerLimit = 990 * 10 ** 6; // 100 bps below the USDT amount that should be at the lower bps limit

    (IUnitasMintingV2.Order memory orderLow, IUnitasMintingV2.Signature memory signatureLow) = redeem_setup(
      usduAmount,
      usdtAmountAtLowerLimit,
      USDTToken,
      1,
      true
    );
    vm.prank(redeemer);
    UnitasMintingContract.redeem(orderLow, signatureLow);

    (IUnitasMintingV2.Order memory orderHigh, IUnitasMintingV2.Signature memory signatureHigh) = redeem_setup(
      usduAmount,
      usdtAmountAtUpperLimit,
      USDTToken,
      2,
      true
    );
    vm.prank(redeemer);
    UnitasMintingContract.redeem(orderHigh, signatureHigh);

    assertEq(USDTToken.balanceOf(beneficiary), usdtAmountAtLowerLimit + usdtAmountAtUpperLimit);
    assertEq(USDTToken.balanceOf(address(UnitasMintingContract)), 0);
  }

  function test_stable_ratios_redeem_invalid() public {
    vm.prank(address(UnitasMintingContract));
    usduToken.mint(beneficiary, 2500 * 10 ** 18);

    USDTToken.mint(2500 * 10 ** 6, address(UnitasMintingContract));

    uint128 stablesDeltaLimit = 100; // 100 bps
    vm.prank(owner);
    UnitasMintingContract.setStablesDeltaLimit(stablesDeltaLimit);

    uint128 usduAmount = 1000 * 10 ** 18; // 1,000 USDu

    address collateralAsset = address(USDTToken);

    // case 1
    uint128 collateralGreaterThanUSDuAmount = 1011 * 10 ** 6; // 1011 USDT redeemed (greater than USDu)
    IUnitasMintingV2.Order memory redeemOrder2 = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 2,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      usdu_amount: usduAmount,
      collateral_amount: collateralGreaterThanUSDuAmount
    });

    vm.startPrank(beneficiary);
    usduToken.approve(address(UnitasMintingContract), usduAmount);

    bytes32 digest2 = UnitasMintingContract.hashOrder(redeemOrder2);
    IUnitasMintingV2.Signature memory takerSignature2 = signOrder(
      beneficiaryPrivateKey,
      digest2,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.expectRevert(InvalidStablePrice);
    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder2, takerSignature2);

    // case 2
    uint128 collateralLessThanUSDuAmount = 989 * 10 ** 6; // 989 USDT redeemed (less than USDu)
    IUnitasMintingV2.Order memory redeemOrder1 = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint120(block.timestamp + 10 minutes),
      nonce: 1,
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: collateralAsset,
      usdu_amount: usduAmount,
      collateral_amount: collateralLessThanUSDuAmount
    });

    vm.startPrank(beneficiary);
    usduToken.approve(address(UnitasMintingContract), usduAmount);

    bytes32 digest1 = UnitasMintingContract.hashOrder(redeemOrder1);
    IUnitasMintingV2.Signature memory takerSignature1 = signOrder(
      beneficiaryPrivateKey,
      digest1,
      IUnitasMintingV2.SignatureType.EIP712
    );
    vm.stopPrank();

    vm.startPrank(owner);
    UnitasMintingContract.grantRole(redeemerRole, redeemer);
    vm.stopPrank();

    vm.prank(redeemer);
    UnitasMintingContract.redeem(redeemOrder1, takerSignature1);
  }
}
