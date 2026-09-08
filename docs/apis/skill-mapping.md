# 技能 `wangcai-ai` 工具映射

本文把契约 method 收敛成技能侧建议暴露的工具，便于实现 `skills/wangcai-ai`。底层一律：加载账本 → 调用与 App 相同的纯函数 → `sync.push`。

## 建议工具列表

| 工具名 | 封装的 method | 说明 |
|--------|----------------|------|
| `wangcai_status` | `sync.status` + `assets.overview` | 是否已配置同步、资产摘要 |
| `wangcai_sync_pull` | `sync.pull` | 拉取远端 |
| `wangcai_sync_push` | `sync.push` | 推送工作副本 |
| `wangcai_add_transaction` | `transactions.create` | 记一笔 |
| `wangcai_update_transaction` | `transactions.update` | 改账单 |
| `wangcai_delete_transaction` | `transactions.delete` | 删账单并回滚余额 |
| `wangcai_list_transactions` | `transactions.list` | 筛选/分页 |
| `wangcai_list_accounts` | `accounts.list` + `lenders.list` | 账户与借贷人 |
| `wangcai_add_account` | `accounts.create` | |
| `wangcai_update_account` | `accounts.update` | |
| `wangcai_delete_account` | `accounts.delete` | |
| `wangcai_add_lender` | `lenders.create` | |
| `wangcai_list_categories` | `categories.list` | |
| `wangcai_manage_category` | `categories.create/update/delete` | |
| `wangcai_upsert_budget` | `budgets.upsert` / `budgets.delete` | |
| `wangcai_list_recurring` | `recurring.list` | |
| `wangcai_upsert_recurring` | `recurring.upsert` | |
| `wangcai_run_recurring` | `recurring.runDue` | 到期入账 |
| `wangcai_stats` | `stats.build` | 周/月/年 |
| `wangcai_import_csv` | `import.parseCsv` + `import.commitCsv` | 可分两步：先预览再确认 |
| `wangcai_export` | `backup.export` | 返回 JSON 文本 |
| `wangcai_restore` | `backup.restore` | 覆盖工作副本，通常再 push |

## 典型对话 → 调用链

**「记一笔今天支付宝午餐 38.5」**

1. `sync.pull`（若工作副本过期）
2. `accounts.list` 解析「支付宝」→ `accountId`
3. `categories.list` 解析「午餐」→ label `餐饮`
4. `transactions.create`
5. `sync.push`

**「这个月花了多少，餐饮超预算了吗」**

1. `stats.build { period: month }`
2. 用 `budgetProgress` 回答

**「把房租设成每月 1 号从储蓄卡扣 3500」**

1. `recurring.upsert`
2. `recurring.runDue`（若今天已到期）
3. `sync.push`

## 与 App 行为必须一致的点

1. 五类账单的余额公式
2. 分类用 label、预算用 categoryId
3. 周期账单 id 格式与 36 次展开上限
4. 删除账户/分类的引用检查
5. 统计只计 income/expense
6. 整包覆盖，不以单条账单合并

## 实现顺序建议

1. 读写 `AppBackupBundle` + WebDAV GET/PUT（与现网 App 互通）
2. 账单 CRUD + 余额副作用（核心闭环）
3. 账户/分类/统计
4. 周期入账、预算、CSV 导入
5. S3 传输层（同一 bundle）
6. 回头改 App：`AppBackupBundle` 升到 schemaVersion 2，备份预算与周期规则
