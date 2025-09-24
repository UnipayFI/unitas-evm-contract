# EVM Caller API 文档


## Endpoint

待定

## 接口

### 1. Mint (铸币)

通过提供抵押资产来铸造 USDu 稳定币。服务器将根据请求参数生成 `nonce`，对订单进行签名，并提交上链。

- **方法**: `POST`
- **路径**: `/mint`

#### 请求体

```json
{
  "order": {
    "order_id": "string",
    "order_type": "number",
    "expiry": "number",
    "benefactor": "string",
    "beneficiary": "string",
    "collateral_asset": "string",
    "collateral_amount": "string",
    "usdu_amount": "string"
  },
  "route": {
    "addresses": ["string"],
    "ratios": ["number"]
  }
}
```

#### 请求体字段说明

**`order`**

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_id` | string | 唯一的订单ID。 |
| `order_type` | number | 订单类型 (例如: 0 代表 MINT)。 |
| `expiry` | number | 订单过期时间的 Unix 时间戳。 |
| `benefactor` | string | 订单发起方地址。 |
| `beneficiary` | string | 最终受益人地址。 |
| `collateral_asset` | string | 抵押资产的合约地址。 |
| `collateral_amount` | string | 抵押资产的数量 (以最小单位表示)。 |
| `usdu_amount` | string | 期望铸造的 USDu 数量 (以最小单位表示)。 |

**`route`**

| 字段 | 类型 | 说明 |
|---|---|---|
| `addresses` | string[] | 路由路径中的地址数组。 |
| `ratios` | number[] | 路由路径中的比率数组。 |


#### 成功响应

```json
{
  "success": true,
  "receipt": {
    "to": "0x0A9133ab7BE00887D89F77d4aE3f999963DF4A03",
    "from": "0x..... (Signer Address)",
    "contractAddress": null,
    "transactionIndex": 5,
    "gasUsed": "123456",
    "blockHash": "0xabc...def",
    "transactionHash": "0x123...789",
    "logs": [],
    "blockNumber": 1234567,
    "confirmations": 1,
    "cumulativeGasUsed": "654321",
    "status": 1,
    "type": 2
  }
}
```

#### 失败响应

```json
{
  "success": false,
  "error": "具体的错误信息"
}
```

---

### 2. Redeem (赎回)

用于销毁 USDu 稳定币以赎回抵押资产。

- **方法**: `POST`
- **路径**: `/redeem`

#### 请求体

```json
{
  "order": {
    "order_id": "string",
    "order_type": "number",
    "expiry": "number",
    "benefactor": "string",
    "beneficiary": "string",
    "collateral_asset": "string",
    "collateral_amount": "string",
    "usdu_amount": "string"
  }
}
```

#### 请求体字段说明

**`order`**

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_id` | string | 唯一的订单ID。 |
| `order_type` | number | 订单类型 (例如: 1 代表 REDEEM)。 |
| `expiry` | number | 订单过期时间的 Unix 时间戳。 |
| `benefactor` | string | 订单发起方地址。 |
| `beneficiary` | string | 最终受益人地址。 |
| `collateral_asset` | string | 抵押资产的合约地址。 |
| `collateral_amount` | string | 抵押资产的数量 (以最小单位表示)。 |
| `usdu_amount` | string | 期望赎回的 USDu 数量 (以最小单位表示)。 |

#### 成功响应

```json
{
  "success": true,
  "receipt": {
    "to": "0x0A9133ab7BE00887D89F77d4aE3f999963DF4A03",
    "from": "0x..... (Signer Address)",
    "contractAddress": null,
    "transactionIndex": 8,
    "gasUsed": "98765",
    "blockHash": "0xfed...cba",
    "transactionHash": "0x987...321",
    "logs": [],
    "blockNumber": 1234599,
    "confirmations": 1,
    "cumulativeGasUsed": "543210",
    "status": 1,
    "type": 2
  }
}
```

#### 失败响应

```json
{
  "success": false,
  "error": "具体的错误信息"
}
```
