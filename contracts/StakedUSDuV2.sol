// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./StakedUSDu.sol";
import "./interfaces/IStakedUSDuCooldown.sol";
import "./USDuSilo.sol";

/**
 * @title StakedUSDuV2
 * @notice The StakedUSDuV2 contract allows users to stake USDu tokens and earn a portion of protocol LST and perpetual yield that is allocated
 * to stakers by the Unitas DAO governance voted yield distribution algorithm.  The algorithm seeks to balance the stability of the protocol by funding
 * the protocol's insurance fund, DAO activities, and rewarding stakers with a portion of the protocol's yield.
 * @dev If cooldown duration is set to zero, the StakedUSDuV2 behavior changes to follow ERC4626 standard and disables cooldownShares and cooldownAssets methods. If cooldown duration is greater than zero, the ERC4626 withdrawal and redeem functions are disabled, breaking the ERC4626 standard, and enabling the cooldownShares and the cooldownAssets functions.
 */
contract StakedUSDuV2 is IStakedUSDuCooldown, StakedUSDu {
  using SafeERC20 for IERC20;

  mapping(address => UserCooldown) public cooldowns;

  USDuSilo public immutable silo;

  uint24 public constant MAX_COOLDOWN_DURATION = 90 days;

  uint24 public cooldownDuration;

  /// @notice ensure cooldownDuration is zero
  modifier ensureCooldownOff() {
    if (cooldownDuration != 0) revert OperationNotAllowed();
    _;
  }

  /// @notice ensure cooldownDuration is gt 0
  modifier ensureCooldownOn() {
    if (cooldownDuration == 0) revert OperationNotAllowed();
    _;
  }

  /// @notice Constructor for StakedUSDuV2 contract.
  /// @param _asset The address of the USDu token.
  /// @param initialRewarder The address of the initial rewarder.
  /// @param owner The address of the admin role.
  constructor(IERC20 _asset, address initialRewarder, address owner) StakedUSDu(_asset, initialRewarder, owner) {
    silo = new USDuSilo(address(this), address(_asset));
    cooldownDuration = MAX_COOLDOWN_DURATION;
  }

  /* ------------- EXTERNAL ------------- */

  /**
   * @dev See {IERC4626-withdraw}.
   */
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual override ensureCooldownOff returns (uint256) {
    return super.withdraw(assets, receiver, owner);
  }

  /**
   * @dev See {IERC4626-redeem}.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual override ensureCooldownOff returns (uint256) {
    return super.redeem(shares, receiver, owner);
  }

  /// @notice Claim the staking amount after the cooldown has finished. The address can only retire the full amount of assets.
  /// @dev unstake can be called after cooldown have been set to 0, to let accounts to be able to claim remaining assets locked at Silo
  /// @param receiver Address to send the assets by the staker
  function unstake(address receiver) external {
    if (hasRole(FULL_RESTRICTED_STAKER_ROLE, _msgSender()) || hasRole(FULL_RESTRICTED_STAKER_ROLE, receiver)) {
      revert OperationNotAllowed();
    }

    UserCooldown storage userCooldown = cooldowns[msg.sender];
    uint256 assets = userCooldown.underlyingAmount;

    if (block.timestamp >= userCooldown.cooldownEnd || cooldownDuration == 0) {
      userCooldown.cooldownEnd = 0;
      userCooldown.underlyingAmount = 0;

      silo.withdraw(receiver, assets);
    } else {
      revert InvalidCooldown();
    }
  }

  /// @notice redeem assets and starts a cooldown to claim the converted underlying asset
  /// @param assets assets to redeem
  function cooldownAssets(uint256 assets) external ensureCooldownOn returns (uint256) {
    if (assets > maxWithdraw(_msgSender())) revert ExcessiveWithdrawAmount();

    uint256 shares = previewWithdraw(assets);

    cooldowns[_msgSender()].cooldownEnd = uint104(block.timestamp) + cooldownDuration;
    cooldowns[_msgSender()].underlyingAmount += assets;

    _withdraw(_msgSender(), address(silo), _msgSender(), assets, shares);

    return shares;
  }

  /// @notice redeem shares into assets and starts a cooldown to claim the converted underlying asset
  /// @param shares shares to redeem
  function cooldownShares(uint256 shares) external ensureCooldownOn returns (uint256) {
    if (shares > maxRedeem(_msgSender())) revert ExcessiveRedeemAmount();

    uint256 assets = previewRedeem(shares);

    cooldowns[_msgSender()].cooldownEnd = uint104(block.timestamp) + cooldownDuration;
    cooldowns[_msgSender()].underlyingAmount += assets;

    _withdraw(_msgSender(), address(silo), _msgSender(), assets, shares);

    return assets;
  }

  /// @notice Set cooldown duration. If cooldown duration is set to zero, the StakedUSDuV2 behavior changes to follow ERC4626 standard and disables cooldownShares and cooldownAssets methods. If cooldown duration is greater than zero, the ERC4626 withdrawal and redeem functions are disabled, breaking the ERC4626 standard, and enabling the cooldownShares and the cooldownAssets functions.
  /// @param duration Duration of the cooldown
  function setCooldownDuration(uint24 duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (duration > MAX_COOLDOWN_DURATION) {
      revert InvalidCooldown();
    }

    uint24 previousDuration = cooldownDuration;
    cooldownDuration = duration;
    emit CooldownDurationUpdated(previousDuration, cooldownDuration);
  }
}
