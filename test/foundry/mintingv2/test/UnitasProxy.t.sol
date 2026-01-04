// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable func-name-mixedcase  */

import "../UnitasMintingV2.utils.sol";
import "../../../../contracts/StakedUSDuV2.sol";
import "../../../../contracts/UnitasProxy.sol";
import "../../../../contracts/interfaces/IUnitasProxy.sol";

contract UnitasProxyTest is UnitasMintingV2Utils {
  StakedUSDuV2 internal staked;
  UnitasProxy internal proxy;

  function setUp() public override {
    super.setUp();

    staked = new StakedUSDuV2(IERC20(address(usduToken)), owner, owner);
    proxy = new UnitasProxy(owner, owner, address(usduToken), address(UnitasMintingContract), address(staked));

    vm.startPrank(owner);
    UnitasMintingContract.addWhitelistedBenefactor(address(proxy));
    UnitasMintingContract.grantRole(minterRole, address(proxy));
    UnitasMintingContract.grantRole(redeemerRole, address(proxy));
    proxy.grantRole(proxy.MINT_CALLER_ROLE(), minter);
    proxy.grantRole(proxy.REDEEM_CALLER_ROLE(), redeemer);
    proxy.grantRole(proxy.SIGNER_ROLE(), trader1);
    vm.stopPrank();
  }

  function test_isValidSignature_validSigner_returnsMagicValue() public view {
    bytes32 hash = keccak256("UnitasProxyTest");
    IUnitasMintingV2.Signature memory signature =
      signOrder(trader1PrivateKey, hash, IUnitasMintingV2.SignatureType.EIP1271);

    bytes4 magic = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    assertEq(proxy.isValidSignature(hash, signature.signature_bytes), magic);
  }

  function test_isValidSignature_invalidSigner_returnsInvalid() public view {
    bytes32 hash = keccak256("UnitasProxyTest");
    IUnitasMintingV2.Signature memory signature =
      signOrder(trader2PrivateKey, hash, IUnitasMintingV2.SignatureType.EIP1271);

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
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({addresses: targets, ratios: ratios});

    vm.prank(benefactor);
    stETHToken.approve(address(proxy), _stETHToDeposit);

    vm.prank(owner);
    proxy.approveCollateral(address(stETHToken), _stETHToDeposit);

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    vm.expectCall(
      address(stETHToken), abi.encodeCall(IERC20.transferFrom, (benefactor, address(proxy), uint256(_stETHToDeposit)))
    );
    vm.expectCall(
      address(stETHToken), abi.encodeCall(IERC20.transferFrom, (address(proxy), custodian1, uint256(_stETHToDeposit)))
    );
    vm.expectCall(address(usduToken), abi.encodeCall(IERC20.approve, (address(staked), uint256(0))));
    vm.expectCall(address(usduToken), abi.encodeCall(IERC20.approve, (address(staked), uint256(_usduToMint))));
    vm.prank(minter);
    uint256 shares = proxy.mintAndStake(benefactor, stakeReceiver, order, route, takerSignature);

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
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({addresses: targets, ratios: ratios});

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    vm.expectRevert();
    vm.prank(trader2);
    proxy.mintAndStake(benefactor, trader2, order, route, takerSignature);
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
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({addresses: targets, ratios: ratios});

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP712);

    vm.expectRevert(IUnitasProxy.InvalidSignatureType.selector);
    vm.prank(minter);
    proxy.mintAndStake(benefactor, trader2, order, route, takerSignature);
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
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({addresses: targets, ratios: ratios});

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    vm.expectRevert(IUnitasProxy.InvalidBenefactor.selector);
    vm.prank(minter);
    proxy.mintAndStake(benefactor, trader2, order, route, takerSignature);
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
    IUnitasMintingV2.Route memory route = IUnitasMintingV2.Route({addresses: targets, ratios: ratios});

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    vm.expectRevert(IUnitasProxy.InvalidBeneficiary.selector);
    vm.prank(minter);
    proxy.mintAndStake(benefactor, trader2, order, route, takerSignature);
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

  function test_redeemAndWithdraw_success() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(11),
      benefactor: address(proxy),
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(benefactor, _usduToMint);

    vm.prank(owner);
    stETHToken.mint(_stETHToDeposit, address(UnitasMintingContract));

    vm.prank(benefactor);
    usduToken.approve(address(proxy), _usduToMint);

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    uint256 mintingCollateralBefore = stETHToken.balanceOf(address(UnitasMintingContract));
    uint256 beneficiaryCollateralBefore = stETHToken.balanceOf(beneficiary);

    vm.prank(redeemer);
    proxy.redeemAndWithdraw(benefactor, beneficiary, order, takerSignature);

    assertEq(usduToken.balanceOf(benefactor), 0);
    assertEq(usduToken.balanceOf(address(proxy)), 0);
    assertEq(stETHToken.balanceOf(address(UnitasMintingContract)), mintingCollateralBefore - _stETHToDeposit);
    assertEq(stETHToken.balanceOf(beneficiary), beneficiaryCollateralBefore + _stETHToDeposit);
  }

  function test_redeemAndWithdraw_revert_whenCallerMissingRole() public {
    IUnitasMintingV2.Order memory order = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(12),
      benefactor: address(proxy),
      beneficiary: address(proxy),
      collateral_asset: address(stETHToken),
      collateral_amount: _stETHToDeposit,
      usdu_amount: _usduToMint
    });

    bytes32 digest = UnitasMintingContract.hashOrder(order);
    IUnitasMintingV2.Signature memory takerSignature =
      signOrder(trader1PrivateKey, digest, IUnitasMintingV2.SignatureType.EIP1271);

    vm.expectRevert();
    vm.prank(trader2);
    proxy.redeemAndWithdraw(benefactor, beneficiary, order, takerSignature);
  }

  function test_flashWithdraw_success() public {
    uint256 susduAmount = uint256(_usduToMint / 2);

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(trader2, _usduToMint);

    vm.prank(trader2);
    usduToken.approve(address(staked), _usduToMint);
    vm.prank(trader2);
    staked.deposit(_usduToMint, trader2);

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(owner, _usduToMint);

    vm.prank(owner);
    usduToken.approve(address(proxy), _usduToMint);

    vm.prank(trader2);
    staked.approve(address(proxy), susduAmount);

    uint256 usduBalanceInStaked = usduToken.balanceOf(address(staked));
    uint256 unvestedAmount = staked.getUnvestedAmount();
    uint256 susduTotal = staked.totalSupply();
    uint256 expectedUsduAmount = (susduAmount * (usduBalanceInStaked - unvestedAmount)) / susduTotal;
    uint256 expectedPenalty = (expectedUsduAmount * 50) / 10_000;
    uint256 expectedNet = expectedUsduAmount - expectedPenalty;

    vm.expectCall(address(staked), abi.encodeCall(IERC20.transferFrom, (trader2, owner, susduAmount)));
    vm.expectCall(address(usduToken), abi.encodeCall(IERC20.transferFrom, (owner, trader2, expectedNet)));

    vm.expectEmit(true, true, true, true, address(proxy));
    emit IUnitasProxy.FlashWithdraw(trader2, susduAmount, expectedUsduAmount, expectedPenalty);

    uint256 userUsduBefore = usduToken.balanceOf(trader2);
    uint256 multisigUsduBefore = usduToken.balanceOf(owner);
    uint256 multisigSusduBefore = staked.balanceOf(owner);
    uint256 userSusduBefore = staked.balanceOf(trader2);

    vm.prank(trader2);
    proxy.flashWithdraw(susduAmount);

    assertEq(usduToken.balanceOf(trader2), userUsduBefore + expectedNet);
    assertEq(usduToken.balanceOf(owner), multisigUsduBefore - expectedNet);
    assertEq(staked.balanceOf(trader2), userSusduBefore - susduAmount);
    assertEq(staked.balanceOf(owner), multisigSusduBefore + susduAmount);
  }

  function test_flashWithdraw_exchangeRateReflectsDonation() public {
    uint256 initialDeposit = uint256(_usduToMint);
    uint256 donation = 1000 ether;
    uint256 susduAmount = 10_000 ether;

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(trader2, initialDeposit);

    vm.prank(trader2);
    usduToken.approve(address(staked), initialDeposit);
    vm.prank(trader2);
    staked.deposit(initialDeposit, trader2);

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(owner, donation + 1);
    vm.prank(owner);
    usduToken.transfer(address(staked), donation);

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(owner, uint256(_usduToMint));
    vm.prank(owner);
    usduToken.approve(address(proxy), uint256(_usduToMint));

    vm.prank(trader2);
    staked.approve(address(proxy), susduAmount);

    uint256 usduBalanceInStaked = usduToken.balanceOf(address(staked));
    uint256 unvestedAmount = staked.getUnvestedAmount();
    uint256 susduTotal = staked.totalSupply();
    uint256 expectedUsduAmount = (susduAmount * (usduBalanceInStaked - unvestedAmount)) / susduTotal;

    assertGt(expectedUsduAmount, susduAmount);

    vm.prank(trader2);
    proxy.flashWithdraw(susduAmount);
  }

  function test_flashWithdraw_revert_whenZeroAmount() public {
    vm.expectRevert(IUnitasProxy.InvalidZeroAmount.selector);
    proxy.flashWithdraw(0);
  }

  function test_flashWithdraw_revert_whenPaused() public {
    vm.startPrank(owner);
    proxy.grantRole(proxy.PAUSER_ROLE(), owner);
    proxy.pause();
    vm.stopPrank();

    vm.expectRevert("Pausable: paused");
    proxy.flashWithdraw(1);
  }

  function test_flashWithdraw_revert_whenNoStakedSupply() public {
    StakedUSDuV2 emptyStaked = new StakedUSDuV2(IERC20(address(usduToken)), owner, owner);
    UnitasProxy emptyProxy =
      new UnitasProxy(owner, owner, address(usduToken), address(UnitasMintingContract), address(emptyStaked));

    vm.expectRevert(IUnitasProxy.NoStakedSupply.selector);
    emptyProxy.flashWithdraw(1);
  }

  function test_flashWithdraw_revert_whenUnvestedExceedsBalance() public {
    uint256 initialDeposit = uint256(_usduToMint);
    uint256 rewardAmount = 1000 ether;
    uint256 susduAmount = 1 ether;

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(trader2, initialDeposit);

    vm.prank(trader2);
    usduToken.approve(address(staked), initialDeposit);
    vm.prank(trader2);
    staked.deposit(initialDeposit, trader2);

    vm.prank(address(UnitasMintingContract));
    usduToken.mint(owner, rewardAmount);

    vm.prank(owner);
    usduToken.approve(address(staked), rewardAmount);
    vm.prank(owner);
    staked.transferInRewards(rewardAmount);

    uint256 stakedUsduBalance = usduToken.balanceOf(address(staked));
    vm.prank(address(staked));
    usduToken.transfer(trader1, stakedUsduBalance);

    vm.prank(trader2);
    staked.approve(address(proxy), susduAmount);

    vm.expectRevert(IUnitasProxy.InvalidStakedState.selector);
    vm.prank(trader2);
    proxy.flashWithdraw(susduAmount);
  }

  function test_constructor_revert_whenMultiSigWalletZero() public {
    vm.expectRevert(IUnitasProxy.InvalidZeroAddress.selector);
    new UnitasProxy(owner, address(0), address(usduToken), address(UnitasMintingContract), address(staked));
  }
}
