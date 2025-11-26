# Unitas Evm Contract

## BSC_MAINNET

### Contract Addresses

| Contract Name | Address | Description |
|---|---|---|
| USDu | [0xeA953eA6634d55dAC6697C436B1e81A679Db5882](https://bscscan.com/address/0xeA953eA6634d55dAC6697C436B1e81A679Db5882) | USDu Stablecoin Contract |
| UnitasMintingV2 | [0xbB984CE670100AA855f6152f88b26EE57f4EA82A](https://bscscan.com/address/0xbB984CE670100AA855f6152f88b26EE57f4EA82A) | Minting and Redemption Contract |
| StakedUSDuV2 | [0x385C279445581a186a4182a5503094eBb652EC71](https://bscscan.com/address/0x385C279445581a186a4182a5503094eBb652EC71) | sUSDu Staking Contract |

### Configuration Information

#### Supported Collateral Assets

| Token | Address | Description |
|---|---|---|
| WBNB | [0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c](https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) | Wrapped BNB |
| USDT | [0x55d398326f99059fF775485246999027B3197955](https://bscscan.com/address/0x55d398326f99059fF775485246999027B3197955) | USDT Stablecoin |
| USDC | [0x55d398326f99059fF775485246999027B3197955](https://bscscan.com/address/0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d) | USDC Stablecoin |


#### Per-Block Limits

| Operation | Limit |
|---|---|
| Mint | 10,200,000 USDu |
| Redeem | 2,000,000 USDu |

## BSC_TESTNET

### Contract Addresses

| Contract Name | Address | Description |
|---|---|---|
| USDu | [0x029544a6ef165c84A6E30862C85B996A2BF0f9dE](https://testnet.bscscan.com/address/0x029544a6ef165c84A6E30862C85B996A2BF0f9dE) | USDu Stablecoin Contract |
| UnitasMintingV2 | [0x84E5D5009ab4EE5eCf42eeA5f1B950d39eEFb648](https://testnet.bscscan.com/address/0x84E5D5009ab4EE5eCf42eeA5f1B950d39eEFb648) | Minting and Redemption Contract |
| StakedUSDuV2 | [0x3E7fF623C4Db0128657567D583df71E0297dfcc3](https://testnet.bscscan.com/address/0x3E7fF623C4Db0128657567D583df71E0297dfcc3) | sUSDu Staking Contract |

### Configuration Information

#### Supported Collateral Assets

| Token | Address | Description |
|---|---|---|
| WETH | [0xae13d989dac2f0debff460ac112a837c89baa7cd](https://testnet.bscscan.com/address/0xae13d989dac2f0debff460ac112a837c89baa7cd) | Wrapped BNB |
| USDT | [0x42e3D7f4cfE3B94BCeF3EBaEa832326AcB40C142](https://testnet.bscscan.com/address/0x42e3D7f4cfE3B94BCeF3EBaEa832326AcB40C142) | USDT Stablecoin |

#### Per-Block Limits

| Operation | Limit |
|---|---|
| Mint | 10,200,000 USDu |
| Redeem | 2,000,000 USDu |

### Permission Addresses

#### USDu

| Role / Target | Description | Address |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` | Super admin, can set USDu Minter (must be set to UnitasMintingV2 contract after creation) | [0x8E3811B4Dc5022AB9C8Afbb54Be4Aa23780C62b3](https://app.safe.global/home?safe=bnb:0x8E3811B4Dc5022AB9C8Afbb54Be4Aa23780C62b3) |

#### UnitasMintingV2

| Role / Target | Description | Address |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` | Super admin managing all roles, global limits, and asset configuration | [0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8](https://app.safe.global/home?safe=bnb:0x0a6Db8e8f0b79bA5B9f5AC7F5728843b830bB1c8) |
| `GATEKEEPER_ROLE` | Can disable minting/redemption and remove operational roles in emergencies | [0x111B13fFf5fEa0C6F5f8108c6Faf2454e0BF906f](https://app.safe.global/home?safe=bnb:0x111B13fFf5fEa0C6F5f8108c6Faf2454e0BF906f) |
| `MINTER_ROLE` | Account allowed to execute `mint` / `mintWETH` | [0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6](https://bscscan.com/address/0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6) |
| `REDEEMER_ROLE` | Account allowed to execute `redeem` | [0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6](https://bscscan.com/address/0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6) |
| `COLLATERAL_MANAGER_ROLE` | Asset custody account responsible for calling `transferToCustody` | [0x2A27ccff65A82dF27C4063e6EC6FBE0483065e18](https://app.safe.global/home?safe=bnb:0x2A27ccff65A82dF27C4063e6EC6FBE0483065e18) |
| Custodians | Added custodian wallets (`addCustodianAddress`) | [0xB464C9890604926bd5Fa7b66Bf15d26BCD0eD3A9](https://app.safe.global/home?safe=bnb:0xB464C9890604926bd5Fa7b66Bf15d26BCD0eD3A9) |
| Whitelisted Benefactors | `_whitelistedBenefactors` list | [0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6](https://bscscan.com/address/0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6) |
| Approved Beneficiaries | Beneficiary lists set by each Benefactor | [0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6](https://bscscan.com/address/0x01444f55dD8D6B5ac61e0676B7C9476E52F069c6) |
| Delegated Signers | Signing accounts authorized via `delegatedSigner` | _TBD_ |

#### StakedUSDu / StakedUSDuV2

| Role / Target | Description | Address |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` | Contract owner, manages other roles and key parameters | [0x179650b38B20773393c3a10B3b55ba57780BDBD9](https://app.safe.global/home?safe=bnb:0x179650b38B20773393c3a10B3b55ba57780BDBD9) |
| `REWARDER_ROLE` | Account responsible for calling `transferInRewards` to distribute rewards | [0xE59965162286D67308e2ebb6c34E0e18caEAA4F9](https://app.safe.global/home?safe=bnb:0xE59965162286D67308e2ebb6c34E0e18caEAA4F9) |
| `BLACKLIST_MANAGER_ROLE` | Control account capable of executing `addToBlacklist` / `removeFromBlacklist` | [0xb3478DF92B7126a4f6Ea48Cde27e13c9F7AeB85E](https://app.safe.global/home?safe=bnb:0xb3478DF92B7126a4f6Ea48Cde27e13c9F7AeB85E) |

## Core Contracts

### UnitasMinting

The UnitasMinting contract is responsible for the minting and redemption of the USDu stablecoin.

#### Roles and Permissions

The contract uses role-based access control:

- `MINTER_ROLE`: Role capable of calling the mint function
- `REDEEMER_ROLE`: Role capable of calling the redeem function
- `GATEKEEPER_ROLE`: Super admin capable of disabling minting and redemption functions in emergencies, and removing minter and redeemer roles
- `DEFAULT_ADMIN_ROLE`: Super admin capable of managing other roles

#### Main Functions

##### mint

Mints USDu stablecoin.

```solidity
function mint(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

Parameter Description:

1. `Order`: Order information
```solidity
struct Order {
    OrderType order_type;     // Must be OrderType.MINT (0)
    uint256 expiry;          // Order expiry timestamp
    uint256 nonce;           // Order nonce, used for replay protection
    address benefactor;      // Address paying collateral
    address beneficiary;     // Address receiving USDu
    address collateral_asset; // Collateral token address
    uint256 collateral_amount; // Collateral amount
    uint256 usdu_amount;     // Amount of USDu to mint
}
```

2. `Route`: Collateral distribution route
```solidity
struct Route {
    address[] addresses;    // Array of custodian addresses
    uint256[] ratios;      // Corresponding ratio array, each element represents basis points, sum must equal 10000
}
```

3. `Signature`: Signature information
```solidity
struct Signature {
    SignatureType signature_type; // Must be SignatureType.EIP712 (0)
    bytes signature_bytes;       // EIP712 signature data
}
```

Signature Generation Description:
1. Uses EIP712 standard

2. Domain Parameters:
   - name: "UnitasMinting"
   - version: "1"
   - chainId: Current chain ID
   - verifyingContract: UnitasMinting contract address

3. Order Type Definition:

```solidity
Order(uint8 order_type,uint256 expiry,uint256 nonce,address benefactor,address beneficiary,address collateral_asset,uint256 collateral_amount,uint256 usdu_amount)
```

##### redeem

Redeems USDu for collateral.

```solidity
function redeem(
    Order calldata order,
    Signature calldata signature
) external
```

Parameter Description:

1. `Order`: Order information

```solidity
struct Order {
    OrderType order_type;     // Must be OrderType.REDEEM (1)
    uint256 expiry;          // Order expiry timestamp
    uint256 nonce;           // Order nonce, used for replay protection
    address benefactor;      // Address paying USDu
    address beneficiary;     // Address receiving collateral
    address collateral_asset; // Collateral token address to redeem
    uint256 collateral_amount; // Collateral amount to redeem
    uint256 usdu_amount;     // Amount of USDu to burn
}
```

2. `Signature`: Signature information, format same as mint function

#### Management Functions

1. Asset Management

```solidity
function addSupportedAsset(address asset) external
function removeSupportedAsset(address asset) external
function isSupportedAsset(address asset) external view returns (bool)
```

2. Custodian Address Management

```solidity
function addCustodianAddress(address custodian) external
function removeCustodianAddress(address custodian) external
```

3. Limit Management

```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external
```

4. Signature Delegation

```solidity
function setDelegatedSigner(address _delegateTo) external
function removeDelegatedSigner(address _removedSigner) external
```

#### Events

1. Mint Event

```solidity
event Mint(
    address minter,
    address benefactor,
    address beneficiary,
    address indexed collateral_asset,
    uint256 indexed collateral_amount,
    uint256 indexed usdu_amount
);
```

2. Redeem Event

```solidity
event Redeem(
    address redeemer,
    address benefactor,
    address beneficiary,
    address indexed collateral_asset,
    uint256 indexed collateral_amount,
    uint256 indexed usdu_amount
);
```

3. Other Management Events

```solidity
event AssetAdded(address indexed asset);
event AssetRemoved(address indexed asset);
event CustodianAddressAdded(address indexed custodian);
event CustodianAddressRemoved(address indexed custodian);
event MaxMintPerBlockChanged(uint256 indexed oldMaxMintPerBlock, uint256 indexed newMaxMintPerBlock);
event MaxRedeemPerBlockChanged(uint256 indexed oldMaxRedeemPerBlock, uint256 indexed newMaxRedeemPerBlock);
event DelegatedSignerAdded(address indexed signer, address indexed delegator);
event DelegatedSignerRemoved(address indexed signer, address indexed delegator);
```

#### Error Codes

```solidity
error Duplicate();                 // Duplicate order
error InvalidAddress();            // Invalid address
error InvalidUSDuAddress();        // Invalid USDu address
error InvalidZeroAddress();        // Invalid zero address
error InvalidAssetAddress();       // Invalid asset address
error InvalidCustodianAddress();   // Invalid custodian address
error InvalidOrder();              // Invalid order
error InvalidAmount();             // Invalid amount
error InvalidRoute();              // Invalid route
error UnsupportedAsset();          // Unsupported asset
error NoAssetsProvided();          // No assets provided
error InvalidSignature();          // Invalid signature
error InvalidNonce();              // Invalid nonce
error SignatureExpired();          // Signature expired
error TransferFailed();            // Transfer failed
error MaxMintPerBlockExceeded();   // Exceeded max mint per block
error MaxRedeemPerBlockExceeded(); // Exceeded max redeem per block
```

### UnitasMintingV2

#### Roles and Permissions

Roles and permissions are consistent with V1:

- `MINTER_ROLE`: Role capable of calling the mint function
- `REDEEMER_ROLE`: Role capable of calling the redeem function
- `GATEKEEPER_ROLE`: Super admin capable of disabling minting and redemption functions in emergencies, and removing minter and redeemer roles
- `COLLATERAL_MANAGER_ROLE`: Role capable of transferring collateral to custodian wallets
- `DEFAULT_ADMIN_ROLE`: Super admin capable of managing other roles

#### Main Functions

##### mint

Mints USDu stablecoin.

```solidity
function mint(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

Parameter Description:

1. `Order`: Order information
```solidity
struct Order {
    string order_id;          // Order ID
    OrderType order_type;     // Must be OrderType.MINT (0)
    uint120 expiry;          // Order expiry timestamp
    uint128 nonce;           // Order nonce, used for replay protection
    address benefactor;      // Address paying collateral
    address beneficiary;     // Address receiving USDu
    address collateral_asset; // Collateral token address
    uint128 collateral_amount; // Collateral amount
    uint128 usdu_amount;     // Amount of USDu to mint
}
```

2. `Route`: Collateral distribution route
```solidity
struct Route {
    address[] addresses;    // Array of custodian addresses
    uint128[] ratios;      // Corresponding ratio array, each element represents basis points, sum must equal 10000
}
```

3. `Signature`: Signature information
```solidity
struct Signature {
    SignatureType signature_type; // Can be SignatureType.EIP712 (0) or SignatureType.EIP1271 (1)
    bytes signature_bytes;       // Signature data
}
```

Signature Generation Description:
1. Uses EIP712 standard

2. Domain Parameters:
   - name: "UnitasMinting"
   - version: "1"
   - chainId: Current chain ID
   - verifyingContract: UnitasMintingV2 contract address

3. Order Type Definition:

```solidity
Order(string order_id,uint8 order_type,uint128 expiry,uint120 nonce,address benefactor,address beneficiary,address collateral_asset,uint128 collateral_amount,uint128 usdu_amount)
```

##### mintWETH

Mints USDu using WETH as collateral. This method first converts WETH to ETH, then distributes it to custodian addresses.

```solidity
function mintWETH(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

Parameters are the same as `mint` method, but `collateral_asset` must be the WETH address.

##### redeem

Redeems USDu for collateral.

```solidity
function redeem(
    Order calldata order,
    Signature calldata signature
) external
```

Parameter Description:

1. `Order`: Order information

```solidity
struct Order {
    string order_id;          // Order ID
    OrderType order_type;     // Must be OrderType.REDEEM (1)
    uint120 expiry;          // Order expiry timestamp
    uint128 nonce;           // Order nonce, used for replay protection
    address benefactor;      // Address paying USDu
    address beneficiary;     // Address receiving collateral
    address collateral_asset; // Collateral token address to redeem
    uint128 collateral_amount; // Collateral amount to redeem
    uint128 usdu_amount;     // Amount of USDu to burn
}
```

2. `Signature`: Signature information, format same as mint function

#### Management Functions

1.  Asset Management

    ```solidity
    function addSupportedAsset(address asset, TokenConfig calldata _tokenConfig) external;
    function removeSupportedAsset(address asset) external;
    function isSupportedAsset(address asset) external view returns (bool);
    function setTokenType(address asset, TokenType tokenType) external;
    ```

2.  Custodian Address Management

    ```solidity
    function addCustodianAddress(address custodian) public;
    function removeCustodianAddress(address custodian) external;
    function isCustodianAddress(address custodian) public view returns (bool);
    function transferToCustody(address wallet, address asset, uint128 amount) external;
    ```

3.  Limit Management

    ```solidity
    function setGlobalMaxMintPerBlock(uint128 _globalMaxMintPerBlock) external;
    function setGlobalMaxRedeemPerBlock(uint128 _globalMaxRedeemPerBlock) external;
    function setMaxMintPerBlock(uint128 _maxMintPerBlock, address asset) external;
    function setMaxRedeemPerBlock(uint128 _maxRedeemPerBlock, address asset) external;
    function setStablesDeltaLimit(uint128 _stablesDeltaLimit) external;
    ```

4.  Signature Delegation

    ```solidity
    function setDelegatedSigner(address _delegateTo) external;
    function confirmDelegatedSigner(address _delegatedBy) external;
    function removeDelegatedSigner(address _removedSigner) external;
    ```

5.  Whitelist Management
    ```solidity
    function addWhitelistedBenefactor(address benefactor) public;
    function removeWhitelistedBenefactor(address benefactor) external;
    function setApprovedBeneficiary(address beneficiary, bool status) public;
    ```

#### Events

1.  Mint Event

    ```solidity
    event Mint(
        string indexed order_id,
        address indexed benefactor,
        address indexed beneficiary,
        address minter,
        address collateral_asset,
        uint256 collateral_amount,
        uint256 usdu_amount
    );
    ```

2.  Redeem Event

    ```solidity
    event Redeem(
        string indexed order_id,
        address indexed benefactor,
        address indexed beneficiary,
        address redeemer,
        address collateral_asset,
        uint256 collateral_amount,
        uint256 usdu_amount
    );
    ```

3.  Other Management Events

    ```solidity
    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);
    event BenefactorAdded(address indexed benefactor);
    event BeneficiaryAdded(address indexed benefactor, address indexed beneficiary);
    event BenefactorRemoved(address indexed benefactor);
    event BeneficiaryRemoved(address indexed benefactor, address indexed beneficiary);
    event CustodianAddressAdded(address indexed custodian);
    event CustodianAddressRemoved(address indexed custodian);
    event CustodyTransfer(address indexed wallet, address indexed asset, uint256 amount);
    event USDuSet(address indexed usdu);
    event MaxMintPerBlockChanged(uint256 oldMaxMintPerBlock, uint256 newMaxMintPerBlock, address indexed asset);
    event MaxRedeemPerBlockChanged(uint256 oldMaxRedeemPerBlock, uint256 newMaxRedeemPerBlock, address indexed asset);
    event DelegatedSignerAdded(address indexed signer, address indexed delegator);
    event DelegatedSignerRemoved(address indexed signer, address indexed delegator);
    event DelegatedSignerInitiated(address indexed signer, address indexed delegator);
    event TokenTypeSet(address indexed token, uint256 tokenType);
    ```

#### Error Codes

```solidity
error InvalidAddress();
error InvalidUSDuAddress();
error InvalidZeroAddress();
error InvalidAssetAddress();
error InvalidBenefactorAddress();
error InvalidBeneficiaryAddress();
error InvalidCustodianAddress();
error InvalidOrder();
error InvalidAmount();
error InvalidRoute();
error InvalidStablePrice();
error UnknownSignatureType();
error UnsupportedAsset();
error NoAssetsProvided();
error BenefactorNotWhitelisted();
error BeneficiaryNotApproved();
error InvalidEIP712Signature();
error InvalidEIP1271Signature();
error InvalidNonce();
error SignatureExpired();
error TransferFailed();
error DelegationNotInitiated();
error MaxMintPerBlockExceeded();
error MaxRedeemPerBlockExceeded();
error GlobalMaxMintPerBlockExceeded();
error GlobalMaxRedeemPerBlockExceeded();
```


### StakedUSDu & StakedUSDuV2

`StakedUSDu` is a vault contract based on the OpenZeppelin ERC4626 standard, allowing users to stake USDu to earn rewards. `StakedUSDuV2` adds a withdrawal Cooldown mechanism on top of this.

#### Roles and Permissions

- `REWARDER_ROLE`: Role allowed to distribute rewards to the contract.
- `BLACKLIST_MANAGER_ROLE`: Role allowed to add addresses to or remove them from the blacklist.
- `SOFT_RESTRICTED_STAKER_ROLE`: "Soft restricted" role; addresses added cannot stake (`deposit`).
- `FULL_RESTRICTED_STAKER_ROLE`: "Fully restricted" role (blacklist); addresses added cannot perform any operations (stake, withdraw, transfer).
- `DEFAULT_ADMIN_ROLE`: Super admin, can manage the above roles and key parameters of the contract.

#### Main Functions

##### Staking Process

Users can obtain `sUSDu` shares by depositing `USDu`.

```solidity
// Stake based on asset amount
function deposit(uint256 assets, address receiver) external returns (uint256 shares)

// Stake based on share amount
function mint(uint256 shares, address receiver) external returns (uint256 assets)
```

##### Withdrawal Process

The withdrawal process is divided into two modes, determined by the `cooldownDuration` parameter in the `StakedUSDuV2` contract.


**Cooldown Withdrawal (V2 `cooldownDuration` > 0)**

In this mode, standard `withdraw` and `redeem` methods are disabled. Users must first initiate a cooldown request and wait for the cooldown period to end before finally withdrawing assets.

Currently `cooldownDuration` is 7 days.

1.  **Initiate Cooldown**
    ```solidity
    // Initiate cooldown based on asset amount
    function cooldownAssets(uint256 assets) external returns (uint256 shares)

    // Initiate cooldown based on share amount
    function cooldownShares(uint256 shares) external returns (uint256 assets)
    ```

2.  **Execute Withdrawal**
    Wait for `cooldownDuration` time to end, then call this method to complete the withdrawal.
    ```solidity
    function unstake(address receiver) external
    ```

##### Get Cooldown

Query user `cooldown` information

```solidity
struct UserCooldown {
  uint104 cooldownEnd; // Expiry time
  uint256 underlyingAmount; // Claimable amount
}

function cooldowns(address owner) external view returns (UserCooldown memory userCooldown);
```

##### Get VestingAmount and UnvestedAmount

```solidity
/// Get the vestingAmount for this period
function vestingAmount() external view returns (uint256);

/// Get the amount of rewards not yet unlocked in this period
function getUnvestedAmount() external view returns (uint256);
```

#### Management Functions

1.  **Blacklist Management** (`BLACKLIST_MANAGER_ROLE`)
    ```solidity
    function addToBlacklist(address target, bool isFullBlacklisting) external
    function removeFromBlacklist(address target, bool isFullBlacklisting) external
    ```

2.  **Reward Management** (`REWARDER_ROLE`)
    ```solidity
    function transferInRewards(uint256 amount) external
    ```

3.  **Emergency Situations** (`DEFAULT_ADMIN_ROLE`)
    ```solidity
    // Redistribute balance of fully blacklisted addresses
    function redistributeLockedAmount(address from, address to) external
    // Recover accidentally transferred non-core assets
    function rescueTokens(address token, uint256 amount, address to) external
    ```

4.  **V2 Configuration** (`DEFAULT_ADMIN_ROLE`)
    ```solidity
    function setCooldownDuration(uint24 duration) external
    ```

#### Events

```solidity
event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
event RewardsReceived(uint256 amount, uint256 newVestingAmount);
event LockedAmountRedistributed(address indexed from, address indexed to, uint256 amountToDistribute);
// V2 Only
event CooldownDurationUpdated(uint24 previousDuration, uint24 newDuration);
```

#### Error Codes

```solidity
error InvalidAmount();
error CantBlacklistOwner();
error InvalidZeroAddress();
error StillVesting();
error InvalidToken();
error OperationNotAllowed();
error MinSharesViolation();
// V2 Only
error InvalidCooldown();
error ExcessiveWithdrawAmount();
error ExcessiveRedeemAmount();
```
