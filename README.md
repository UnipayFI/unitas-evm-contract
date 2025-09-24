# Unitas Evm Contract

## BSC_TESTNET

### 合约地址

| 合约名称 | 地址 | 说明 |
|---------|------|------|
| USDu | [0xabFD3253fD009414b2911543880972d98F2Facd2](https://testnet.bscscan.com/address/0xabFD3253fD009414b2911543880972d98F2Facd2) | USDu 稳定币合约 |
| UnitasMintingV2 | [0x0A9133ab7BE00887D89F77d4aE3f999963DF4A03](https://testnet.bscscan.com/address/0x0A9133ab7BE00887D89F77d4aE3f999963DF4A03) | 铸造和赎回合约 |
| StakedUSDuV2 | [0xfaf2A0372742A305817f5a634cA8E1C75a3Cf3E1](https://testnet.bscscan.com/address/0xfaf2A0372742A305817f5a634cA8E1C75a3Cf3E1) | sUSDu 质押合约 |
| USDUSilo | [0xcB2Cea5CF51Bf346406Db6c64a9BA40380F217A0](https://testnet.bscscan.com/address/0xcB2Cea5CF51Bf346406Db6c64a9BA40380F217A0) | USDu  资金合约 |

### 配置信息

#### 支持的抵押资产

| 代币 | 地址 | 说明 |
|------|------|------|
| WETH | [0xae13d989dac2f0debff460ac112a837c89baa7cd](https://testnet.bscscan.com/address/0xae13d989dac2f0debff460ac112a837c89baa7cd) | Wrap BNB |
| USDT | [0x337610d27c682e347c9cd60bd4b3b107c9d34ddd](https://testnet.bscscan.com/address/0x337610d27c682e347c9cd60bd4b3b107c9d34ddd) | USDT 稳定币 |
| USDC | [0xfe146E53b08E4204A26E3cC5037077bAa52EB174](https://testnet.bscscan.com/address/0xfe146E53b08E4204A26E3cC5037077bAa52EB174) | mUSDT 稳定币 |

#### 每区块限额

| 操作 | 限额 |
|------|------|
| 铸造 | 10,200,000 USDu |
| 赎回 | 2,000,000 USDu |

## 主要合约

### UnitasMinting

UnitasMinting 合约负责 USDu 稳定币的铸造和赎回功能。

#### 角色和权限

合约使用基于角色的访问控制：

- `MINTER_ROLE`: 可以调用 mint 方法的角色
- `REDEEMER_ROLE`: 可以调用 redeem 方法的角色
- `GATEKEEPER_ROLE`: 可以在紧急情况下禁用铸造和赎回功能，以及移除 minter 和 redeemer 角色的超级管理员
- `DEFAULT_ADMIN_ROLE`: 可以管理其他角色的超级管理员

#### 主要方法

##### mint

铸造 USDu 稳定币。

```solidity
function mint(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

参数说明：

1. `Order`: 订单信息
```solidity
struct Order {
    OrderType order_type;     // 必须为 OrderType.MINT (0)
    uint256 expiry;          // 订单过期时间戳
    uint256 nonce;           // 订单随机数，用于防重放
    address benefactor;      // 支付抵押物的地址
    address beneficiary;     // 接收 USDu 的地址
    address collateral_asset; // 抵押物代币地址
    uint256 collateral_amount; // 抵押物数量
    uint256 usdu_amount;     // 要铸造的 USDu 数量
}
```

2. `Route`: 抵押物分发路由
```solidity
struct Route {
    address[] addresses;    // 托管地址数组
    uint256[] ratios;      // 对应的比例数组，每个元素代表万分之几，总和必须等于 10000
}
```

3. `Signature`: 签名信息
```solidity
struct Signature {
    SignatureType signature_type; // 必须为 SignatureType.EIP712 (0)
    bytes signature_bytes;       // EIP712 签名数据
}
```

签名生成说明：
1. 使用 EIP712 标准

2. Domain 参数:
   - name: "UnitasMinting"
   - version: "1"
   - chainId: 当前链 ID
   - verifyingContract: UnitasMinting 合约地址

3. Order 类型定义:

```solidity
Order(uint8 order_type,uint256 expiry,uint256 nonce,address benefactor,address beneficiary,address collateral_asset,uint256 collateral_amount,uint256 usdu_amount)
```

##### redeem

赎回 USDu 换回抵押物。

```solidity
function redeem(
    Order calldata order,
    Signature calldata signature
) external
```

参数说明：

1. `Order`: 订单信息

```solidity
struct Order {
    OrderType order_type;     // 必须为 OrderType.REDEEM (1)
    uint256 expiry;          // 订单过期时间戳
    uint256 nonce;           // 订单随机数，用于防重放
    address benefactor;      // 支付 USDu 的地址
    address beneficiary;     // 接收抵押物的地址
    address collateral_asset; // 要赎回的抵押物代币地址
    uint256 collateral_amount; // 要赎回的抵押物数量
    uint256 usdu_amount;     // 要销毁的 USDu 数量
}
```

2. `Signature`: 签名信息，格式同 mint 方法

#### 管理方法

1. 资产管理

```solidity
function addSupportedAsset(address asset) external
function removeSupportedAsset(address asset) external
function isSupportedAsset(address asset) external view returns (bool)
```

2. 托管地址管理

```solidity
function addCustodianAddress(address custodian) external
function removeCustodianAddress(address custodian) external
```

3. 限额管理

```solidity
function setMaxMintPerBlock(uint256 _maxMintPerBlock) external
function setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) external
```

4. 签名委托

```solidity
function setDelegatedSigner(address _delegateTo) external
function removeDelegatedSigner(address _removedSigner) external
```

#### 事件

1. 铸造事件

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

2. 赎回事件

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

3. 其他管理事件

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

#### 错误码

```solidity
error Duplicate();                 // 订单重复
error InvalidAddress();            // 地址无效
error InvalidUSDuAddress();        // USDu 地址无效
error InvalidZeroAddress();        // 零地址无效
error InvalidAssetAddress();       // 资产地址无效
error InvalidCustodianAddress();   // 托管地址无效
error InvalidOrder();              // 订单无效
error InvalidAmount();             // 金额无效
error InvalidRoute();              // 路由无效
error UnsupportedAsset();          // 不支持的资产
error NoAssetsProvided();          // 未提供资产
error InvalidSignature();          // 签名无效
error InvalidNonce();              // nonce 无效
error SignatureExpired();          // 签名过期
error TransferFailed();            // 转账失败
error MaxMintPerBlockExceeded();   // 超过每块最大铸造量
error MaxRedeemPerBlockExceeded(); // 超过每块最大赎回量
```

### UnitasMintingV2

#### 角色和权限

角色和权限与 V1 版本基本一致：

- `MINTER_ROLE`: 可以调用 mint 方法的角色
- `REDEEMER_ROLE`: 可以调用 redeem 方法的角色
- `GATEKEEPER_ROLE`: 可以在紧急情况下禁用铸造和赎回功能，以及移除 minter 和 redeemer 角色的超级管理员
- `COLLATERAL_MANAGER_ROLE`: 可以将抵押品转移到托管钱包的角色
- `DEFAULT_ADMIN_ROLE`: 可以管理其他角色的超级管理员

#### 主要方法

##### mint

铸造 USDu 稳定币。

```solidity
function mint(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

参数说明：

1. `Order`: 订单信息
```solidity
struct Order {
    string order_id;          // 订单 ID
    OrderType order_type;     // 必须为 OrderType.MINT (0)
    uint120 expiry;          // 订单过期时间戳
    uint128 nonce;           // 订单随机数，用于防重放
    address benefactor;      // 支付抵押物的地址
    address beneficiary;     // 接收 USDu 的地址
    address collateral_asset; // 抵押物代币地址
    uint128 collateral_amount; // 抵押物数量
    uint128 usdu_amount;     // 要铸造的 USDu 数量
}
```

2. `Route`: 抵押物分发路由
```solidity
struct Route {
    address[] addresses;    // 托管地址数组
    uint128[] ratios;      // 对应的比例数组，每个元素代表万分之几，总和必须等于 10000
}
```

3. `Signature`: 签名信息
```solidity
struct Signature {
    SignatureType signature_type; // 可为 SignatureType.EIP712 (0) 或 SignatureType.EIP1271 (1)
    bytes signature_bytes;       // 签名数据
}
```

签名生成说明：
1. 使用 EIP712 标准

2. Domain 参数:
   - name: "UnitasMinting"
   - version: "1"
   - chainId: 当前链 ID
   - verifyingContract: UnitasMintingV2 合约地址

3. Order 类型定义:

```solidity
Order(string order_id,uint8 order_type,uint128 expiry,uint120 nonce,address benefactor,address beneficiary,address collateral_asset,uint128 collateral_amount,uint128 usdu_amount)
```

##### mintWETH

使用 WETH 作为抵押物铸造 USDu。此方法会先将 WETH 兑换成 ETH，然后分发到托管地址。

```solidity
function mintWETH(
    Order calldata order,
    Route calldata route,
    Signature calldata signature
) external
```

参数与 `mint` 方法相同，但 `collateral_asset` 必须是 WETH 地址。

##### redeem

赎回 USDu 换回抵押物。

```solidity
function redeem(
    Order calldata order,
    Signature calldata signature
) external
```

参数说明：

1. `Order`: 订单信息

```solidity
struct Order {
    string order_id;          // 订单 ID
    OrderType order_type;     // 必须为 OrderType.REDEEM (1)
    uint120 expiry;          // 订单过期时间戳
    uint128 nonce;           // 订单随机数，用于防重放
    address benefactor;      // 支付 USDu 的地址
    address beneficiary;     // 接收抵押物的地址
    address collateral_asset; // 要赎回的抵押物代币地址
    uint128 collateral_amount; // 要赎回的抵押物数量
    uint128 usdu_amount;     // 要销毁的 USDu 数量
}
```

2. `Signature`: 签名信息，格式同 mint 方法

#### 管理方法

1.  资产管理

    ```solidity
    function addSupportedAsset(address asset, TokenConfig calldata _tokenConfig) external;
    function removeSupportedAsset(address asset) external;
    function isSupportedAsset(address asset) external view returns (bool);
    function setTokenType(address asset, TokenType tokenType) external;
    ```

2.  托管地址管理

    ```solidity
    function addCustodianAddress(address custodian) public;
    function removeCustodianAddress(address custodian) external;
    function isCustodianAddress(address custodian) public view returns (bool);
    function transferToCustody(address wallet, address asset, uint128 amount) external;
    ```

3.  限额管理

    ```solidity
    function setGlobalMaxMintPerBlock(uint128 _globalMaxMintPerBlock) external;
    function setGlobalMaxRedeemPerBlock(uint128 _globalMaxRedeemPerBlock) external;
    function setMaxMintPerBlock(uint128 _maxMintPerBlock, address asset) external;
    function setMaxRedeemPerBlock(uint128 _maxRedeemPerBlock, address asset) external;
    function setStablesDeltaLimit(uint128 _stablesDeltaLimit) external;
    ```

4.  签名委托

    ```solidity
    function setDelegatedSigner(address _delegateTo) external;
    function confirmDelegatedSigner(address _delegatedBy) external;
    function removeDelegatedSigner(address _removedSigner) external;
    ```

5.  白名单管理
    ```solidity
    function addWhitelistedBenefactor(address benefactor) public;
    function removeWhitelistedBenefactor(address benefactor) external;
    function setApprovedBeneficiary(address beneficiary, bool status) public;
    ```

#### 事件

1.  铸造事件

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

2.  赎回事件

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

3.  其他管理事件

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

#### 错误码

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

`StakedUSDu` 是一个基于 OpenZeppelin ERC4626 标准的金库合约，允许用户质押 USDu 来获取收益。`StakedUSDuV2` 在此基础上增加了提款冷却（Cooldown）机制。

#### 角色和权限

- `REWARDER_ROLE`: 允许向合约中分发奖励的角色。
- `BLACKLIST_MANAGER_ROLE`: 允许将地址加入黑名单或从中移除的角色。
- `SOFT_RESTRICTED_STAKER_ROLE`: “软限制”角色，被添加的地址将无法进行质押（`deposit`）。
- `FULL_RESTRICTED_STAKER_ROLE`: “完全限制”角色（黑名单），被添加的地址无法进行任何操作（质押、提款、转账）。
- `DEFAULT_ADMIN_ROLE`: 超级管理员，可以管理以上角色以及合约的关键参数。

#### 主要方法

##### 质押流程

用户可以通过存入 `USDu` 来获取 `sUSDu` 份额。

```solidity
// 根据资产数量进行质押
function deposit(uint256 assets, address receiver) external returns (uint256 shares)

// 根据份额数量进行质押
function mint(uint256 shares, address receiver) external returns (uint256 assets)
```

##### 提款流程

提款流程分为两种模式，由 `StakedUSDuV2` 合约中的 `cooldownDuration` 参数决定。


**冷却提款 (V2 `cooldownDuration` > 0)**

在此模式下，标准的 `withdraw` 和 `redeem` 方法会被禁用。用户必须先发起一个冷却请求，等待冷却期结束后才能最终取出资产。

目前`cooldownDuration`为 7 天

1.  **发起冷却**
    ```solidity
    // 根据资产数量发起冷却
    function cooldownAssets(uint256 assets, address owner) external returns (uint256 shares)

    // 根据份额数量发起冷却
    function cooldownShares(uint256 shares, address owner) external returns (uint256 assets)
    ```

2.  **执行提款**
    等待 `cooldownDuration` 时间结束后，调用此方法以完成提款。
    ```solidity
    function unstake(address receiver) external
    ```

#### 管理方法

1.  **黑名单管理** (`BLACKLIST_MANAGER_ROLE`)
    ```solidity
    function addToBlacklist(address target, bool isFullBlacklisting) external
    function removeFromBlacklist(address target, bool isFullBlacklisting) external
    ```

2.  **奖励管理** (`REWARDER_ROLE`)
    ```solidity
    function transferInRewards(uint256 amount) external
    ```

3.  **紧急情况** (`DEFAULT_ADMIN_ROLE`)
    ```solidity
    // 转移被完全拉黑地址的余额
    function redistributeLockedAmount(address from, address to) external
    // 提取意外转入的非核心资产
    function rescueTokens(address token, uint256 amount, address to) external
    ```

4.  **V2 配置** (`DEFAULT_ADMIN_ROLE`)
    ```solidity
    function setCooldownDuration(uint24 duration) external
    ```

#### 事件

```solidity
event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
event RewardsReceived(uint256 amount, uint256 newVestingAmount);
event LockedAmountRedistributed(address indexed from, address indexed to, uint256 amountToDistribute);
// V2 Only
event CooldownDurationUpdated(uint24 previousDuration, uint24 newDuration);
```

#### 错误码

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

