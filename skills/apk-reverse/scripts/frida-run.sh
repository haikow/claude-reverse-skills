#!/usr/bin/env bash
# frida-run.sh — frida 注入/枚举（对应 frida-run.ps1）。从 .ps1 移植，未在 Linux/Mac 实测；走 PATH。
# 用法:
#   frida-run.sh --list-devices
#   frida-run.sh [-U|-H host:port] --list-processes
#   frida-run.sh [-U|-H host:port] (-p <package>|-N <process>) -l <script.js> [--spawn] [--pause]
set -euo pipefail
command -v frida >/dev/null || { echo "missing tool: frida" >&2; exit 1; }
command -v python3 >/dev/null && PY=python3 || PY=python

USB=0; RHOST="127.0.0.1:27042"; PKG=""; PROC=""; SCRIPT=""; SPAWN=0; PAUSE=0; LSDEV=0; LSPROC=0
while [ $# -gt 0 ]; do
  case "$1" in
    -U|--usb) USB=1; shift;;
    -H) RHOST="$2"; shift 2;;
    -p|--package) PKG="$2"; shift 2;;
    -N|--process) PROC="$2"; shift 2;;
    -l) SCRIPT="$2"; shift 2;;
    --spawn) SPAWN=1; shift;;
    --pause) PAUSE=1; shift;;
    --list-devices) LSDEV=1; shift;;
    --list-processes) LSPROC=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done

if [ $LSDEV -eq 1 ]; then
  "$PY" -c "import frida;[print(f'{d.id}\t{d.type}\t{d.name}') for d in frida.enumerate_devices()]"; exit $?
fi
if [ $LSPROC -eq 1 ]; then
  if [ $USB -eq 1 ]; then
    "$PY" -c "import frida;d=frida.get_usb_device();[print(f'{p.pid}\t{p.name}') for p in d.enumerate_processes()]"
  else
    "$PY" -c "import frida;d=frida.get_device_manager().add_remote_device('$RHOST');[print(f'{p.pid}\t{p.name}') for p in d.enumerate_processes()]"
  fi
  exit $?
fi

TARGET="${PKG:-$PROC}"
[ -n "$TARGET" ] || { echo "need -p <package> or -N <process> (or --list-*)" >&2; exit 1; }
[ -n "$SCRIPT" ] && [ -f "$SCRIPT" ] || { echo "frida script not found: $SCRIPT" >&2; exit 1; }

ARGS=()
if [ $USB -eq 1 ]; then ARGS+=(-U); else ARGS+=(-H "$RHOST"); fi
if [ $SPAWN -eq 1 ]; then ARGS+=(-f); else ARGS+=(-n); fi
ARGS+=("$TARGET" -l "$SCRIPT")
[ $PAUSE -eq 0 ] && ARGS+=(--no-pause)
exec frida "${ARGS[@]}"
