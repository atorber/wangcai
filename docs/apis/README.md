# 旺财能力接口契约

旺财当前是 **本地优先 Flutter App**：没有独立 HTTP 后端。业务能力由 Provider 实现，数据以 JSON 落在本机，再通过 **WebDAV 整包备份/恢复**。

本文档把 App 现有能力抽象成 **技能可复用的接口契约**，供下一步 `skills/wangcai-ai` 实现同等记账能力，并通过 **WebDAV / S3** 与 App 共用同一份账本。

## 设计原则

1. **同一份账本**：App 与 Skill 读写同一份 `AppBackupBundle` JSON（对象存储中的单个文件）。
2. **同一套实体**：字段名、枚举值、金额符号与 App 模型 `toJson()` 完全一致。
3. **同一套副作用**：记账必须同步调整账户 / 借贷人余额，规则与 `AccountProvider._applyTransactionDelta` 一致。
4. **传输层可替换**：业务接口与存储协议解耦。当前 App 只实现 WebDAV；Skill 同时支持 WebDAV 与 S3。

## 文档目录

| 文档 | 内容 |
|------|------|
| [models.md](./models.md) | 实体 JSON、枚举、本地存储键、备份包 |
| [transactions.md](./transactions.md) | 记账、查询、编辑、删除 |
| [accounts.md](./accounts.md) | 账户、借贷人、资产概览 |
| [taxonomy.md](./taxonomy.md) | 分类、预算、周期账单 |
| [stats.md](./stats.md) | 周/月/年统计与预算执行 |
| [import.md](./import.md) | 支付宝/微信 CSV、JSON/CSV 导入导出 |
| [sync.md](./sync.md) | WebDAV / S3 同步协议与冲突策略 |
| [settings.md](./settings.md) | 主题、安全隐私、清空数据（技能可选） |

## 调用约定

技能与未来服务端统一使用以下信封。App 内部是 Dart 方法调用，语义与此一一对应。

### 请求

```json
{
  "method": "transactions.create",
  "params": {}
}
```

- `method`：`领域.动作`，见各文档。
- `params`：对象；无参数时传 `{}`。
- 金额单位为人民币元，`number`，保留最多 2 位小数。
- 时间一律 ISO-8601 字符串，例如 `2026-09-08T12:30:00.000`。
- 实体 `id` 为字符串。App 当前用 `DateTime.now().microsecondsSinceEpoch` 生成。

### 成功响应

```json
{
  "ok": true,
  "method": "transactions.create",
  "data": {}
}
```

### 失败响应

```json
{
  "ok": false,
  "method": "transactions.create",
  "error": {
    "code": "ACCOUNT_NOT_FOUND",
    "message": "账户不存在"
  }
}
```

### 通用错误码

| code | 含义 |
|------|------|
| `INVALID_PARAMS` | 参数缺失或类型错误 |
| `NOT_FOUND` | 目标实体不存在 |
| `CONFLICT` | 名称重复、覆盖冲突、路径冲突 |
| `CONSTRAINT` | 业务约束（如账户仍有关联账单） |
| `SYNC_FAILED` | 远端读写失败 |
| `PARSE_FAILED` | JSON/CSV 无法解析 |
| `UNAUTHORIZED` | WebDAV/S3 认证失败 |

## 能力清单（与 App 对齐）

| 领域 | method 前缀 | App 入口 |
|------|-------------|----------|
| 账单 | `transactions.*` | 添加 Tab、账单列表、账户/借贷人详情 |
| 账户 | `accounts.*` | 首页资产概览、添加账户 |
| 借贷人 | `lenders.*` | 首页借贷人、记一笔借出/借入 |
| 分类 | `categories.*` | 设置 → 分类管理 |
| 预算 | `budgets.*` | 统计页分类预算 |
| 周期账单 | `recurring.*` | 设置 → 周期账单；启动时自动入账 |
| 资产 | `assets.overview` | 首页顶部总资产/净资产/总负债 |
| 统计 | `stats.build` | 统计 Tab |
| 账单导入 | `import.csv` | 设置 → 导入支付宝/微信账单 |
| 数据迁移 | `backup.*` | 导出 JSON/CSV、导入 JSON |
| 同步 | `sync.*` | 设置 → WebDAV 云备份 |
| 设置 | `settings.*` / `security.*` | 主题、应用锁、清空数据 |

## 实现映射

| 契约层 | App 现状 | Skill 目标 |
|--------|----------|------------|
| 业务逻辑 | `lib/providers/*`、`lib/services/*` | `skills/wangcai-ai` 工具函数 |
| 本地持久化 | SharedPreferences JSON | 工作副本（内存/临时文件） |
| 远端账本 | WebDAV `PUT/GET` 单个 JSON | WebDAV **或** S3 兼容对象存储 |
| 账本文件 | `AppBackupBundle` schemaVersion=1 | 建议升级到 2，补预算与周期规则 |

当前备份包 **不含** 预算和周期规则。技能若要与 App 完整对齐，需按 [sync.md](./sync.md) 的 schemaVersion 2 扩展，并在 App 侧同步升级 `AppBackupBundle`。
