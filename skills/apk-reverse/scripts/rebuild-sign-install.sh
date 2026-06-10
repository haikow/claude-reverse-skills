#!/usr/bin/env bash
# rebuild-sign-install.sh — apktool 回编 → zipalign → apksigner 签名 →(可选)adb 安装
# 对应 rebuild-sign-install.ps1。从 .ps1 移植，未在 Linux/Mac 实测；工具走 PATH。
# 用法: rebuild-sign-install.sh <projectDir> [-o <outDir>] [-n <baseName>] [--install] [--reinstall] [-s <serial>] [--clean]
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE="${KEYSTORE:-$SELF_DIR/../debug.keystore}"   # 默认用 skill 自带 debug.keystore
ALIAS="${KEY_ALIAS:-androiddebugkey}"; STOREPASS="${STORE_PASS:-android}"; KEYPASS="${KEY_PASS:-android}"

PROJ=""; OUTDIR=""; BASENAME=""; INSTALL=0; REINSTALL=0; SERIAL=""; CLEAN=0
while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUTDIR="$2"; shift 2;;
    -n) BASENAME="$2"; shift 2;;
    -s) SERIAL="$2"; shift 2;;
    --install) INSTALL=1; shift;;
    --reinstall) REINSTALL=1; shift;;
    --clean) CLEAN=1; shift;;
    *) PROJ="$1"; shift;;
  esac
done
[ -n "$PROJ" ] && [ -d "$PROJ" ] || { echo "project dir not found: $PROJ" >&2; exit 1; }
for t in apktool zipalign apksigner; do command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }; done

# 没有 keystore 就用 keytool 生成一个 debug keystore
if [ ! -f "$KEYSTORE" ]; then
  command -v keytool >/dev/null || { echo "missing keystore and keytool" >&2; exit 1; }
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -v -keystore "$KEYSTORE" -storepass "$STOREPASS" -keypass "$KEYPASS" \
    -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Android Debug,O=ReverseSkills,C=CN'
fi

[ -n "$OUTDIR" ] || OUTDIR="$(cd "$(dirname "$PROJ")" && pwd)"
[ -n "$BASENAME" ] || BASENAME="$(basename "$PROJ")"
mkdir -p "$OUTDIR"
UNSIGNED="$OUTDIR/$BASENAME-unsigned.apk"; ALIGNED="$OUTDIR/$BASENAME-aligned.apk"; SIGNED="$OUTDIR/$BASENAME-signed.apk"
[ $CLEAN -eq 1 ] && rm -f "$UNSIGNED" "$ALIGNED" "$SIGNED"

apktool b "$PROJ" -o "$UNSIGNED"
zipalign -f -p 4 "$UNSIGNED" "$ALIGNED"
apksigner sign --ks "$KEYSTORE" --ks-key-alias "$ALIAS" --ks-pass "pass:$STOREPASS" --key-pass "pass:$KEYPASS" --out "$SIGNED" "$ALIGNED"
apksigner verify --print-certs "$SIGNED" | head -3

echo "unsigned_apk=$UNSIGNED"
echo "aligned_apk=$ALIGNED"
echo "signed_apk=$SIGNED"
echo "keystore=$KEYSTORE"

if [ $INSTALL -eq 1 ]; then
  command -v adb >/dev/null || { echo "missing tool: adb" >&2; exit 1; }
  ADB_ARGS=(); [ -n "$SERIAL" ] && ADB_ARGS+=(-s "$SERIAL")
  ADB_ARGS+=(install); [ $REINSTALL -eq 1 ] && ADB_ARGS+=(-r)
  ADB_ARGS+=("$SIGNED")
  adb "${ADB_ARGS[@]}"
  echo "install_device=$SERIAL"
fi
