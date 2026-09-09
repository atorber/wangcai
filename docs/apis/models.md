# 数据模型

对应源码：`lib/models/*`。字段名与 `toJson()` / `fromJson()` 一致，Skill 必须按此读写，不可改名。

## 枚举

### TransactionType

账单类型。JSON 值为枚举 `name`。

| 值 | 中文 | 余额副作用 |
|----|------|------------|
| `expense` | 支出 | 账户 `-amount` |
| `income` | 收入 | 账户 `+amount` |
| `transfer` | 转账 | 转出账户 `-amount`，转入账户 `+amount` |
| `lend` | 借出 | 账户 `-amount`，借贷人 `+amount`（对方欠我） |
| `borrow` | 借入 | 账户 `+amount`，借贷人 `-amount`（我欠对方） |

### AccountType

| 值 | 中文 |
|----|------|
| `cash` | 现金 |
| `creditCard` | 信用卡 |
| `debitCard` | 储蓄卡/借记卡 |
| `onlineAccount` | 网络账户 |
| `investment` | 投资账户 |
| `storedValueCard` | 储值卡 |

兼容旧值：`alipay` / `wechatPay` / `wechat` / `other` / `receivablePayable` → `onlineAccount`。未知值按 `debitCard` 解析。

**应收/应付**：与借贷人（`Lender`）同一概念，走 `lenders.*`，不是 `AccountType`。

### RecurringFrequency

| 值 | 中文 | 触发规则 |
|----|------|----------|
| `monthly` | 每月 | 使用 `dayOfMonth`（1–28） |
| `weekly` | 每周 | 使用 `weekday`（1=周一 … 7=周日，与 Dart `DateTime.weekday` 一致） |

未知值按 `monthly` 解析。

### StatsPeriod

仅统计接口使用，不入库。

| 值 | 中文 | 区间 |
|----|------|------|
| `week` | 周 | 本周一 00:00 至下周一 00:00（左闭右开） |
| `month` | 月 | 本月 1 日 至下月 1 日 |
| `year` | 年 | 本年 1 月 1 日 至下年 1 月 1 日 |

### ExportFormat / BillImportSource

| 枚举 | 值 |
|------|-----|
| `ExportFormat` | `json`, `csv` |
| `BillImportSource` | `alipay`, `wechat`, `unknown` |

## Account

```json
{
  "id": "debit-default",
  "name": "招商银行储蓄卡",
  "type": "debitCard",
  "balance": 1000.0,
  "subtitle": "尾号 4392",
  "creditLimit": 20000.0,
  "billingDay": 5,
  "paymentDay": 23
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 账户主键 |
| `name` | string | 是 | 显示名 |
| `type` | AccountType | 是 | 见枚举 |
| `balance` | number | 是 | 当前余额。信用卡欠款为 **负数** |
| `subtitle` | string | 否 | 默认 `""` |
| `creditLimit` | number \| null | 否 | 仅信用卡有意义 |
| `billingDay` | int \| null | 否 | 账单日 1–28 |
| `paymentDay` | int \| null | 否 | 还款日 1–28 |

派生（不入库，接口可返回）：

- `isLiability`：`balance < 0`
- `usedCredit`：信用卡为 `abs(balance)`，否则 0
- `availableCredit`：`creditLimit - usedCredit`（缺额度时为 null）
- `daysUntilPayment`：距最近还款日天数（含当天）

### 默认账户（首次安装、无本地数据时）

| id | name | type | balance |
|----|------|------|---------|
| `debit-default` | 招商银行储蓄卡 | debitCard | 1000 |
| `credit-default` | 浦发银行信用卡 | creditCard | 0 |
| `alipay-default` | 支付宝 | onlineAccount | 0 |
| `wechat-default` | 微信支付 | onlineAccount | 0 |
| `cash-default` | 现金 | cash | 0 |

一旦 SharedPreferences 有 `accounts_v1`，不再使用上述默认值。

## Lender

```json
{
  "id": "1710000000000000",
  "name": "张三",
  "balance": 200.0
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 主键 |
| `name` | string | 名称，创建时按精确匹配去重 |
| `balance` | number | 正数表示对方欠我（借出累计），负数表示我欠对方（借入累计） |

## TransactionRecord

```json
{
  "id": "1710000000000001",
  "type": "expense",
  "amount": 38.5,
  "category": "餐饮",
  "accountId": "alipay-default",
  "accountName": "支付宝",
  "transferAccountId": null,
  "transferAccountName": null,
  "lenderId": null,
  "lenderName": null,
  "date": "2026-09-08T12:30:00.000",
  "note": "午餐"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 主键。周期入账使用 `recurring_{ruleId}_{dateMs}` |
| `type` | TransactionType | 是 | |
| `amount` | number | 是 | 必须 `> 0` |
| `category` | string | 是 | **分类标签**，不是 categoryId |
| `accountId` / `accountName` | string | 是 | 主账户（支出/收入来源；转账为转出；借贷为资金账户） |
| `transferAccountId` / `transferAccountName` | string \| null | 转账必填 | 转入账户，不得与转出相同 |
| `lenderId` / `lenderName` | string \| null | 借出/借入必填 | |
| `date` | string | 是 | ISO-8601 |
| `note` | string | 否 | 默认 `""` |

## TransactionCategory

```json
{
  "id": "c_food",
  "label": "餐饮",
  "iconKey": "food"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 主键。预算按此关联 |
| `label` | string | 显示名。**账单、周期规则、导入建议分类都存 label** |
| `iconKey` | string | 见下表 |

允许的 `iconKey`：`food` / `transport` / `shopping` / `movie` / `medical` / `grocery` / `bill` / `other`。未知值按 `other` 显示。

### 默认分类

| id | label | iconKey |
|----|-------|---------|
| `c_food` | 餐饮 | food |
| `c_transport` | 交通 | transport |
| `c_shopping` | 购物 | shopping |
| `c_movie` | 电影 | movie |
| `c_medical` | 医疗 | medical |
| `c_grocery` | 杂货 | grocery |
| `c_bill` | 账单 | bill |
| `c_other` | 其他 | other |

分类最近使用时间单独存在 `transaction_categories_recency_v1`，**不进入备份包**。列表按 lastUsedAt 降序，相同时保持原顺序。

## Budget

```json
{
  "categoryId": "c_food",
  "monthlyLimit": 2000.0
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `categoryId` | string | 对应 `TransactionCategory.id` |
| `monthlyLimit` | number | 月度上限；写入时 `< 0` 会被归一为 0 |

一个分类最多一条预算。**当前 schemaVersion=1 备份包不含此集合。**

## RecurringRule

```json
{
  "id": "1710000000000002",
  "title": "房租",
  "type": "expense",
  "amount": 3500.0,
  "category": "账单",
  "accountId": "debit-default",
  "accountName": "招商银行储蓄卡",
  "frequency": "monthly",
  "dayOfMonth": 1,
  "weekday": 1,
  "startDate": "2026-09-01T00:00:00.000",
  "endDate": null,
  "nextRunDate": "2026-10-01T00:00:00.000",
  "enabled": true,
  "note": ""
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 主键 |
| `title` | string | 规则标题 |
| `type` | TransactionType | App 仅对 `expense` / `income` 自动入账 |
| `amount` | number | `<= 0` 的规则不会入账 |
| `category` | string | 分类 **label** |
| `accountId` / `accountName` | string | 入账账户 |
| `frequency` | RecurringFrequency | |
| `dayOfMonth` | int | 默认 1 |
| `weekday` | int | 默认 1（周一） |
| `startDate` | string | |
| `endDate` | string \| null | 超过结束日停止 |
| `nextRunDate` | string | 下一次应入账日期（日期部分） |
| `enabled` | bool | 默认 true |
| `note` | string | 空则入账备注为 `周期：{title}` |

**当前 schemaVersion=1 备份包不含此集合。**

周期入账生成的账单 id：

```
recurring_{ruleId}_{nextRunDate.millisecondsSinceEpoch}
```

同一 id 已存在则跳过（幂等）。

## AppBackupBundle（账本文件）

当前 App 上传/导出的根对象。远端默认目录 WebDAV `/wangcai/`、S3 `wangcai/`，账本文件为其中的 `records.json`；版本见同目录 `revision.json`。

```json
{
  "version": 1,
  "schemaVersion": 1,
  "deviceId": "wc_xxxx_yyyy",
  "exportedAt": "2026-09-08T12:33:00.000",
  "accounts": [],
  "lenders": [],
  "categories": [],
  "transactions": []
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | int | 业务版本，当前写死 `1` |
| `schemaVersion` | int | 结构版本，缺省按 `1` |
| `deviceId` | string \| null | 上传时由 App 注入，格式 `wc_{time36}_{rand36}` |
| `exportedAt` | string | 导出/备份时间，冲突检测主字段 |
| `accounts` | Account[] | |
| `lenders` | Lender[] | |
| `categories` | TransactionCategory[] | |
| `transactions` | TransactionRecord[] | 无保证顺序；App 读入后按 `date` 降序展示 |

`fromJson` 对缺失数组按 `[]` 处理；非法元素跳过。

### schemaVersion 2（技能对齐建议）

为让 Skill 与 App 能力完全一致，备份包应增加：

```json
{
  "version": 1,
  "schemaVersion": 2,
  "deviceId": "wc_xxxx_yyyy",
  "exportedAt": "2026-09-08T12:33:00.000",
  "accounts": [],
  "lenders": [],
  "categories": [],
  "transactions": [],
  "budgets": [],
  "recurringRules": []
}
```

App 读取时：缺字段视为空数组，以兼容旧文件。

## 本地存储键（仅 App）

| Key | 内容 |
|-----|------|
| `accounts_v1` | Account[] JSON |
| `lenders_v1` | Lender[] JSON |
| `transaction_records_v1` | TransactionRecord[] JSON |
| `transaction_categories_v1` | TransactionCategory[] JSON |
| `transaction_categories_recency_v1` | `{ [categoryId]: epochMs }` |
| `budget_items_v1` | Budget[] JSON |
| `recurring_rules_v1` | RecurringRule[] JSON |
| `app_settings_theme_mode` | `system` / `light` / `dark` |
| `security_app_lock_enabled` | bool |
| `security_biometric_enabled` | bool |
| `security_privacy_mode_enabled` | bool |
| `webdav_server_url` | string |
| `webdav_username` | string |
| `webdav_remote_path` | string |
| `webdav_last_backup_at` | ISO-8601 |
| `webdav_device_id` | string |
| `webdav_password` | 已迁移到 `flutter_secure_storage` |

技能不使用 SharedPreferences；工作数据来自远端账本文件。
