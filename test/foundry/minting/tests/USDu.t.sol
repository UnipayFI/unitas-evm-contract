// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* solhint-disable private-vars-leading-underscore  */

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";
import {Vm} from "forge-std/Vm.sol";

import "../../../../contracts/USDu.sol";
import "../UnitasMinting.utils.sol";

contract USDuTest is Test, IUSDuDefinitions, UnitasMintingUtils {
  USDu internal _usduToken;

  uint256 internal _ownerPrivateKey;
  uint256 internal _newOwnerPrivateKey;
  uint256 internal _minterPrivateKey;
  uint256 internal _newMinterPrivateKey;

  address internal _owner;
  address internal _newOwner;
  address internal _minter;
  address internal _newMinter;

  function setUp() public virtual override {
    _ownerPrivateKey = 0xA11CE;
    _newOwnerPrivateKey = 0xA14CE;
    _minterPrivateKey = 0xB44DE;
    _newMinterPrivateKey = 0xB45DE;

    _owner = vm.addr(_ownerPrivateKey);
    _newOwner = vm.addr(_newOwnerPrivateKey);
    _minter = vm.addr(_minterPrivateKey);
    _newMinter = vm.addr(_newMinterPrivateKey);

    vm.label(_minter, "minter");
    vm.label(_owner, "owner");
    vm.label(_newMinter, "_newMinter");
    vm.label(_newOwner, "newOwner");

    _usduToken = new USDu(_owner);
    vm.prank(_owner);
    _usduToken.setMinter(_minter);
  }

  function testCorrectInitialConfig() public view {
    assertEq(_usduToken.owner(), _owner);
    assertEq(_usduToken.minter(), _minter);
  }

  function testCantInitWithNoOwner() public {
    vm.expectRevert(ZeroAddressExceptionErr);
    new USDu(address(0));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.prank(_owner);
    vm.expectRevert(CantRenounceOwnershipErr);
    _usduToken.renounceOwnership();
    assertEq(_usduToken.owner(), _owner);
    assertNotEq(_usduToken.owner(), address(0));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(_owner);
    _usduToken.transferOwnership(_newOwner);
    assertEq(_usduToken.owner(), _owner);
    assertNotEq(_usduToken.owner(), _newOwner);
  }

  function testCanTransferOwnership() public {
    vm.prank(_owner);
    _usduToken.transferOwnership(_newOwner);
    vm.prank(_newOwner);
    _usduToken.acceptOwnership();
    assertEq(_usduToken.owner(), _newOwner);
    assertNotEq(_usduToken.owner(), _owner);
  }

  function testCanCancelOwnershipChange() public {
    vm.startPrank(_owner);
    _usduToken.transferOwnership(_newOwner);
    _usduToken.transferOwnership(address(0));
    vm.stopPrank();

    vm.prank(_newOwner);
    vm.expectRevert("Ownable2Step: caller is not the new owner");
    _usduToken.acceptOwnership();
    assertEq(_usduToken.owner(), _owner);
    assertNotEq(_usduToken.owner(), _newOwner);
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(_owner);
    _usduToken.transferOwnership(_newOwner);
    vm.startPrank(_newOwner);
    _usduToken.acceptOwnership();
    _usduToken.setMinter(_newMinter);
    vm.stopPrank();
    assertEq(_usduToken.minter(), _newMinter);
    assertNotEq(_usduToken.minter(), _minter);
  }

  function testOnlyOwnerCanSetMinter() public {
    vm.prank(_newOwner);
    vm.expectRevert("Ownable: caller is not the owner");
    _usduToken.setMinter(_newMinter);
    assertEq(_usduToken.minter(), _minter);
  }

  function testOwnerCantMint() public {
    vm.prank(_owner);
    vm.expectRevert(OnlyMinterErr);
    _usduToken.mint(_newMinter, 100);
  }

  function testMinterCanMint() public {
    assertEq(_usduToken.balanceOf(_newMinter), 0);
    vm.prank(_minter);
    _usduToken.mint(_newMinter, 100);
    assertEq(_usduToken.balanceOf(_newMinter), 100);
  }

  function testMinterCantMintToZeroAddress() public {
    vm.prank(_minter);
    vm.expectRevert("ERC20: mint to the zero address");
    _usduToken.mint(address(0), 100);
  }

  function testNewMinterCanMint() public {
    assertEq(_usduToken.balanceOf(_newMinter), 0);
    vm.prank(_owner);
    _usduToken.setMinter(_newMinter);
    vm.prank(_newMinter);
    _usduToken.mint(_newMinter, 100);
    assertEq(_usduToken.balanceOf(_newMinter), 100);
  }

  function testOldMinterCantMint() public {
    assertEq(_usduToken.balanceOf(_newMinter), 0);
    vm.prank(_owner);
    _usduToken.setMinter(_newMinter);
    vm.prank(_minter);
    vm.expectRevert(OnlyMinterErr);
    _usduToken.mint(_newMinter, 100);
    assertEq(_usduToken.balanceOf(_newMinter), 0);
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(_owner);
    _usduToken.transferOwnership(_newOwner);
    vm.prank(_newOwner);
    _usduToken.acceptOwnership();
    assertNotEq(_usduToken.owner(), _owner);
    assertEq(_usduToken.owner(), _newOwner);
    vm.prank(_owner);
    vm.expectRevert("Ownable: caller is not the owner");
    _usduToken.transferOwnership(_newMinter);
    assertEq(_usduToken.owner(), _newOwner);
  }

  function testOldOwnerCantSetMinter() public {
    vm.prank(_owner);
    _usduToken.transferOwnership(_newOwner);
    vm.prank(_newOwner);
    _usduToken.acceptOwnership();
    assertNotEq(_usduToken.owner(), _owner);
    assertEq(_usduToken.owner(), _newOwner);
    vm.prank(_owner);
    vm.expectRevert("Ownable: caller is not the owner");
    _usduToken.setMinter(_newMinter);
    assertEq(_usduToken.minter(), _minter);
  }
}
