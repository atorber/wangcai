#!/usr/bin/env bash
# 从最近一次成功的 Build Wangcai CLI workflow 下载产物到 skills/wangcai-ai/bin/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILL_BIN="$ROOT/skills/wangcai-ai/bin"
mkdir -p "$SKILL_BIN"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$ROOT"
RUN_ID="$(gh run list --workflow=build-cli.yml --status=success --limit 1 --json databaseId -q '.[0].databaseId')"
if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "没有成功的 build-cli.yml 运行记录。请先: gh workflow run \"Build Wangcai CLI\"" >&2
  exit 1
fi
echo "Downloading artifacts from run $RUN_ID ..."
gh run download "$RUN_ID" --dir "$TMP"

found=0
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  case "$base" in
    wangcai-macos-arm64|wangcai-windows-x64.exe)
      cp -f "$f" "$SKILL_BIN/$base"
      chmod +x "$SKILL_BIN/$base" 2>/dev/null || true
      echo "Installed $SKILL_BIN/$base"
      found=1
      ;;
  esac
done < <(find "$TMP" -type f -print0)

if [[ "$found" -eq 0 ]]; then
  echo "未在 artifact 中找到预期二进制，目录内容：" >&2
  find "$TMP" -type f >&2
  exit 1
fi
ls -lh "$SKILL_BIN"
