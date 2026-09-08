# wangcai_cli

与 App 共用 `wangcai_core`。对外交付为多平台原生二进制，并放入 `skills/wangcai-ai/bin/`。

| 文件 | 平台 |
|------|------|
| `wangcai-macos-arm64` | macOS Apple Silicon |
| `wangcai-windows-x64.exe` | Windows x64 |
| `wangcai` / `wangcai.cmd` | 启动器 |

## 本机构建（当前 OS）

```bash
cd packages/wangcai_cli
./scripts/build.sh
```

macOS 上 **无法** 交叉编译 Windows（Dart 仅支持交叉到 Linux）。Windows 产物用 CI：

```bash
# 需已推送含 packages/wangcai_* 与 workflow 的分支
gh workflow run "Build Wangcai CLI"
# 完成后
./scripts/sync-from-ci.sh
```

## 开发调试

```bash
dart run bin/wangcai.dart status
```
