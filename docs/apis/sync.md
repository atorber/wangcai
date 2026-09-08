# 同步协议 `sync.*`（WebDAV / S3）

对应：`CloudSyncService`、`WebDavBackupService`、`S3BackupService`。App 已支持 **WebDAV** 与 **S3 兼容对象存储**；账本文件格式相同。

同步模型：**整包覆盖**，不是增量 CRDT。远端一个对象 = 一份 `AppBackupBundle`。

---

## 账本对象

| 项 | 当前 App | 技能建议 |
|----|---------|----------|
| 路径 | `/wangcai/records.json` | 保持默认；可配置 |
| Content-Type | `application/json` | 同左 |
| 编码 | UTF-8，无 BOM | 同左 |
| 结构 | [models.md](./models.md) `AppBackupBundle` | schemaVersion 2 含 `budgets`、`recurringRules` |

### schemaVersion 演进

| 版本 | 字段 |
|------|------|
| 1（现状） | `version`, `schemaVersion`, `deviceId`, `exportedAt`, `accounts`, `lenders`, `categories`, `transactions` |
| 2（对齐 Skill） | 增加 `budgets`, `recurringRules`；读旧文件时缺省 `[]` |

写入时始终刷新：

- `exportedAt = now`
- `deviceId`：本机/本技能实例稳定 id
- `schemaVersion`：实现所支持的最高版本

---

## 连接配置

App 支持 `webdav` 与 `s3` 两种协议，通过统一门面 `CloudSyncService` 读写同一份 `AppBackupBundle`。

### WebDAV

```json
{
  "protocol": "webdav",
  "serverUrl": "https://dav.example.com/dav",
  "username": "user",
  "password": "app-password",
  "remotePath": "/wangcai/records.json"
}
```

| 字段 | 约束 |
|------|------|
| `serverUrl` | 非空，可含 path 前缀 |
| `username` / `password` | Basic Auth |
| `remotePath` | 非空；不以 `/` 开头时实现会补上 |

`isValid`：四字段 trim 后均非空。

### S3 兼容（MinIO / R2 / OSS 等）

```json
{
  "protocol": "s3",
  "endpoint": "https://s3.example.com",
  "region": "us-east-1",
  "bucket": "wangcai",
  "objectKey": "wangcai/records.json",
  "accessKeyId": "...",
  "secretAccessKey": "...",
  "forcePathStyle": true
}
```

| 字段 | 说明 |
|------|------|
| `endpoint` | S3 API 入口，可省略 `https://` |
| `region` | 签名区域，R2 常用 `auto` |
| `bucket` / `objectKey` | 目标对象 |
| `accessKeyId` / `secretAccessKey` | Secret 存 `flutter_secure_storage` |
| `forcePathStyle` | 默认 `true`（自托管建议开启） |

`protocol` 缺省按 `webdav` 处理，兼容旧配置。密钥**不写入**账本 JSON。

---

## WebDAV 语义（App 已实现）

超时 **15 秒**。认证头：`Authorization: Basic base64(user:password)`。

文件 URI：`{serverUrl 去尾斜杠}{remotePath}`。

| 操作 | HTTP | 行为 |
|------|------|------|
| 确保目录 | `MKCOL` 逐级创建 `remotePath` 的父目录 | 201 成功；405 视为已存在 |
| 上传 | `PUT` 全文 JSON | 2xx 成功 |
| 下载 | `GET` | 空 body / 非 JSON / 非 object 失败 |
| 探活元信息 | 同 GET | 404/405/409 或空/坏 JSON → 视为远端无包，返回 null |

HTTP 错误映射：

| 状态码 | 用户可见含义 |
|--------|----------------|
| 401 / 403 | 认证失败，请检查用户名或密码 |
| 404 | 远端文件不存在，请先执行备份 |
| 409 | 远端路径冲突，请检查上级目录是否可写 |
| 5xx | 服务器异常（code） |
| 网络/超时 | 请求超时或网络异常 |

---

## S3 语义（Skill 新增，App 后续可跟）

| 操作 | API | 对应 WebDAV |
|------|------|-------------|
| 上传 | `PutObject` | PUT |
| 下载 | `GetObject` | GET |
| 探活 | `GetObject` 或 `HeadObject` | fetchRemoteBundleMeta |
| 目录 | 无需 MKCOL | 对象键本身即路径 |

兼容 MinIO / 阿里云 OSS / Cloudflare R2 等 S3 API。建议 `forcePathStyle=true` 以便自托管。

错误映射与 WebDAV 同一套 `UNAUTHORIZED` / `NOT_FOUND` / `SYNC_FAILED`。

---

## `sync.status`

```json
{ "method": "sync.status", "params": {} }
```

```json
{
  "ok": true,
  "data": {
    "configured": true,
    "protocol": "webdav",
    "remotePath": "/wangcai/records.json",
    "lastSyncAt": "2026-09-08T12:00:00.000",
    "localDeviceId": "wc_xxxx_yyyy"
  }
}
```

App：`lastSyncAt` 来自 `webdav_last_backup_at`，上传或下载成功都会刷新。

---

## `sync.pull`

下载远端账本，可选覆盖本地。

```json
{
  "method": "sync.pull",
  "params": { "apply": true, "force": false }
}
```

| 参数 | 说明 |
|------|------|
| `apply` | `false` 只返回 bundle，不覆盖（对应 fetch meta） |
| `force` | `true` 跳过「远端较旧」确认 |

App 恢复前的冲突提示（`force=false` 时应返回 `CONFLICT` 让调用方确认）：

若本地已有账单或账户/借贷人，且

```
bundle.exportedAt < 本地账单最大 date
```

则提示：远端备份可能较旧，继续会丢失本地较新数据。

### 响应

```json
{
  "ok": true,
  "data": {
    "applied": true,
    "bundle": {},
    "transactionCount": 128,
    "accountCount": 5,
    "lenderCount": 1,
    "categoryCount": 8
  }
}
```

`apply=true` 时内部调用 `backup.restore`。

---

## `sync.push`

上传当前账本。

```json
{
  "method": "sync.push",
  "params": { "force": false }
}
```

上传前 App 会 GET 远端元信息。若

```
remote.exportedAt > now
```

（远端时间比本机时钟还晚）则确认后再覆盖。`force=false` 时技能应返回 `CONFLICT`。

PUT 前 WebDAV 会 MKCOL 父目录。成功后写 `lastSyncAt`。

### 响应

```json
{
  "ok": true,
  "data": {
    "exportedAt": "2026-09-08T12:33:00.000",
    "deviceId": "wc_xxxx_yyyy"
  }
}
```

---

## 多端约定（App + Skill）

1. **先 pull 再改再 push**。技能一次工具调用应：pull → 内存修改 → push，减少覆盖窗口。
2. **不要用本地账单 date 当版本**。权威版本是 `exportedAt` + 可选未来的 `revision`。
3. **覆盖是整包**。两端不得只上传 transactions 子集。
4. **密钥与账本分离**。WebDAV 密码、S3 Key 只存在各端安全存储。
5. **schema 向前兼容**：读时忽略未知字段；写时带上自己支持的字段。App 未升级前，Skill 写 schemaVersion 2 时 App 会丢掉 `budgets`/`recurringRules`——在 App 升级 `AppBackupBundle` 之前，Skill 若需与现网 App 共存，push 时应保留读到的未知字段，或暂不写 v2 字段。

推荐冲突处理（尚未在 App 实现，技能可先做）：

```
if remote.exportedAt > localWorkingCopy.exportedAt
  → 拒绝 push，要求先 pull
```

当前 App 只比较了「远端 exportedAt > 本机时钟」和「恢复时 exportedAt < 本地最新账单时间」，**没有**双向合并。

---

## `sync.saveConfig` / `sync.loadConfig`

仅配置存储，不碰账本。

```json
{
  "method": "sync.saveConfig",
  "params": {
    "protocol": "webdav",
    "serverUrl": "https://dav.example.com/dav",
    "username": "user",
    "password": "secret",
    "remotePath": "/wangcai/records.json"
  }
}
```

App：URL/用户名/路径 → SharedPreferences；密码 → `flutter_secure_storage`，并删除旧明文 key。

```json
{ "method": "sync.loadConfig", "params": {} }
```

无效配置返回 `data.config = null`。密码是否回传由实现决定；技能工具对模型展示时应脱敏。
