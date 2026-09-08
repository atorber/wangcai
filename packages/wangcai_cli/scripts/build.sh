#!/usr/bin/env bash
# 本机编译当前平台，并写入 skills/wangcai-ai/bin/
# Windows 无法在 macOS 上交叉编译，需跑 CI：gh workflow run "Build Wangcai CLI"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$ROOT/packages/wangcai_cli"
SKILL_BIN="$ROOT/skills/wangcai-ai/bin"
cd "$CLI"
dart pub get
mkdir -p "$SKILL_BIN"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
  arm64|aarch64) arch=arm64 ;;
  x86_64|amd64) arch=x64 ;;
esac

case "$os" in
  darwin)
    out="wangcai-macos-${arch}"
    dart compile exe bin/wangcai.dart -o "$out"
    cp -f "$out" "$SKILL_BIN/$out"
    chmod +x "$SKILL_BIN/$out"
    ;;
  linux)
    out="wangcai-linux-${arch}"
    dart compile exe bin/wangcai.dart -o "$out"
    cp -f "$out" "$SKILL_BIN/$out"
    chmod +x "$SKILL_BIN/$out"
    ;;
  mingw*|msys*|cygwin*)
    out="wangcai-windows-${arch}.exe"
    dart compile exe bin/wangcai.dart -o "$out"
    cp -f "$out" "$SKILL_BIN/$out"
    ;;
  *)
    echo "Unsupported host OS: $os" >&2
    exit 1
    ;;
esac

chmod +x "$SKILL_BIN/wangcai" 2>/dev/null || true
echo "Built host binary: $SKILL_BIN/$out"
ls -lh "$SKILL_BIN"/wangcai*
