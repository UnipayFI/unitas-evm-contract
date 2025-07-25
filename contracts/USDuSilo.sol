// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../contracts/interfaces/IUSDuSiloDefinitions.sol";

/**
 * @title USDuSilo
 * @notice The Silo allows to store USDu during the stake cooldown process.
 */
contract USDuSilo is IUSDuSiloDefinitions {
  using SafeERC20 for IERC20;

  address immutable STAKING_VAULT;
  IERC20 immutable USDU;

  constructor(address stakingVault, address usdu) {
    STAKING_VAULT = stakingVault;
    USDU = IERC20(usdu);
  }

  modifier onlyStakingVault() {
    if (msg.sender != STAKING_VAULT) revert OnlyStakingVault();
    _;
  }

  function withdraw(address to, uint256 amount) external onlyStakingVault {
    USDU.transfer(to, amount);
  }
}
