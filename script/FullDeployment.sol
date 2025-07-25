// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DeploymentUtils.sol";
import "forge-std/Script.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import "../contracts/StakedUSDu.sol";
import "../contracts/interfaces/IUSDu.sol";
import "../contracts/mock/MockToken.sol";
import "../contracts/USDu.sol";
import "../contracts/StakedUSDu.sol";
import "../contracts/interfaces/IUnitasMinting.sol";
import "../contracts/UnitasMinting.sol";
import "../contracts/WETH9.sol";

// This deployment uses CREATE2 to ensure that only the modified contracts are deployed
contract FullDeployment is Script, DeploymentUtils {
  struct Contracts {
    // Mock tokens
    MockToken stEth;
    // MockToken rETH;
    // MockToken cbETH;
    // MockToken usdc;
    // MockToken usdt;
    // MockToken wbETH;
    address weth9;
    // E-tokens
    USDu USDuToken;
    StakedUSDu stakedUSDu;
    // E-contracts
    UnitasMinting unitasMintingContract;
  }

  struct Configuration {
    // Roles
    bytes32 usduMinterRole;
  }
  // bytes32 stakedUSDuTokenMinterRole;
  // bytes32 stakingRewarderRole;

  address public constant ZERO_ADDRESS = address(0);
  // versioning to enable forced redeploys
  bytes32 public constant SALT = bytes32("Unitas0.0.15");
  uint256 public constant MAX_USDU_MINT_PER_BLOCK = 100_000e18;
  uint256 public constant MAX_USDU_REDEEM_PER_BLOCK = 100_000e18;

  function run() public virtual {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    deployment(deployerPrivateKey);
  }

  function deployment(uint256 deployerPrivateKey) public returns (Contracts memory) {
    address deployerAddress = vm.addr(deployerPrivateKey);
    Contracts memory contracts;

    contracts.weth9 = _create2Deploy(SALT, type(WETH9).creationCode, bytes(""));

    vm.startBroadcast(deployerPrivateKey);

    contracts.USDuToken = USDu(_create2Deploy(SALT, type(USDu).creationCode, abi.encode(deployerAddress)));

    // Checks the USDu owner
    _utilsIsOwner(deployerAddress, address(contracts.USDuToken));

    contracts.stakedUSDu = StakedUSDu(
      _create2Deploy(
        SALT, type(StakedUSDu).creationCode, abi.encode(address(contracts.USDuToken), deployerAddress, deployerAddress)
      )
    );

    // Checks the staking owner and admin
    _utilsIsOwner(deployerAddress, address(contracts.stakedUSDu));
    _utilsHasRole(contracts.stakedUSDu.DEFAULT_ADMIN_ROLE(), deployerAddress, address(contracts.stakedUSDu));

    IUSDu iUSDu = IUSDu(address(contracts.USDuToken));

    // stEth //
    contracts.stEth = MockToken(
      _create2Deploy(
        SALT, type(MockToken).creationCode, abi.encode("Mocked stETH", "stETH", uint256(18), deployerAddress)
      )
    );
    // rETH //
    // contracts.rETH = MockToken(
    //   _create2Deploy(
    //     SALT,
    //     type(MockToken).creationCode,
    //     abi.encode('Mocked rETH', 'rETH', uint256(18), deployerAddress)
    //   )
    // );
    // // cbETH //
    // contracts.cbETH = MockToken(
    //   _create2Deploy(
    //     SALT,
    //     type(MockToken).creationCode,
    //     abi.encode('Mocked cbETH', 'cbETH', uint256(18), deployerAddress)
    //   )
    // );
    // // USDC //
    // contracts.usdc = MockToken(
    //   _create2Deploy(SALT, type(MockToken).creationCode, abi.encode('Mocked USDC', 'USDC', uint256(6), deployerAddress))
    // );
    // // USDT //
    // contracts.usdt = MockToken(
    //   _create2Deploy(SALT, type(MockToken).creationCode, abi.encode('Mocked USDT', 'USDT', uint256(6), deployerAddress))
    // );
    // // WBETH //
    // contracts.wbETH = MockToken(
    //   _create2Deploy(
    //     SALT,
    //     type(MockToken).creationCode,
    //     abi.encode('Mocked WBETH', 'WBETH', uint256(6), deployerAddress)
    //   )
    // );

    // Unitas Minting
    address[] memory assets = new address[](2);
    assets[0] = address(contracts.stEth);

    // assets[1] = address(contracts.cbETH);
    // assets[2] = address(contracts.rETH);
    // assets[3] = address(contracts.usdc);
    // assets[4] = address(contracts.usdt);
    // assets[5] = address(contracts.wbETH);
    // ETH
    assets[1] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address[] memory custodians = new address[](1);
    // copper address
    custodians[0] = address(0x6b95F243959329bb88F5D3Df9A7127Efba703fDA);

    contracts.unitasMintingContract = UnitasMinting(
      payable(
        _create2Deploy(
          SALT,
          type(UnitasMinting).creationCode,
          abi.encode(iUSDu, assets, custodians, deployerAddress, MAX_USDU_MINT_PER_BLOCK, MAX_USDU_REDEEM_PER_BLOCK)
        )
      )
    );

    // give minting contract USDu minter role
    contracts.USDuToken.setMinter(address(contracts.unitasMintingContract));

    // Checks the minting owner and admin
    _utilsIsOwner(deployerAddress, address(contracts.unitasMintingContract));

    _utilsHasRole(
      contracts.unitasMintingContract.DEFAULT_ADMIN_ROLE(), deployerAddress, address(contracts.unitasMintingContract)
    );

    vm.stopBroadcast();

    string memory blockExplorerUrl = "https://sepolia.etherscan.io";

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    if (chainId == 1) {
      blockExplorerUrl = "https://etherscan.io";
    } else if (chainId == 5) {
      blockExplorerUrl = "https://goerli.etherscan.io";
    } else if (chainId == 137) {
      blockExplorerUrl = "https://polygonscan.com";
    }

    // Logs
    console.log("=====> All Unitas contracts deployed ....");
    console.log("USDu                          : %s/address/%s", blockExplorerUrl, address(contracts.USDuToken));
    console.log("StakedUSDu                     : %s/address/%s", blockExplorerUrl, address(contracts.stakedUSDu));
    console.log("stETH                         : %s/address/%s", blockExplorerUrl, address(contracts.stEth));
    // console.log('rETH                          : %s/address/%s', blockExplorerUrl, address(contracts.rETH));
    // console.log('cbETH                         : %s/address/%s', blockExplorerUrl, address(contracts.cbETH));
    console.log("WETH9                         : %s/address/%s", blockExplorerUrl, address(contracts.weth9));
    // console.log('USDC                          : %s/address/%s', blockExplorerUrl, address(contracts.usdc));
    // console.log('USDT                          : %s/address/%s', blockExplorerUrl, address(contracts.usdt));
    // console.log('WBETH                         : %s/address/%s', blockExplorerUrl, address(contracts.wbETH));
    console.log(
      "Unitas Minting                  : %s/address/%s", blockExplorerUrl, address(contracts.unitasMintingContract)
    );
    return contracts;
  }
}
