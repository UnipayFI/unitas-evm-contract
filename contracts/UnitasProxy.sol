// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./SingleAdminAccessControl.sol";
import "./StakedUSDuV2.sol";
import "./interfaces/IUnitasMintingV2.sol";
import "./interfaces/IUSDu.sol";
import "./interfaces/IStakedUSDu.sol";
import "./interfaces/IUnitasProxy.sol";

contract UnitasProxy is IUnitasProxy, IERC1271, SingleAdminAccessControl, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  bytes32 public constant MINT_CALLER_ROLE = keccak256("MINT_CALLER_ROLE");
  bytes32 public constant REDEEM_CALLER_ROLE = keccak256("REDEEM_CALLER_ROLE");
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  bytes4 private constant EIP1271_MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
  bytes4 private constant EIP1271_INVALID_SIGNATURE = 0xffffffff;

  uint256 private penaltyRate = 50; // 0.5%
  uint256 private constant MAX_PENALTY_RATE = 10000; // 100%

  address public multiSigWallet;
  address public immutable usdu;
  IUnitasMintingV2 public immutable minting;
  StakedUSDuV2 public immutable staked;

  constructor(
    address adminAddress,
    address multiSigWalletAddress,
    address usduAddress,
    address mintingAddress,
    address stakedAddress
  ) {
    if (
      address(mintingAddress) == address(0) || address(stakedAddress) == address(0)
        || address(usduAddress) == address(0) || address(multiSigWalletAddress) == address(0)
    ) {
      revert InvalidZeroAddress();
    }
    if (adminAddress == address(0)) {
      revert InvalidZeroAddress();
    }

    minting = IUnitasMintingV2(mintingAddress);
    staked = StakedUSDuV2(stakedAddress);
    usdu = usduAddress;
    multiSigWallet = multiSigWalletAddress;

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

  function approveCollateral(address collateralAsset, uint256 allowance) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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

  function adjustPenaltyRate(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (rate > MAX_PENALTY_RATE) {
      revert InvalidPenaltyRate();
    }
    emit PenaltyRateSet(penaltyRate, rate);
    penaltyRate = rate;
  }

  function updateMultiSigWallet(address newMultiSigWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (newMultiSigWallet == address(0)) {
      revert InvalidZeroAddress();
    }
    emit MultiSigWalletUpdated(multiSigWallet, newMultiSigWallet);
    multiSigWallet = newMultiSigWallet;
  }

  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function calculateExchangeRate(uint256 susduAmount) internal view returns (uint256) {
    uint256 usduBalanceInStaked = IERC20(usdu).balanceOf(address(staked));
    uint256 unvestedAmount = IStakedUSDu(address(staked)).getUnvestedAmount();
    uint256 susduTotal = staked.totalSupply();
    if (susduTotal == 0) {
      revert NoStakedSupply();
    }
    if (unvestedAmount > usduBalanceInStaked) {
      revert InvalidStakedState();
    }
    return susduAmount * (usduBalanceInStaked - unvestedAmount) / susduTotal;
  }

  function flashWithdraw(uint256 susduAmount) external nonReentrant whenNotPaused {
    if (susduAmount == 0) {
      revert InvalidZeroAmount();
    }
    uint256 usduAmount = calculateExchangeRate(susduAmount);
    uint256 penaltyUsduAmount = (usduAmount * penaltyRate) / MAX_PENALTY_RATE;

    IERC20(address(staked)).safeTransferFrom(msg.sender, multiSigWallet, susduAmount);
    IERC20(usdu).safeTransferFrom(multiSigWallet, msg.sender, usduAmount - penaltyUsduAmount);

    emit FlashWithdraw(msg.sender, susduAmount, usduAmount, penaltyUsduAmount);
  }

  function mintAndStake(
    address benefactor,
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Route calldata route,
    IUnitasMintingV2.Signature calldata signature
  ) external override nonReentrant onlyRole(MINT_CALLER_ROLE) whenNotPaused returns (uint256 shares) {
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

    emit MintAndStake(benefactor, beneficiary, order, route, signature);
  }

  function redeemAndWithdraw(
    address benefactor,
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Signature calldata signature
  ) external override nonReentrant onlyRole(REDEEM_CALLER_ROLE) whenNotPaused returns (uint256 asset) {
    if (beneficiary == address(0)) {
      revert InvalidZeroAddress();
    }
    if (benefactor == address(0)) {
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

    // collateral asset amount
    asset = order.collateral_amount;

    // Transfer usdu from beneficiary to this contract
    // Make sure benefactor approve to proxy contract
    IERC20(usdu).safeTransferFrom(benefactor, address(this), order.usdu_amount);

    IERC20(usdu).approve(address(minting), 0);
    IERC20(usdu).approve(address(minting), order.usdu_amount);
    // redeem usdt from mintingContract
    minting.redeem(order, signature);

    // Transfer usdt to beneficiary
    IERC20(order.collateral_asset).safeTransfer(beneficiary, order.collateral_amount);

    emit RedeemAndWithdraw(benefactor, beneficiary, order, signature);
  }
}
