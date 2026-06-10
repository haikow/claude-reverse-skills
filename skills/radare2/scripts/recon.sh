#!/usr/bin/env bash
# recon.sh — radare2/rabin2 快速侦察（对应 recon.ps1）。未在 Linux/Mac 实测；走 PATH。
# 用法: recon.sh <target> [--strings N] [--imports N] [--analysis]
set -euo pipefail
TARGET=""; SLIMIT=40; ILIMIT=80; ANALYSIS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --strings) SLIMIT="$2"; shift 2;;
    --imports) ILIMIT="$2"; shift 2;;
    --analysis) ANALYSIS=1; shift;;
    *) TARGET="$1"; shift;;
  esac
done
[ -n "$TARGET" ] && [ -f "$TARGET" ] || { echo "target not found: $TARGET" >&2; exit 1; }
command -v rabin2 >/dev/null || { echo "missing tool: rabin2" >&2; exit 1; }
[ $ANALYSIS -eq 1 ] && { command -v r2 >/dev/null || { echo "missing tool: r2" >&2; exit 1; }; }

echo "目标文件: $TARGET"
echo; echo "=== 基本信息 ==="; rabin2 -I -- "$TARGET"
echo; echo "=== 节区 ===";     rabin2 -S -- "$TARGET"
echo; echo "=== 导入 ===";     rabin2 -i -- "$TARGET" | head -n "$ILIMIT"
echo; echo "=== 导出 ===";     rabin2 -E -- "$TARGET" | head -n "$ILIMIT"
echo; echo "=== 字符串 ===";   rabin2 -z -- "$TARGET" | head -n "$SLIMIT"
if [ $ANALYSIS -eq 1 ]; then
  echo; echo "=== 函数(r2 aaa) ==="
  r2 -2 -q -c 'aaa; afl' -- "$TARGET" 2>/dev/null | head -n 200
fi
