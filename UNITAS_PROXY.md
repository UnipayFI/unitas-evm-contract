# UnitasProxy 前端接入

## 1. 关键

`UnitasProxy.mintAndStake()` 对订单做了约束（否则会 revert）：

- `order.benefactor == address(UnitasProxy)`
- `order.beneficiary == address(UnitasProxy)`
- `signature.signature_type == EIP1271`
- 调用者必须具备 `MINT_CALLER_ROLE`

此外，`UnitasMintingV2` 侧还会校验：

- `benefactor` 必须在 `UnitasMintingV2` 的 whitelisted benefactors 内
- 若 `benefactor != beneficiary`，还需要 `benefactor` 批准 `beneficiary`；本模式中两者相等（都为 proxy），无需额外批准
- `route.addresses` 必须是 `UnitasMintingV2` 的 custodian 地址集合内，且 `ratios` 满足合约要求（通常总和为 10_000）

参考实现：
- [UnitasProxy.mintAndStake](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasProxy.sol#L72-L104)
- [UnitasMintingV2.verifyOrder](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasMintingV2.sol#L508-L545)

## 2. 参与合约与角色

你需要准备三份合约实例：

- `UnitasMintingV2`：负责 mint（EIP712/EIP1271 校验、dedup、transferFrom collateral、铸币）
- `UnitasProxy`：托管 benefactor（持有 collateral）、实现 `IERC1271`、并在同一 tx 内 stake
- `StakedUSDuV2`：ERC4626 vault，`deposit(assets, receiver)` 把 USDu 换成 sUSDu

角色/权限（链上配置一次即可）：

1) 在 `UnitasMintingV2` 上配置
- `addWhitelistedBenefactor(UnitasProxy)`（admin 调用）
- `grantRole(MINTER_ROLE, UnitasProxy)`（admin 调用）
- `addCustodianAddress(...)`（admin 调用，确保 route 中的地址都被允许）

2) 在 `UnitasProxy` 上配置
- `grantRole(MINT_CALLER_ROLE, <你的交易发起方>)`（admin 调用）
  - 交易发起方可以是后端热钱包 / relayer / 你自己的 EOA
- `grantRole(SIGNER_ROLE, <允许签名的 EOA>)`（admin 调用）
  - 这些 EOA 用来生成 EIP712 签名（但 signature_type 仍设置为 EIP1271，见后文）

## 3. 前端交互总流程（推荐）

纯托管下，用户不需要对 `UnitasMintingV2` 的订单签名（因为 benefactor 是 proxy），一般推荐：

1) 用户把 collateral 转入 `UnitasProxy`
- ERC20：前端引导用户 `collateral.transfer(proxy, amount)`
- 注意：这一步是用户资产入托管

2) 后端/服务端生成订单参数 `order`、`route` 并签名（EIP712）
- 订单里 `benefactor/beneficiary` 都填 `proxy`
- `stakeReceiver` 填用户要拿到 sUSDu 的地址（用户地址）
- 订单签名使用后端“签名 EOA”，该 EOA 必须具备 `proxy.SIGNER_ROLE`

3) 后端/服务端用具备 `MINT_CALLER_ROLE` 的地址发起交易
- 调用 `UnitasProxy.mintAndStake(order, route, signature, stakeReceiver)`

最终效果：

- collateral：从 proxy 被 `UnitasMintingV2` `transferFrom` 到 route custodian
- USDu：由 `UnitasMintingV2` mint 到 proxy
- sUSDu：由 proxy 立即 `deposit` 给 stakeReceiver

## 4. order / route / signature 的构造细节

### 4.1 Order 字段（V2）

`IUnitasMintingV2.Order`：

- `order_id`: string（自定义唯一 ID）
- `order_type`: `MINT`
- `expiry`: uint128（过期时间戳）
- `nonce`: uint120（同一 benefactor 维度去重用）
- `benefactor`: `UnitasProxy` 地址
- `beneficiary`: `UnitasProxy` 地址
- `collateral_asset`: collateral token 地址
- `collateral_amount`: uint128
- `usdu_amount`: uint128

字段类型必须与合约一致，否则 `hashOrder` 会不匹配。

参考：[IUnitasMintingV2.Order](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/interfaces/IUnitasMintingV2.sol#L36-L52)

### 4.2 Route 字段

`IUnitasMintingV2.Route`：

- `addresses`: custodian 地址数组
- `ratios`: 对应的 `uint128[]` 比例数组

参考：[IUnitasMintingV2.Route](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/interfaces/IUnitasMintingV2.sol#L28-L34)

### 4.3 Signature：为什么是“EIP712 生成的签名 + signature_type=EIP1271”

在本模式中，你需要：

- **签名内容**：按 `UnitasMintingV2` 的 EIP712 typed data（domain + Order struct）生成的签名（这和普通 EIP712 用户签名是同一种签名格式）
- **signature.signature_type**：必须设置为 `EIP1271`

原因是 `UnitasMintingV2.verifyOrder()` 在 `EIP1271` 分支会调用：

`IERC1271(order.benefactor).isValidSignature(orderHash, signatureBytes)`

而 `order.benefactor == proxy`，所以它会调用 `proxy.isValidSignature(hash, sig)`。

在 proxy 内部，`isValidSignature` 的实现是：

- 用 `ECDSA.tryRecover(hash, signatureBytes)` 直接 recover signer
- signer 必须具有 `SIGNER_ROLE` 才返回 magic value

也就是说：**你仍然生成一份“EIP712 typed-data 签名”**，但把它作为 **EIP1271 合约签名** 交给 minting 校验。

参考：
- [UnitasMintingV2.verifyOrder EIP1271 分支](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasMintingV2.sol#L521-L537)
- [UnitasProxy.isValidSignature](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasProxy.sol#L51-L59)

## 5. hashOrder 获取方式（前端/后端两种）

你可以用两种方式得到订单 hash（两者应一致）：

1) 链上读取（推荐用来做一致性校验）
- `orderHash = await minting.hashOrder(order)`（eth_call）

2) 本地计算（用于签名）
- 按 EIP712 规则，用与合约一致的 domain 和 types 对 `order` 做 `signTypedData`（ethers 会内部计算同样的 digest）

> 实操建议：先用 `signTypedData` 生成签名，再调用一次 `minting.hashOrder(order)` 对比本地 encoder 的 digest，避免 domain/types 写错。

## 6. ethers 示例（后端签名 + 发起交易）

下面示例以 ethers v6 风格描述（伪代码），重点是 domain/types/value 的一致性。

### 6.1 EIP712 domain

- `name`: `"UnitasMinting"`
- `version`: `"1"`
- `chainId`: 当前链 ID
- `verifyingContract`: `UnitasMintingV2` 合约地址（不是 proxy 地址）

### 6.2 EIP712 types

```ts
const types = {
  Order: [
    { name: "order_id", type: "string" },
    { name: "order_type", type: "uint8" },
    { name: "expiry", type: "uint128" },
    { name: "nonce", type: "uint120" },
    { name: "benefactor", type: "address" },
    { name: "beneficiary", type: "address" },
    { name: "collateral_asset", type: "address" },
    { name: "collateral_amount", type: "uint128" },
    { name: "usdu_amount", type: "uint128" }
  ]
};
```

### 6.3 构造 order 并签名

```ts
const order = {
  order_id: "RFQ-XXXX",
  order_type: 0, // MINT
  expiry: BigInt(Math.floor(Date.now() / 1000) + 600),
  nonce: BigInt(nonce120),
  benefactor: proxyAddress,
  beneficiary: proxyAddress,
  collateral_asset: collateralTokenAddress,
  collateral_amount: BigInt(collateralAmount),
  usdu_amount: BigInt(usduAmount)
};

const domain = {
  name: "UnitasMinting",
  version: "1",
  chainId,
  verifyingContract: mintingAddress
};

const signatureBytes = await signer.signTypedData(domain, types, order);

const signature = {
  signature_type: 1, // EIP1271
  signature_bytes: signatureBytes
};
```

### 6.4 发起 mintAndStake 交易

```ts
await proxy.mintAndStake(order, route, signature, stakeReceiver);
```

注意：

- 发起这笔交易的地址必须在 proxy 上有 `MINT_CALLER_ROLE`
- `signer`（用于 signTypedData 的地址）必须在 proxy 上有 `SIGNER_ROLE`

## 7. collateral 授权（proxy → minting）

`UnitasMintingV2` 会从 `order.benefactor` 拉走 collateral（`transferFrom(benefactor, custodian, amount)`），因此 proxy 必须事先把 collateral allowance 授权给 minting。

本仓库的 proxy 提供了管理员接口：

- `approveCollateral(collateralAsset, allowance)`（admin only）

参考：
- [UnitasMintingV2._transferCollateral safeTransferFrom](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasMintingV2.sol#L653-L666)
- [UnitasProxy.approveCollateral](file:///Users/lizhihao/Work/madao/unipay/unitas-evm-contract/contracts/UnitasProxy.sol#L61-L70)

## 8. 常见错误定位

- `InvalidSignatureType()`：你把 `signature_type` 设成了 EIP712（必须为 EIP1271）
- `InvalidBenefactor()` / `InvalidBeneficiary()`：订单里 benefactor/beneficiary 不是 proxy
- `BenefactorNotWhitelisted()`：minting 未把 proxy 加入 whitelisted benefactors
- `InvalidEIP1271Signature()`：proxy.isValidSignature 返回失败（signer 未授予 SIGNER_ROLE、domain/types/value 不一致等）
- `UnsupportedAsset()`：route/collateral_asset 不在 minting 支持列表或不允许 mint 的资产类型

