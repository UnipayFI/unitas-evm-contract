// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../contracts/UnitasMintingV2.sol";
import "../contracts/mock/MockToken.sol";

contract UnitasMintingV2MockScript is Script {
  address benefactor = 0x9F0cfD25ACe49057691948E4EAD7044CCc52d050;
  address minter = 0x9F0cfD25ACe49057691948E4EAD7044CCc52d050;
  address redeemer = 0x9F0cfD25ACe49057691948E4EAD7044CCc52d050;
  address beneficiary = 0x9F0cfD25ACe49057691948E4EAD7044CCc52d050;
  address collateral_asset = 0x42e3D7f4cfE3B94BCeF3EBaEa832326AcB40C142;
  MockToken collateral_token = MockToken(0x42e3D7f4cfE3B94BCeF3EBaEa832326AcB40C142);
  IERC20 public usduToken = IERC20(0x029544a6ef165c84A6E30862C85B996A2BF0f9dE);
  UnitasMintingV2 public UnitasMintingContract = UnitasMintingV2(payable(0x84E5D5009ab4EE5eCf42eeA5f1B950d39eEFb648));

  uint256 benefactorPrivateKey;
  uint256 beneficiaryPrivateKey;

  string constant ORDER_ID_PREFIX = "RFQ-";
  bytes constant ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

  function setUp() public {
    // forkId
    uint256 forkId = vm.createFork(
      "https://rpc.ankr.com/bsc_testnet_chapel/9c05cbd66971c4f4279faa4e285ac086cc93601060343afe4d8c27464fe18c8d"
    );
    vm.selectFork(forkId);

    benefactorPrivateKey = vm.envUint("MOCK_PRIVATE_KEY");
    beneficiaryPrivateKey = vm.envUint("MOCK_PRIVATE_KEY");
  }

  /// @notice packs r, s, v into signature bytes
  function _packRsv(bytes32 r, bytes32 s, uint8 v) internal pure returns (bytes memory) {
    bytes memory sig = new bytes(65);
    assembly {
      mstore(add(sig, 32), r)
      mstore(add(sig, 64), s)
      mstore8(add(sig, 96), v)
    }
    return sig;
  }

  function signOrder(
    uint256 key,
    bytes32 digest,
    IUnitasMintingV2.SignatureType sigType
  ) public pure returns (IUnitasMintingV2.Signature memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
    bytes memory sigBytes = _packRsv(r, s, v);

    IUnitasMintingV2.Signature memory signature = IUnitasMintingV2.Signature({
      signature_type: sigType,
      signature_bytes: sigBytes
    });

    return signature;
  }

  function generateRandomOrderId() internal view returns (string memory) {
    bytes memory randomChars = new bytes(13);
    for (uint256 i = 0; i < 13; i++) {
      uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) %
        ALPHANUMERIC.length;
      randomChars[i] = ALPHANUMERIC[randomIndex];
    }
    return string(abi.encodePacked(ORDER_ID_PREFIX, randomChars));
  }

  // Generic mint setup reused in the tests to reduce lines of code
  function mint_setup(
    uint256 usduAmount,
    uint256 collateralAmount,
    uint256 nonce
  )
    public
    returns (
      IUnitasMintingV2.Order memory order,
      IUnitasMintingV2.Signature memory takerSignature,
      IUnitasMintingV2.Route memory route
    )
  {
    order = IUnitasMintingV2.Order({
      order_id: "2225",
      order_type: IUnitasMintingV2.OrderType.MINT,
      nonce: uint120(nonce),
      expiry: uint128(block.timestamp + 10 minutes),
      benefactor: benefactor,
      beneficiary: beneficiary,
      collateral_asset: collateral_asset,
      usdu_amount: uint128(usduAmount),
      collateral_amount: uint128(collateralAmount)
    });

    address[] memory targets = new address[](1);
    targets[0] = address(0x9F0cfD25ACe49057691948E4EAD7044CCc52d050);

    uint128[] memory ratios = new uint128[](1);
    ratios[0] = 10_000;

    route = IUnitasMintingV2.Route({ addresses: targets, ratios: ratios });

    vm.startPrank(benefactor);
    bytes32 digest1 = UnitasMintingContract.hashOrder(order);
    console.log("digest:");
    console.logBytes32(digest1);
    takerSignature = signOrder(benefactorPrivateKey, digest1, IUnitasMintingV2.SignatureType.EIP712);
    console.log("signature:");
    console.logBytes(takerSignature.signature_bytes);
    collateral_token.approve(address(UnitasMintingContract), collateralAmount);
    vm.stopPrank();
  }

  function execute_mint() internal {
    uint256 usduAmount = 1000000000000000000;
    uint256 collateralAmount = 1000000000000000000;
    uint256 nonce = 1764119701226;
    (
      IUnitasMintingV2.Order memory mintOrder,
      IUnitasMintingV2.Signature memory takerSignature,
      IUnitasMintingV2.Route memory route
    ) = mint_setup(usduAmount, collateralAmount, nonce);

    vm.startPrank(benefactor);
    IERC20(mintOrder.collateral_asset).approve(address(UnitasMintingContract), collateralAmount);
    UnitasMintingContract.mint(mintOrder, route, takerSignature);
    vm.stopPrank();
  }

  function redeem_setup(
    uint256 usduAmount,
    uint256 collateralAmount,
    uint256 nonce
  ) public returns (IUnitasMintingV2.Order memory redeemOrder, IUnitasMintingV2.Signature memory takerSignature2) {
    //redeem
    redeemOrder = IUnitasMintingV2.Order({
      order_type: IUnitasMintingV2.OrderType.REDEEM,
      order_id: generateRandomOrderId(),
      expiry: uint128(block.timestamp + 10 minutes),
      nonce: uint120(nonce + 1),
      benefactor: beneficiary,
      beneficiary: beneficiary,
      collateral_asset: address(collateral_asset),
      usdu_amount: uint128(usduAmount),
      collateral_amount: uint128(collateralAmount)
    });

    // taker
    vm.startPrank(beneficiary);
    usduToken.approve(address(UnitasMintingContract), usduAmount);

    bytes32 digest3 = UnitasMintingContract.hashOrder(redeemOrder);
    takerSignature2 = signOrder(beneficiaryPrivateKey, digest3, IUnitasMintingV2.SignatureType.EIP712);
    vm.stopPrank();
  }

  function execute_redeem() internal {
    uint256 usduAmount = 1;
    uint256 collateralAmount = 1;
    uint256 nonce = 1747613582964;
    (IUnitasMintingV2.Order memory redeemOrder, IUnitasMintingV2.Signature memory takerSignature2) = redeem_setup(
      usduAmount,
      collateralAmount,
      nonce
    );

    uint256 contractBalance = IERC20(collateral_asset).balanceOf(address(UnitasMintingContract));
    console.log("Contract collateral balance before redeem:", contractBalance);
    vm.startPrank(redeemer);
    UnitasMintingContract.redeem(redeemOrder, takerSignature2);
    vm.stopPrank();
  }

  function run() public {
    execute_mint();
  }
}

contract UnitasMintingV2SimulateScript is Script {
  UnitasMintingV2 public UnitasMintingContract = UnitasMintingV2(payable(0xbB984CE670100AA855f6152f88b26EE57f4EA82A));
  address internal admin = 0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8;

  function setUp() public {
    // forkId
    uint256 forkId = vm.createFork(
      "https://rpc.ankr.com/bsc/9c05cbd66971c4f4279faa4e285ac086cc93601060343afe4d8c27464fe18c8d"
    );
    vm.selectFork(forkId);
  }

  function simulateAddWhitelistedBenefactor() public {
    vm.startPrank(admin);
    UnitasMintingContract.addWhitelistedBenefactor(0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6);
    vm.stopPrank();
  }

  function run() public {
    simulateAddWhitelistedBenefactor();
  }
}
