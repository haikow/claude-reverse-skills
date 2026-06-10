#!/usr/bin/env bash
# start.sh — 启动 idalib HTTP MCP 服务（对应 start.ps1 的 HTTP 方案）。未在 Linux/Mac 实测。
#
# ⚠️ 推荐用法（Claude Code + ida-multi-mcp，无需本脚本）：
#   pip install ida-multi-mcp   # 见仓库 mcp/README.md
#   然后在 MCP 配置里加 {"command":"python","args":["-m","ida_multi_mcp"]}
#   Claude Code 会以 stdio 方式自动拉起，不需要手动起 HTTP 服务。
#
# 本脚本仅用于"手动 HTTP 服务"那一套（idalib-mcp --host --port）。
# 需先设好 IDADIR 指向你的 IDA 安装目录（含 idalib）。
set -euo pipefail
: "${IDADIR:?请先 export IDADIR=/path/to/IDA（含 idalib 的 IDA 安装目录）}"
PORT="${PORT:-13337}"

command -v idalib-mcp >/dev/null || { echo "missing: idalib-mcp（pip install 后应在 PATH）" >&2; exit 1; }

# 杀旧进程
pkill -f 'idalib-mcp' 2>/dev/null || true
sleep 1

# 后台启动
nohup idalib-mcp --host 127.0.0.1 --port "$PORT" >/tmp/idalib-mcp.log 2>&1 &
echo "idalib-mcp 启动中 (pid $!)，日志 /tmp/idalib-mcp.log"

# 等待就绪（最多 15s）
for i in $(seq 1 15); do
  sleep 1
  if curl -s -m 3 "http://127.0.0.1:$PORT/mcp" \
      -H 'Content-Type: application/json' \
      -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | grep -q '"tools"'; then
    echo "OK: idalib-mcp ready on 127.0.0.1:$PORT"; exit 0
  fi
done
echo "ERR:timeout（查看 /tmp/idalib-mcp.log）" >&2; exit 1
