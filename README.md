# Unitas Evm Contract

## BSC_TESTNET

### 合约地址

| 合约名称 | 地址 | 说明 |
|---------|------|------|
| USDu | [0x4735B34869edc443814829Af93BcAAe76F0C6c68](https://testnet.bscscan.com/address/0x4735B34869edc443814829Af93BcAAe76F0C6c68) | Unitas 稳定币合约 |
| UnitasMinting | [0x9C509d3eFD5404e38f37B11771590864AB77D190](https://testnet.bscscan.com/address/0x9C509d3eFD5404e38f37B11771590864AB77D190) | 铸造和赎回合约 |
| StakedUSDuV2 | [0x03a205AD47Bb97545eEE66DDdE7C4821Fcd22833](https://testnet.bscscan.com/address/0x03a205AD47Bb97545eEE66DDdE7C4821Fcd22833) | USDu 质押合约 |

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

