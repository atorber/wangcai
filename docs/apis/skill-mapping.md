# 技能 `wangcai-ai` 工具映射

Skill **独立安装**：目录内自带多平台 `bin/wangcai*` + 配置模板，只需再准备 `~/.wangcai/config.json`。
**不要**假设当前目录是本仓库；**不要**用 Python 等重写业务逻辑。

副本路径：`skills/wangcai-ai/`（可整体拷到 `~/.cursor/skills/wangcai-ai/`）。

## 运行

```bash
SKILL_ROOT=~/.cursor/skills/wangcai-ai   # 或本仓库 skills/wangcai-ai
cp "$SKILL_ROOT/config.example.webdav.json" ~/.wangcai/config.json
"$SKILL_ROOT/bin/wangcai" status          # macOS / Linux 启动器
# Windows: %SKILL_ROOT%\bin\wangcai.cmd status
```

重建：本机 `packages/wangcai_cli/scripts/build.sh`；Windows 需 CI（`.github/workflows/build-cli.yml`）+ `scripts/sync-from-ci.sh`。

stdout：`{"ok":true,"data":{...}}`。

## 命令一览

| CLI | 同步 | 契约 |
|-----|------|------|
| `status` / `pull` / `push` | 读对齐 / 加锁拉 / 加锁推 | `sync.*` |
| `tx add\|list\|delete` | 写事务 / 读 | `transactions.*` |
| `accounts list\|add` | 读 / 写 | `accounts.*` |
| `categories list\|add\|update\|delete` | 读 / 写 | `categories.*` |
| `budgets list\|upsert\|delete` | 读 / 写 | `budgets.*` |
| `recurring list\|upsert\|delete\|run` | 读 / 写 | `recurring.*` |
| `import parse\|commit` | 读解析 / 写提交 | `import.*` |
| `stats` | 读 | `stats.build` |

App 日常记账写路径：`CloudLedgerBridge.mutate`（已配置云同步则写穿 `SyncClient`）。
