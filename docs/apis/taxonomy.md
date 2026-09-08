# 分类、预算、周期账单

对应：`CategoryProvider`、`BudgetProvider`、`RecurringProvider`，以及设置页分类管理 / 周期账单、统计页预算编辑。

---

## 分类 `categories.*`

账单存的是 **label**，预算存的是 **categoryId**。改名必须同时调用 `transactions.replaceCategoryLabel`。

### `categories.list`

```json
{ "method": "categories.list", "params": {} }
```

```json
{
  "ok": true,
  "data": {
    "categories": [
      { "id": "c_food", "label": "餐饮", "iconKey": "food" }
    ]
  }
}
```

排序：最近使用时间降序，其次保持原插入顺序。

---

### `categories.create`

对应 `addCategory`。label trim 后为空忽略；与已有 label **精确相同** 则不创建。

```json
{
  "method": "categories.create",
  "params": { "label": "房租", "iconKey": "bill" }
}
```

`iconKey` 非法时按 `other`。响应 `data.category`。

---

### `categories.update`

```json
{
  "method": "categories.update",
  "params": {
    "id": "c_food",
    "label": "吃饭",
    "iconKey": "food"
  }
}
```

若 `label` 变化，必须级联：

```json
{ "method": "transactions.replaceCategoryLabel", "params": { "from": "餐饮", "to": "吃饭" } }
```

周期规则里的 `category` 也是 label。schemaVersion 2 下技能应同步替换 `recurringRules[].category`。

---

### `categories.delete`

有关联账单（`transaction.category == label`）时拒绝。

```json
{ "method": "categories.delete", "params": { "id": "c_movie" } }
```

| 结果 | code |
|------|------|
| 有账单 | `CONSTRAINT`「该分类已有关联账单，无法删除」 |
| 成功 | 同时去掉 recency 记录 |

App 不自动删除该分类的预算；技能删除分类时应顺带 `budgets.delete`。

---

### `categories.markUsed`

记账成功后调用。按 **label** 查找。

```json
{
  "method": "categories.markUsed",
  "params": { "label": "餐饮" }
}
```

写入 `lastUsedAt = now.millisecondsSinceEpoch`。不进备份包。

---

## 预算 `budgets.*`

月度限额，按 `categoryId` upsert。统计页用本月支出对比。

### `budgets.list`

```json
{ "method": "budgets.list", "params": {} }
```

```json
{
  "ok": true,
  "data": {
    "budgets": [{ "categoryId": "c_food", "monthlyLimit": 2000 }]
  }
}
```

---

### `budgets.upsert`

```json
{
  "method": "budgets.upsert",
  "params": { "categoryId": "c_food", "monthlyLimit": 2000 }
}
```

`monthlyLimit < 0` 归一为 0。`categoryId` 应指向已有分类。

响应 `data.budget`。

---

### `budgets.delete`

```json
{ "method": "budgets.delete", "params": { "categoryId": "c_food" } }
```

---

### 预算执行（只读，由 `stats.build` 附带）

本月该分类支出合计 `used`：

```
used = Σ amount  where type=expense AND category==label AND date ∈ 本月
progress = used / monthlyLimit   （限额为 0 时视为 0）
over = max(used - monthlyLimit, 0)
```

---

## 周期账单 `recurring.*`

App 启动 `MainLayout` 时执行一次到期入账。技能在每次写账本前/后也应执行同等逻辑，避免漏账。

仅处理 `enabled && amount > 0 && type ∈ {expense, income}`。转账/借贷规则即使存在也不会自动入账。

### `recurring.list`

```json
{ "method": "recurring.list", "params": {} }
```

```json
{ "ok": true, "data": { "rules": [] } }
```

---

### `recurring.upsert`

创建或整单覆盖。id 不存在则新增。

```json
{
  "method": "recurring.upsert",
  "params": {
    "id": null,
    "title": "房租",
    "type": "expense",
    "amount": 3500,
    "category": "账单",
    "accountId": "debit-default",
    "frequency": "monthly",
    "dayOfMonth": 1,
    "weekday": 1,
    "enabled": true,
    "note": ""
  }
}
```

| 参数 | 说明 |
|------|------|
| `id` | null 则新建 |
| `title` | 非空 |
| `type` | 建议仅 `expense` / `income` |
| `accountId` | 必须存在，回填 `accountName` |
| `startDate` | 新建时默认今天日期部分；更新时保留原值 |
| `nextRunDate` | 不传则按 `computeInitialNextRun` 计算 |
| `endDate` | 可选 |

`computeInitialNextRun`：

- **monthly**：本月 `dayOfMonth`（clamp 1–28）；若已早于 start，则下月同日
- **weekly**：从 start 起（含当天）找到下一个匹配 `weekday` 的日期

### 响应

```json
{ "ok": true, "data": { "rule": {} } }
```

---

### `recurring.delete`

```json
{ "method": "recurring.delete", "params": { "id": "1710..." } }
```

已生成的历史账单保留。

---

### `recurring.peekDue`

只收集到期项，**不推进** `nextRunDate`。对应 `peekDueTransactions`。

```json
{
  "method": "recurring.peekDue",
  "params": { "until": "2026-09-08T00:00:00.000" }
}
```

`until` 缺省为现在。比较使用日期部分（忽略时分秒）。每条规则最多向前展开 36 次，防止死循环。

### 响应

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "ruleId": "1710...",
        "nextRunDateAfter": "2026-10-01T00:00:00.000",
        "record": {
          "id": "recurring_1710..._1756944000000",
          "type": "expense",
          "amount": 3500,
          "category": "账单",
          "accountId": "debit-default",
          "accountName": "招商银行储蓄卡",
          "date": "2026-09-01T00:00:00.000",
          "note": "周期：房租"
        }
      }
    ]
  }
}
```

---

### `recurring.advance`

入账成功后推进规则。仅当 `nextRunDateAfter` **晚于** 当前 `nextRunDate` 才写入。

```json
{
  "method": "recurring.advance",
  "params": {
    "ruleId": "1710...",
    "nextRunDateAfter": "2026-10-01T00:00:00.000"
  }
}
```

---

### `recurring.runDue`（技能建议封装）

App 在启动时顺序执行，技能应提供这一组合方法，避免调用方漏步骤：

1. `peekDue`
2. 对每条 `transactions.addIfAbsent(record)`
3. 若创建成功则应用余额副作用
4. 无论是否已存在，都 `advance`

```json
{ "method": "recurring.runDue", "params": {} }
```

```json
{
  "ok": true,
  "data": { "createdCount": 2, "skippedCount": 1 }
}
```

App UI 提示：`已自动入账 {createdCount} 笔周期账单`。
