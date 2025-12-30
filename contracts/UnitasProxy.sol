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

contract UnitasProxy is IERC1271, SingleAdminAccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;

  error InvalidZeroAddress();
  error InvalidBenefactor();
  error InvalidBeneficiary();
  error InvalidSignatureType();

  bytes32 public constant MINT_CALLER_ROLE = keccak256("MINT_CALLER_ROLE");
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
  bytes4 private constant EIP1271_INVALID_SIGNATURE = 0xffffffff;

  IUnitasMintingV2 public immutable minting;
  StakedUSDuV2 public immutable staked;
  IUSDu public immutable usdu;

  constructor(
    IUnitasMintingV2 _minting,
    StakedUSDuV2 _staked,
    IUSDu _usdu,
    address admin
  ) {
    if (address(_minting) == address(0) || address(_staked) == address(0) || address(_usdu) == address(0)) {
      revert InvalidZeroAddress();
    }
    if (admin == address(0)) {
      revert InvalidZeroAddress();
    }

    minting = _minting;
    staked = _staked;
    usdu = _usdu;

    _grantRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view override returns (bytes4) {
    (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
    if (err == ECDSA.RecoverError.NoError && hasRole(SIGNER_ROLE, signer)) {
      return EIP1271_MAGICVALUE;
    }
    return EIP1271_INVALID_SIGNATURE;
  }

  function approveCollateral(address collateralAsset, uint256 allowance) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (collateralAsset == address(0)) {
      revert InvalidZeroAddress();
    }

    IERC20(collateralAsset).safeApprove(address(minting), 0);
    IERC20(collateralAsset).safeApprove(address(minting), allowance);
  }

  function rescueERC20(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (token == address(0) || to == address(0)) {
      revert InvalidZeroAddress();
    }
    IERC20(token).safeTransfer(to, amount);
  }

  function mintAndStake(
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Route calldata route,
    IUnitasMintingV2.Signature calldata signature,
    address stakeReceiver
  ) external nonReentrant onlyRole(MINT_CALLER_ROLE) returns (uint256 shares) {
    if (stakeReceiver == address(0)) {
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

    uint256 amount = uint256(order.usdu_amount);

    minting.mint(order, route, signature);

    IERC20(address(usdu)).safeApprove(address(staked), 0);
    IERC20(address(usdu)).safeApprove(address(staked), amount);

    shares = staked.deposit(amount, stakeReceiver);
  }
}
