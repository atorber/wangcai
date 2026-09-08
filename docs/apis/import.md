# 导入导出 `import.*` / `backup.*`

对应：`BillImportService`、`DataExportService`、设置页导出/导入 JSON。

---

## `import.parseCsv`

解析支付宝 / 微信导出的 CSV 文本，**不写账本**。

### 请求

```json
{
  "method": "import.parseCsv",
  "params": { "text": "交易时间,收/支,金额,...\n..." }
}
```

表头识别：文件前 40 行中，含 `交易时间` / `交易创建时间`，或同时含 `时间` 与 `金额`。

来源判断：

- 含 `交易对方` 或 `收/支`：若同时有 `交易单号`+`商户单号` → `wechat`，否则 `alipay`
- 含 `交易类型` 且 `金额(元)` → `wechat`

列映射（单元格包含即命中）：

| 逻辑列 | 候选表头 |
|--------|---------|
| date | 交易时间、交易创建时间、时间 |
| amount | 金额(元)、金额（元）、金额 |
| direction | 收/支、收／支、类型 |
| category | 交易分类、交易类型、分类 |
| counterparty | 交易对方、对方、商户 |
| note | 商品说明、商品、备注、说明 |

金额去掉 `,` `¥` `￥`；日期 `/` 换成 `-`，`DateTime.tryParse`。`amount <= 0` 或无法解析的行跳过。

收支：方向含「收/收入/入账」→ `income`；含「支/支出」→ `expense`；金额以 `+` 开头 → `income`；否则支出。

### 分类建议 `suggestCategory`

对 `rawCategory + counterparty + note` 做关键词匹配（小写）：

| 命中关键词（节选） | 建议分类 |
|--------------------|----------|
| 餐、外卖、美团、饿了么、咖啡、奶茶、食堂 | 餐饮 |
| 地铁、公交、打车、滴滴、高德、加油、停车、火车、机票 | 交通 |
| 淘宝、京东、拼多多、超市、便利店、购物 | 购物 |
| 电影、影院、会员、游戏、娱乐 | 电影 |
| 医院、药店、医保、诊所 | 医疗 |
| 水电、煤气、物业、话费、宽带、电费、水费 | 账单 |
| 菜、生鲜、水果、蔬菜 | 杂货 |
| 以上皆无且 rawCategory 非空 | 使用 rawCategory |
| 再无 | 其他 |

### 成功响应

```json
{
  "ok": true,
  "data": {
    "source": "alipay",
    "rows": [
      {
        "date": "2026-09-01T12:00:00.000",
        "amount": 38.5,
        "type": "expense",
        "rawCategory": "餐饮美食",
        "counterparty": "某某餐厅",
        "note": "午餐",
        "suggestedCategory": "餐饮"
      }
    ]
  }
}
```

`amount` 已取绝对值。`note` 为空时回退为 `counterparty`。

### 失败

| 场景 | message |
|------|---------|
| 空文件 | 文件为空 |
| 无表头 | 未识别到支付宝/微信账单表头，请导出 CSV 后再试 |
| 缺时间/金额列 | 缺少必要列（时间/金额） |
| 无有效行 | 未解析到有效账单行 |

`error.code = PARSE_FAILED`。

---

## `import.commitCsv`

将解析结果写入账本（对应导入页「确认导入」）。每条调用 `transactions.create`。

### 请求

```json
{
  "method": "import.commitCsv",
  "params": {
    "accountId": "alipay-default",
    "rows": [
      {
        "date": "2026-09-01T12:00:00.000",
        "amount": 38.5,
        "type": "expense",
        "suggestedCategory": "餐饮",
        "note": "午餐"
      }
    ]
  }
}
```

App 按用户勾选的行下标导入；技能直接传选定 `rows`。分类用 `suggestedCategory`。

### 响应

```json
{
  "ok": true,
  "data": { "importedCount": 15 }
}
```

---

## `backup.export`

构造成完整账本并序列化。App 再走系统分享；技能返回文本即可。

### 请求

```json
{
  "method": "backup.export",
  "params": { "format": "json" }
}
```

`format`：`json` | `csv`。

当前 App 导出内容 = schemaVersion 1 的 `AppBackupBundle`（不含预算/周期规则）。schemaVersion 2 见 [sync.md](./sync.md)。

### JSON 响应

```json
{
  "ok": true,
  "data": {
    "format": "json",
    "filename": "wangcai_export_20260908123300.json",
    "bundle": {}
  }
}
```

JSON 使用 2 空格缩进（App `JsonEncoder.withIndent('  ')`）。

### CSV 格式（App `_buildCsv`）

分段表，第一列是 section：

```
section,key,value
meta,version,1
meta,exportedAt,2026-09-08T12:33:00.000

accounts,id,name,type,balance,subtitle
accounts,debit-default,招商银行储蓄卡,debitCard,1000,尾号 4392

lenders,id,name,balance
lenders,1710...,张三,200

categories,id,label,iconKey
categories,c_food,餐饮,food

transactions,id,type,amount,category,accountId,accountName,transferAccountId,transferAccountName,lenderId,lenderName,date,note
transactions,...
```

含逗号、引号、换行的字段按 RFC 方式加双引号并转义 `"` → `""`。

CSV **不是** 恢复格式；恢复只认 JSON bundle。

---

## `backup.restore`

用 JSON 覆盖本地账本。对应「导入 JSON」与 WebDAV 恢复。

### 请求

```json
{
  "method": "backup.restore",
  "params": {
    "bundle": {},
    "confirmOverwrite": true
  }
}
```

写入顺序（App）：

1. `accounts.replaceAll`
2. `lenders.replaceAll`（`AccountProvider.replaceLenders`）
3. `categories.replaceAll`
4. `transactions.replaceAll`

**不重算余额。** 以 bundle 内账户/借贷人余额为准。

schemaVersion 2 时追加 `budgets.replaceAll`、`recurring.replaceAll`。

`confirmOverwrite != true` 时返回 `CONSTRAINT`，避免误覆盖。

### 响应

```json
{
  "ok": true,
  "data": {
    "transactionCount": 128,
    "accountCount": 5,
    "lenderCount": 1,
    "categoryCount": 8
  }
}
```

根对象不是 JSON object → `PARSE_FAILED`「文件结构无效」。
