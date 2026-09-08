# wangcai-ai 参考（自包含）

本文件随 Skill 分发，不依赖仓库内 `docs/`。

## 环境与二进制

| 路径 / 变量 | 含义 |
|-------------|------|
| `bin/wangcai` | Unix 启动器（按 OS/Arch 选择下方文件） |
| `bin/wangcai.cmd` | Windows 启动器 |
| `bin/wangcai-macos-arm64` | macOS Apple Silicon 原生可执行文件 |
| `bin/wangcai-windows-x64.exe` | Windows x64 原生可执行文件 |
| `WANGCAI_BIN` | 若设置则覆盖启动器 |
| `WANGCAI_CONFIG` | 默认 `~/.wangcai/config.json` |
| `WANGCAI_LEDGER` | 默认 `~/.wangcai/ledger.json` |

> Dart `compile exe` **不能**在 macOS 上交叉编译出 Windows；Windows 产物需在 Windows 主机或 GitHub Actions（`build-cli.yml`）上生成后放入 `bin/`。

## 配置字段

### WebDAV（`protocol: "webdav"`）

| 字段 | 必填 | 说明 |
|------|------|------|
| `deviceId` | 是 | 本机设备标识，写入锁 |
| `serverUrl` | 是 | WebDAV 根 URL |
| `username` / `password` | 是 | 认证 |
| `remotePath` | 否 | 默认 `/wangcai/records.json` |

### S3（`protocol: "s3"`）

| 字段 | 必填 | 说明 |
|------|------|------|
| `deviceId` | 是 | 设备标识 |
| `endpoint` | 是 | S3 兼容 endpoint |
| `region` | 是 | 区域 |
| `bucket` | 是 | 桶名 |
| `objectKey` | 否 | 默认 `wangcai/records.json` |
| `accessKeyId` / `secretAccessKey` | 是 | 密钥 |
| `forcePathStyle` | 否 | MinIO 等常为 `true` |
| `sessionToken` | 否 | 临时凭证 |

## 同步与锁

- 账本为整文件 JSON，含 `revision`（单调递增）
- **读**：`remote > local` 时用远端覆盖本地；否则保持本地
- **写**：`remote > local` 先拉远端再改；`remote <= local` 保留本地再改并上传（更新云端）
- **push**：远端更新且无 `--force` → `CONFLICT`
- **pull**：远端整包覆盖本地
- 锁文件：账本路径 + `.lock`
- `status.alignment`：`in_sync` | `pulled_remote` | `local_ahead` | `no_remote`

## 账户类型 `type`

`cash` | `debitCard` | `creditCard` | `alipay` | `wechat` | `other`（以 CLI `--help` 为准）

## 交易类型 `type`

`expense` | `income` | `transfer` | `lend` | `borrow`

## 分类图标 `icon`

`food` | `transport` | `shopping` | `movie` | `medical` | `grocery` | `bill` | `other`

## 错误码

| code | 含义 |
|------|------|
| `INVALID_PARAMS` | 参数非法 |
| `NOT_FOUND` | 账户/分类/记录不存在 |
| `CONSTRAINT` | 业务约束 |
| `CONFLICT` | 远端 revision 更新 |
| `LOCK_BUSY` | 其他设备持锁 |
| `PARSE_FAILED` | CSV/配置解析失败 |
| `SYNC_FAILED` | 网络或对象存储失败 |
| `UNAUTHORIZED` | 认证失败 |

## CLI 命令一览

| 命令 | 读/写 |
|------|------|
| `status` / `pull` / `push` | 读对齐 / 拉 / 推 |
| `tx add\|list\|delete` | 写 / 读 / 写 |
| `accounts list\|add` | 读 / 写 |
| `categories list\|add\|update\|delete` | 读 / 写 |
| `budgets list\|upsert\|delete` | 读 / 写 |
| `recurring list\|upsert\|delete\|run` | 读 / 写 |
| `import parse\|commit` | 读解析 / 写提交 |
| `stats --period week\|month\|year` | 读 |

stdout 一律：`{"ok":true,"data":...}`。
