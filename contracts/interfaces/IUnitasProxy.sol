// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IUnitasMintingV2.sol";

interface IUnitasProxy {
  // Errors
  error InvalidZeroAddress();
  error InvalidBenefactor();
  error InvalidBeneficiary();
  error InvalidSignatureType();

  // Events
  event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event CollateralApproved(address indexed collateralAsset, uint256 allowance);
  event ERC20Rescued(address indexed token, address indexed to, uint256 amount);
  event MintAndStake(
    address indexed beneficiary,
    IUnitasMintingV2.Order order,
    IUnitasMintingV2.Route route,
    IUnitasMintingV2.Signature signature
  );

  // Functions
  function approveCollateral(address collateralAsset, uint256 allowance) external;

  function rescueERC20(address token, address to, uint256 amount) external;

  function mintAndStake(
    address beneficiary,
    IUnitasMintingV2.Order calldata order,
    IUnitasMintingV2.Route calldata route,
    IUnitasMintingV2.Signature calldata signature
  ) external returns (uint256 shares);
}
