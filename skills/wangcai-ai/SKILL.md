---
name: wangcai-ai
description: >-
  Operates the WangCai (旺财) personal finance ledger via the bundled
  multi-platform `bin/wangcai` CLI (WebDAV/S3 locked sync). Use when the user
  wants to bookkeep, query accounts/transactions/stats, manage
  categories/budgets/recurring rules, import Alipay/WeChat CSV, or sync the
  cloud ledger. Self-contained skill with macOS/Windows binaries + config
  templates; does not need the WangCai source repo.
---

# 旺财 AI Skill

本 Skill **自带** 多平台 CLI，与 App 共用同一套账本逻辑（WebDAV / S3 加锁同步）。**不依赖项目源码。**

## 运行时依赖

| 依赖 | 说明 |
|------|------|
| `bin/wangcai`（Unix）或 `bin/wangcai.cmd`（Windows） | 启动器，自动选择下方平台二进制 |
| `bin/wangcai-macos-arm64` | macOS Apple Silicon |
| `bin/wangcai-windows-x64.exe` | Windows x64 |
| `~/.wangcai/config.json` | WebDAV / S3 配置（模板见同目录 `config.example.*.json`） |

可选：`WANGCAI_CONFIG`、`WANGCAI_LEDGER`、`WANGCAI_BIN`（覆盖启动器路径）。

### 如何调用 CLI

```bash
# SKILL_ROOT = 本 Skill 安装目录（含 SKILL.md）
BIN="${WANGCAI_BIN:-$SKILL_ROOT/bin/wangcai}"   # Windows 用 wangcai.cmd
chmod +x "$BIN" "$SKILL_ROOT/bin/wangcai-macos-arm64" 2>/dev/null || true
"$BIN" status
```

下文凡写 `wangcai ...`，均指上述启动器（或 `WANGCAI_BIN`）。不要用系统 PATH，不要 `dart run`。

### 配置模板

**WebDAV** → `~/.wangcai/config.json`：

```json
{
  "protocol": "webdav",
  "deviceId": "wc_cli",
  "serverUrl": "https://dav.example.com/remote.php/dav/files/user",
  "username": "user",
  "password": "app-password",
  "remotePath": "/wangcai"
}
```

**S3 兼容** → `~/.wangcai/config.json`：

```json
{
  "protocol": "s3",
  "deviceId": "wc_cli",
  "endpoint": "https://s3.example.com",
  "region": "us-east-1",
  "bucket": "wangcai",
  "objectKey": "wangcai",
  "accessKeyId": "AKIA...",
  "secretAccessKey": "...",
  "forcePathStyle": true
}
```

也可复制本 Skill 内：`config.example.webdav.json` / `config.example.s3.json`。

## 输出约定

所有命令 **stdout** 为 JSON：`{"ok":true,"data":{...}}`  
失败写 **stderr**：`{"ok":false,"error":{"code":"...","message":"..."}}`

## 同步语义（必须遵守）

| 操作类型 | 行为 |
|----------|------|
| 读（list/status/stats/parse） | 先对齐远端：`revision` 更大则拉本地 |
| 写（add/update/delete/upsert/commit/run/push） | 加锁 → 拉远端 → 变更 → `revision++` → 推送 → 释锁 |
| `LOCK_BUSY` | 提示稍后重试，勿绕过锁硬写 |

用户只配置远端**目录**（默认 WebDAV `/wangcai`、S3 `wangcai`）。目录内由旺财自动维护：

| 文件 | 用途 |
|------|------|
| `records.json` | 账本整包 |
| `revision.json` | 独立数据版本（读对齐优先读此文件） |
| `lock.json` | 写入租约锁 |

## 命令速查

### 同步与状态

```bash
wangcai status
wangcai pull
wangcai push [--force]
```

### 记账

```bash
wangcai tx add --type expense --amount 38.5 --account 支付宝 --category 餐饮 --note 午餐
wangcai tx add --type transfer --amount 100 --account 支付宝 --transfer-account 现金
wangcai tx list --limit 20 --keyword 午餐
wangcai tx delete --id <id>
```

`--account` / `--transfer-account` / `--lender` 可用 **id 或名称**。

### 账户

```bash
wangcai accounts list
wangcai accounts add --name 建设银行 --type debitCard --balance 5000
wangcai accounts update --account 支付宝 --balance 1200 --record-diff
```

`--record-diff`：将「新余额 − 原余额」补记为收入（增加）或支出（减少）。

### 分类

```bash
wangcai categories list
wangcai categories add --label 房租 --icon bill
wangcai categories update --id <id> --label 吃饭 --icon food
wangcai categories delete --id <id>
```

`icon`：`food|transport|shopping|movie|medical|grocery|bill|other`

### 预算

```bash
wangcai budgets list
wangcai budgets upsert --category 餐饮 --limit 2000
wangcai budgets delete --category 餐饮
```

### 周期账单

```bash
wangcai recurring list
wangcai recurring upsert --title 房租 --type expense --amount 3500 --account 招商银行储蓄卡 --category 账单 --frequency monthly --day-of-month 1
wangcai recurring delete --id <id>
wangcai recurring run
```

### 导入支付宝/微信 CSV

```bash
wangcai import parse --file ~/Downloads/alipay.csv
wangcai import commit --file ~/Downloads/alipay.csv --account 支付宝
```

### 统计

```bash
wangcai stats --period month   # week|month|year
```

## 对话 → 调用建议

| 用户意图 | 调用 |
|----------|------|
| 记一笔午餐 | `tx add`（先 `accounts list` / `categories list` 解析名称） |
| 调整账户余额并补记差额 | `accounts update --account 支付宝 --balance 1200 --record-diff` |
| 这个月花了多少 | `stats --period month` |
| 设餐饮预算 | `budgets upsert --category 餐饮 --limit ...` |
| 每月房租 | `recurring upsert`，必要时 `recurring run` |
| 导入账单 | `import parse` 预览 → 确认后 `import commit` |
| 和其他端对齐 | `pull` 或依赖写路径自动拉齐 |

## 约束

1. **只通过本 Skill 的 `bin/wangcai`（或 `.cmd`）** 改账本
2. 账单分类是 **label**；预算关联 **categoryId**
3. 统计只计 `income` / `expense`
4. 密钥只在 config / 环境变量
5. 对用户用中文，金额用人民币元
6. 安装时保留 `bin/` 下全部平台文件与执行权限

## 更多细节

见 [`reference.md`](reference.md)。
