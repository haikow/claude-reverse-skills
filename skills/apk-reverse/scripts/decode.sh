#!/usr/bin/env bash
# decode.sh — 用 jadx + apktool 解包 APK（Linux/Mac 版，对应 decode.ps1）
# 注意：从 .ps1 移植，未在 Linux/Mac 实测；工具一律走 PATH 查找。
# 用法: decode.sh <apk> [-o <outroot>] [-n <name>] [--skip-jadx] [--skip-apktool] [--clean]
set -euo pipefail

APK=""; OUTROOT=""; NAME=""; SKIP_JADX=0; SKIP_APKTOOL=0; CLEAN=0
while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUTROOT="$2"; shift 2;;
    -n) NAME="$2"; shift 2;;
    --skip-jadx) SKIP_JADX=1; shift;;
    --skip-apktool) SKIP_APKTOOL=1; shift;;
    --clean) CLEAN=1; shift;;
    *) APK="$1"; shift;;
  esac
done
[ -n "$APK" ] && [ -f "$APK" ] || { echo "APK not found: $APK" >&2; exit 1; }

[ $SKIP_JADX -eq 1 ]    || command -v jadx    >/dev/null || { echo "missing tool: jadx" >&2; exit 1; }
[ $SKIP_APKTOOL -eq 1 ] || command -v apktool >/dev/null || { echo "missing tool: apktool" >&2; exit 1; }

[ -n "$NAME" ]    || NAME="$(basename "$APK"); NAME="${NAME%.*}"; NAME="$(printf '%s' "${NAME%.*}" | tr -c 'A-Za-z0-9._-' '_')"
[ -n "$OUTROOT" ] || OUTROOT="$(cd "$(dirname "$APK")" && pwd)"
TASK_ROOT="$OUTROOT/$NAME"; JADX_OUT="$TASK_ROOT/jadx"; APKTOOL_OUT="$TASK_ROOT/apktool"

[ $CLEAN -eq 1 ] && rm -rf "$TASK_ROOT"
mkdir -p "$TASK_ROOT"

JADX_RC=""; APKTOOL_RC=""
if [ $SKIP_JADX -eq 0 ]; then
  rm -rf "$JADX_OUT"; set +e; jadx -d "$JADX_OUT" "$APK"; JADX_RC=$?; set -e
fi
if [ $SKIP_APKTOOL -eq 0 ]; then
  rm -rf "$APKTOOL_OUT"; set +e; apktool d "$APK" -o "$APKTOOL_OUT" -f; APKTOOL_RC=$?; set -e
fi

MANIFEST="$APKTOOL_OUT/AndroidManifest.xml"
PKG=""; [ -f "$MANIFEST" ] && PKG="$(grep -aoE 'package="[^"]+"' "$MANIFEST" | head -1 | sed 's/package="//; s/"//')"
JAVA_N=0;  [ -d "$JADX_OUT" ]    && JAVA_N=$(find "$JADX_OUT" -type f -name '*.java' | wc -l | tr -d ' ')
SO_N=0;    [ -d "$APKTOOL_OUT" ] && SO_N=$(find "$APKTOOL_OUT" -type f -name '*.so' | wc -l | tr -d ' ')

echo "task_root=$TASK_ROOT"
echo "jadx_out=$JADX_OUT"
echo "apktool_out=$APKTOOL_OUT"
echo "package=$PKG"
echo "jadx_exit_code=$JADX_RC"
echo "apktool_exit_code=$APKTOOL_RC"
echo "java_files=$JAVA_N"
echo "so_files=$SO_N"
