# 账单接口 `transactions.*`

对应：`TransactionProvider`、`AddTransactionScreen`、`BillListScreen`。

任何会改变余额的写操作，必须同时应用 [账户余额副作用](#余额副作用)。技能在改完 `transactions` 后，应重算或增量调整 `accounts` / `lenders`，再写回账本。

## 余额副作用

与 `AccountProvider._applyTransactionDelta` 一致。`sign = +1` 为入账，删除/回滚时 `sign = -1`。

| type | 账户 | 借贷人 |
|------|------|--------|
| `expense` | `accountId` − amount×sign | — |
| `income` | `accountId` + amount×sign | — |
| `transfer` | `accountId` − amount×sign；`transferAccountId` + amount×sign | — |
| `lend` | `accountId` − amount×sign | `lenderId` + amount×sign |
| `borrow` | `accountId` + amount×sign | `lenderId` − amount×sign |

更新账单 = 先对旧记录 revert，再对新记录 apply。

---

## `transactions.list`

分页查询。默认按 `date` 降序。

### 请求

```json
{
  "method": "transactions.list",
  "params": {
    "offset": 0,
    "limit": 20,
    "type": null,
    "types": ["lend", "borrow"],
    "startDate": "2026-09-01T00:00:00.000",
    "endDate": "2026-09-08T23:59:59.999",
    "keyword": "午餐"
  }
}
```

| 参数 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| `offset` | int | 是 | — | ≥ 0 |
| `limit` | int | 是 | — | App 列表页每次 +20 |
| `type` | TransactionType \| null | 否 | null | 单类型；与 `types` 同时存在时两者都生效（AND） |
| `types` | TransactionType[] \| null | 否 | null | App「借贷」筛选 = `["lend","borrow"]` |
| `startDate` | string \| null | 否 | null | `date < startDate` 排除 |
| `endDate` | string \| null | 否 | null | `date > endDate` 排除 |
| `keyword` | string \| null | 否 | null | 不区分大小写；匹配 `category`、`accountName`、`transferAccountName`、`lenderName`、`note` |

App 账单页筛选 Chip：`全部` / `支出` / `收入` / `转账` / `借贷`。

### 响应

```json
{
  "ok": true,
  "data": {
    "total": 128,
    "offset": 0,
    "limit": 20,
    "items": []
  }
}
```

`items` 为 `TransactionRecord[]`。

---

## `transactions.get`

### 请求

```json
{
  "method": "transactions.get",
  "params": { "id": "1710000000000001" }
}
```

### 响应

```json
{
  "ok": true,
  "data": { "record": {} }
}
```

不存在时 `error.code = NOT_FOUND`。

---

## `transactions.create`

对应 `addTransaction` + `applyTransaction` + `markCategoryUsed`。

### 请求

```json
{
  "method": "transactions.create",
  "params": {
    "type": "expense",
    "amount": 38.5,
    "category": "餐饮",
    "accountId": "alipay-default",
    "transferAccountId": null,
    "lenderId": null,
    "date": "2026-09-08T12:30:00.000",
    "note": "午餐"
  }
}
```

| 参数 | 类型 | 必填 | 约束 |
|------|------|------|------|
| `type` | TransactionType | 是 | |
| `amount` | number | 是 | `> 0` |
| `category` | string | 是 | 建议使用已有分类 label |
| `accountId` | string | 是 | 必须存在 |
| `transferAccountId` | string | 转账必填 | 必须存在且 ≠ `accountId` |
| `lenderId` | string | 借出/借入必填 | 必须存在 |
| `date` | string | 是 | |
| `note` | string | 否 | 默认 `""` |

`accountName` / `transferAccountName` / `lenderName` 由服务端按 id 回填，调用方不必传。

### 校验失败

| 场景 | code | message 示例 |
|------|------|----------------|
| 金额非法 | `INVALID_PARAMS` | 请输入合法金额 |
| 账户不存在 | `NOT_FOUND` | 请选择账户 |
| 转账双方相同 | `CONSTRAINT` | 转入账户不能与转出账户相同 |
| 未选借贷人 | `INVALID_PARAMS` | 请选择借贷人 |

### 响应

```json
{
  "ok": true,
  "data": {
    "record": {},
    "accounts": [],
    "lenders": []
  }
}
```

返回写入后的账单，以及受影响的账户/借贷人快照（技能可只返回变更项）。

### App 额外行为

保存成功后标记分类最近使用：`categories.markUsed({ "label": "餐饮" })`。

编辑账户余额且选择「补记差额」时，会调用本接口：

- `delta > 0` → `type=income`，`category="余额调整"`，`note="编辑账户余额补记"`
- `delta < 0` → `type=expense`，同上

---

## `transactions.update`

对应 `applyTransactionUpdate` + `updateTransaction`。`id` 不可变。

### 请求

```json
{
  "method": "transactions.update",
  "params": {
    "id": "1710000000000001",
    "type": "expense",
    "amount": 42.0,
    "category": "餐饮",
    "accountId": "alipay-default",
    "transferAccountId": null,
    "lenderId": null,
    "date": "2026-09-08T12:30:00.000",
    "note": "午餐加饮料"
  }
}
```

约束同 `create`。记录不存在 → `NOT_FOUND`。

### 响应

同 `create`，`data.record` 为更新后对象。

实现必须：revert(old) → apply(new) → 覆盖存储。

---

## `transactions.delete`

对应 `revertTransaction` + `deleteTransaction`。

### 请求

```json
{
  "method": "transactions.delete",
  "params": { "id": "1710000000000001" }
}
```

### 响应

```json
{
  "ok": true,
  "data": { "deletedId": "1710000000000001" }
}
```

删除前必须回滚余额。不存在可视为成功（幂等）或 `NOT_FOUND`；App 当前是静默跳过存储更新，但 UI 只会删除已展示的记录。

---

## `transactions.replaceCategoryLabel`

分类改名时批量改账单上的 `category` 字符串。**不改余额。**

### 请求

```json
{
  "method": "transactions.replaceCategoryLabel",
  "params": { "from": "餐饮", "to": "吃饭" }
}
```

### 响应

```json
{
  "ok": true,
  "data": { "updatedCount": 12 }
}
```

无匹配时 `updatedCount = 0`。

---

## `transactions.replaceAll`

整包覆盖，用于 JSON 导入 / WebDAV 恢复。**不按流水重算余额**——账户余额以 bundle 内 `accounts` 为准。

### 请求

```json
{
  "method": "transactions.replaceAll",
  "params": { "records": [] }
}
```

通常由 `backup.restore` 一并调用，而不是单独暴露给终端用户。

---

## `transactions.addIfAbsent`

周期账单幂等入账。若 `id` 已存在返回 `created=false` 且不改余额。

### 请求

```json
{
  "method": "transactions.addIfAbsent",
  "params": { "record": {} }
}
```

`record` 必须是完整 `TransactionRecord`（含预定 `id`）。

### 响应

```json
{
  "ok": true,
  "data": { "created": true, "record": {} }
}
```

仅当 `created=true` 时执行余额副作用。
