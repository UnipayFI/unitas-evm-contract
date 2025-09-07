// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IUSDuDefinitions.sol";

/**
 * @title USDu
 * @notice Stable Coin Contract
 * @dev Only a single approved minter can mint new tokens
 */
contract USDu is Ownable2Step, ERC20Burnable, ERC20Permit, IUSDuDefinitions {
  address public minter;

  constructor(address admin) ERC20("USDu", "USDu") ERC20Permit("USDu") {
    if (admin == address(0)) revert ZeroAddressException();
    _transferOwnership(admin);
  }

  function setMinter(address newMinter) external onlyOwner {
    emit MinterUpdated(newMinter, minter);
    minter = newMinter;
  }

  function mint(address to, uint256 amount) external {
    if (msg.sender != minter) revert OnlyMinter();
    _mint(to, amount);
  }

  function renounceOwnership() public view override onlyOwner {
    revert CantRenounceOwnership();
  }
}
