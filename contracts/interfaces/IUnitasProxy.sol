// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IUnitasMintingV2.sol";

interface IUnitasProxy {
  // Errors
  error InvalidZeroAddress();
  error InvalidZeroAmount();
  error NoStakedSupply();
  error InvalidStakedState();
  error InvalidBenefactor();
  error InvalidBeneficiary();
  error InvalidSignatureType();
  error InvalidPenaltyRate();

  // Events
  event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event CollateralApproved(address indexed collateralAsset, uint256 allowance);
  event ERC20Rescued(address indexed token, address indexed to, uint256 amount);
  event PenaltyRateSet(uint256 oldRate, uint256 newRate);
  event MultiSigWalletUpdated(address indexed oldMultiSigWallet, address indexed newMultiSigWallet);
  event MintAndStake(
    address indexed benefactor,
    address indexed beneficiary,
    IUnitasMintingV2.Order order,
    IUnitasMintingV2.Route route,
    IUnitasMintingV2.Signature signature
  );
  event RedeemAndWithdraw(
    address indexed benefactor,
    address indexed beneficiary,
    IUnitasMintingV2.Order order,
    IUnitasMintingV2.Signature signature
  );
  event FlashWithdraw(address indexed user, uint256 susduAmount, uint256 usduAmount, uint256 penaltyUsduAmount);

  // Functions
  function approveCollateral(address collateralAsset, uint256 allowance) external;

  function rescueERC20(address token, address to, uint256 amount) external;

  function flashWithdraw(uint256 susduAmount) external;

  function mintAndStake(
    address benefactor,
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Route calldata route,
    IUnitasMintingV2.Signature calldata signature
  ) external returns (uint256 shares);

  function redeemAndWithdraw(
    address benefactor,
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Signature calldata signature
  ) external returns (uint256 asset);
}
