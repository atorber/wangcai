# 同步协议 `sync.*`（WebDAV / S3）

对应：`wangcai_core` 的 `SyncClient` + `ObjectStore`（App：`CloudSyncService`；CLI：`wangcai`）。

同步模型：**整包覆盖** + **`revision` 单调版本** + **旁路锁文件租约**。远端一个对象 = 一份 `LedgerBundle`（兼容旧名 `AppBackupBundle`）。

---

## 账本对象

| 项 | 约定 |
|----|------|
| 路径 | 默认 `/wangcai/records.json`（WebDAV）或 `wangcai/records.json`（S3） |
| 锁文件 | `{ledgerPath}.lock` |
| Content-Type | `application/json` |
| schemaVersion | `2`（含 `budgets`、`recurringRules`） |
| revision | 每次成功推送 +1，多端对齐主字段 |

### schemaVersion / revision

```json
{
  "version": 1,
  "schemaVersion": 2,
  "revision": 12,
  "deviceId": "wc_xxxx",
  "exportedAt": "2026-09-08T12:33:00.000",
  "accounts": [],
  "lenders": [],
  "categories": [],
  "transactions": [],
  "budgets": [],
  "recurringRules": []
}
```

读旧文件：缺 `revision` 按 `0`；缺 `budgets` / `recurringRules` 按 `[]`。

---

## 锁协议

锁文件示例：

```json
{
  "ownerId": "wc_cli_xxx",
  "acquiredAt": "2026-09-08T04:00:00.000Z",
  "expiresAt": "2026-09-08T04:00:30.000Z",
  "leaseMs": 30000
}
```

| 步骤 | 行为 |
|------|------|
| 获取 | `putIfAbsent` 锁文件；失败则读锁：过期可覆盖；己方持有则续租；他方未过期则重试至超时 → `LOCK_BUSY` |
| 释放 | 仅 `ownerId` 匹配时 `DELETE` |
| WebDAV | `If-None-Match: *` 或 GET 探测后 PUT；S3 同条件写 + Head 回退 |

---

## 读 / 写路径

**读（`ensureFresh`）**

1. 读本地工作副本 revision  
2. 下载远端账本  
3. 若 `remote.revision > local.revision` → **用远端覆盖本地**  
4. 若本地更新或相等 → **保持本地**（不把较旧远端盖过来）

**写（CLI / App 日常变更 `writeTransaction`）**

1. `acquireLock`  
2. 下载远端并按 revision 选底稿：  
   - `remote > local` → 用远端覆盖本地（先更新本地）  
   - `remote <= local` 或无远端 → **保留本地**（随后上传即更新云端）  
3. 执行业务 mutation  
4. `revision++`，`exportedAt=now`  
5. 上传账本  
6. `releaseLock`  

**写（App「立即备份」`pushLocal`）**

1. 加锁  
2. 若 `remote.revision > local.revision` 且未 `force` → `CONFLICT`  
3. 以本地内容为准，`revision = max(local, remote) + 1` 上传  
4. 释锁  

**恢复（`pullReplace`）**：加锁 → 下载覆盖本地 → 释锁。

---

## 连接配置

见 App 设置页或 CLI `~/.wangcai/config.json`（示例在 `packages/wangcai_cli/config.example.*.json`）。

密钥不进账本 JSON。

---

## 包布局

| 包 | 职责 |
|----|------|
| `packages/wangcai_core` | 模型、`Ledger`、统计/导入、`SyncClient`、WebDAV/S3 |
| `packages/wangcai_cli` | Skill 调用的 JSON CLI |
| Flutter App | UI + SharedPreferences；云同步走 core |

Skill 侧只调用 PATH（或 `WANGCAI_BIN`）上的 `wangcai` 子命令，stdout 为 `{"ok":true,"data":...}`；不依赖本仓库源码。
