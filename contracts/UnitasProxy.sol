// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./SingleAdminAccessControl.sol";
import "./StakedUSDuV2.sol";
import "./interfaces/IUnitasMintingV2.sol";
import "./interfaces/IUSDu.sol";
import "./interfaces/IUnitasProxy.sol";

contract UnitasProxy is IUnitasProxy, IERC1271, SingleAdminAccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;

  bytes32 public constant MINT_CALLER_ROLE = keccak256("MINT_CALLER_ROLE");
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
  bytes4 private constant EIP1271_INVALID_SIGNATURE = 0xffffffff;

  address public immutable usdu;
  IUnitasMintingV2 public immutable minting;
  StakedUSDuV2 public immutable staked;

  constructor(address adminAddress, address usduAddress, address mintingAddress, address stakedAddress) {
    if (
      address(mintingAddress) == address(0) ||
      address(stakedAddress) == address(0) ||
      address(usduAddress) == address(0)
    ) {
      revert InvalidZeroAddress();
    }
    if (adminAddress == address(0)) {
      revert InvalidZeroAddress();
    }

    minting = IUnitasMintingV2(mintingAddress);
    staked = StakedUSDuV2(stakedAddress);
    usdu = usduAddress;

    // Add AdminChanged event emission when admin role is granted
    emit AdminChanged(address(0), adminAddress);
    _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view override returns (bytes4) {
    (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
    if (err == ECDSA.RecoverError.NoError && hasRole(SIGNER_ROLE, signer)) {
      return EIP1271_MAGICVALUE;
    }
    return EIP1271_INVALID_SIGNATURE;
  }

  function approveCollateral(
    address collateralAsset,
    uint256 allowance
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (collateralAsset == address(0)) {
      revert InvalidZeroAddress();
    }

    IERC20(collateralAsset).approve(address(minting), 0);
    IERC20(collateralAsset).approve(address(minting), allowance);

    emit CollateralApproved(collateralAsset, allowance);
  }

  function rescueERC20(address token, address to, uint256 amount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (token == address(0) || to == address(0)) {
      revert InvalidZeroAddress();
    }
    IERC20(token).safeTransfer(to, amount);

    emit ERC20Rescued(token, to, amount);
  }

  function mintAndStake(
    address benefactor,
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Route calldata route,
    IUnitasMintingV2.Signature calldata signature
  ) external override nonReentrant onlyRole(MINT_CALLER_ROLE) returns (uint256 shares) {
    if (beneficiary == address(0)) {
      revert InvalidZeroAddress();
    }
    if (signature.signature_type != IUnitasMintingV2.SignatureType.EIP1271) {
      revert InvalidSignatureType();
    }
    if (order.benefactor != address(this)) {
      revert InvalidBenefactor();
    }
    if (order.beneficiary != address(this)) {
      revert InvalidBeneficiary();
    }

    // Transfer collateral asset from benefactor to this contract
    // Make sure benefactor approve to proxy contract
    IERC20(order.collateral_asset).safeTransferFrom(benefactor, address(this), order.collateral_amount);
    
    uint256 amount = uint256(order.usdu_amount);

    minting.mint(order, route, signature);

    IERC20(usdu).approve(address(staked), 0);
    IERC20(usdu).approve(address(staked), amount);

    shares = staked.deposit(amount, beneficiary);

    emit MintAndStake(beneficiary, order, route, signature);
  }
}
