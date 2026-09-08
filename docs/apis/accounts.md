# 账户与借贷人 `accounts.*` / `lenders.*` / `assets.overview`

对应：`AccountProvider`、`AssetOverviewScreen`、`AddAccountScreen`、账户/借贷人详情。

---

## `accounts.list`

### 请求

```json
{ "method": "accounts.list", "params": {} }
```

### 响应

```json
{
  "ok": true,
  "data": {
    "accounts": [],
    "upcomingCreditPayments": []
  }
}
```

`upcomingCreditPayments`：信用卡中 `daysUntilPayment <= 7` 的账户，按剩余天数升序。与首页还款提醒一致。

每条账户可附带派生字段（可选）：

```json
{
  "id": "credit-default",
  "name": "浦发银行信用卡",
  "type": "creditCard",
  "balance": -1200.0,
  "creditLimit": 20000.0,
  "billingDay": 5,
  "paymentDay": 23,
  "usedCredit": 1200.0,
  "availableCredit": 18800.0,
  "daysUntilPayment": 3
}
```

---

## `accounts.get`

```json
{ "method": "accounts.get", "params": { "id": "alipay-default" } }
```

响应 `data.account`。不存在 → `NOT_FOUND`。

详情页还会列出该账户相关账单（`accountId` 或 `transferAccountId` 匹配），调用 `transactions.list` 即可，不必单独接口。

---

## `accounts.create`

对应 `addAccount`。id 由服务端生成。

### 请求

```json
{
  "method": "accounts.create",
  "params": {
    "name": "建设银行储蓄卡",
    "type": "debitCard",
    "balance": 5000.0,
    "creditLimit": null,
    "billingDay": null,
    "paymentDay": null
  }
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | trim 后非空 |
| `type` | AccountType | 是 | 不含 `lender`（借贷人走 `lenders.create`） |
| `balance` | number | 是 | 初始余额。信用卡欠款传负数 |
| `creditLimit` | number \| null | 否 | 仅 `creditCard` 写入 |
| `billingDay` | int \| null | 否 | 1–28，仅信用卡 |
| `paymentDay` | int \| null | 否 | 1–28，仅信用卡 |

非信用卡的额度/账单日/还款日必须存为 `null`。

### 响应

```json
{ "ok": true, "data": { "account": {} } }
```

---

## `accounts.update`

对应 `updateAccount`。**不改 `type`。**

### 请求

```json
{
  "method": "accounts.update",
  "params": {
    "id": "debit-default",
    "name": "招商银行储蓄卡",
    "balance": 1200.0,
    "creditLimit": null,
    "billingDay": null,
    "paymentDay": null,
    "adjustByTransaction": true
  }
}
```

| 参数 | 说明 |
|------|------|
| `adjustByTransaction` | App 编辑弹窗选项。`true` 时不直接改余额，改为记一笔「余额调整」；`false` 则直接覆盖 `balance` |

当 `adjustByTransaction=true` 且 `newBalance != oldBalance`：

1. 先更新名称/信用卡字段，余额保持旧值
2. 再 `transactions.create` 补差额（见 [transactions.md](./transactions.md)）

### 响应

```json
{
  "ok": true,
  "data": {
    "account": {},
    "adjustmentRecord": null
  }
}
```

有补记时 `adjustmentRecord` 为新账单，否则 `null`。

---

## `accounts.delete`

对应 `removeAccount`。若仍有账单引用该账户（`accountId` 或 `transferAccountId`），拒绝删除。

### 请求

```json
{ "method": "accounts.delete", "params": { "id": "cash-default" } }
```

### 响应

成功：

```json
{ "ok": true, "data": { "deletedId": "cash-default" } }
```

有关联账单：

```json
{
  "ok": false,
  "error": {
    "code": "CONSTRAINT",
    "message": "该账户已有关联账单，无法删除"
  }
}
```

---

## `lenders.list`

```json
{ "method": "lenders.list", "params": {} }
```

```json
{ "ok": true, "data": { "lenders": [] } }
```

---

## `lenders.create`

对应 `addLender`。名称 trim 后为空则忽略；与已有 **精确同名** 则不创建（App 静默返回）。

### 请求

```json
{ "method": "lenders.create", "params": { "name": "张三" } }
```

初始 `balance = 0`。

### 响应

```json
{ "ok": true, "data": { "lender": {}, "created": true } }
```

重名时 `created=false`，`lender` 为已有记录。技能建议对重名返回 `CONFLICT`，比静默更清晰。

---

## `lenders.update`

对应 `updateLender`。空名称保留原名。

```json
{
  "method": "lenders.update",
  "params": {
    "id": "1710...",
    "name": "张三",
    "balance": 200.0
  }
}
```

App 允许直接改余额（不强制补记流水）。技能若从聊天改余额，建议走借出/借入账单以保持可追溯。

---

## `lenders.delete`

App **当前没有删除借贷人入口**。技能若实现删除，约束应对齐账户：存在 `lenderId` 引用的账单则 `CONSTRAINT`。

```json
{ "method": "lenders.delete", "params": { "id": "1710..." } }
```

---

## `assets.overview`

对应首页顶部卡片。纯计算，不入库。

### 请求

```json
{ "method": "assets.overview", "params": {} }
```

### 响应

```json
{
  "ok": true,
  "data": {
    "totalAssets": 1000.0,
    "totalLiabilities": 1200.0,
    "netAssets": -200.0,
    "accountCount": 5,
    "lenderCount": 1,
    "upcomingCreditPayments": []
  }
}
```

计算规则：

```
totalAssets      = Σ max(account.balance, 0)
totalLiabilities  = Σ abs(min(account.balance, 0))
netAssets         = totalAssets - totalLiabilities
```

借贷人余额 **不计入** 总资产/总负债（首页单独展示）。
