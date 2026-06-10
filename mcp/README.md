# MCP：ida-multi-mcp（IDA Pro 多实例 MCP 服务）

本仓库**不再分发** `ida-multi-mcp` 的源码——它是第三方 **MIT** 包，直接用 pip 安装即可（本身跨平台）。

> `ida-multi-mcp`：Multi-instance IDA Pro MCP server for simultaneous reverse engineering（License: MIT）。

## 前置：IDA Pro + idalib（商业授权，需自备）
- 需要 **IDA Pro 9.x** 且带 **idalib**（headless 分析库）。这是商业软件，本仓库不提供。
- 让 idalib 能被找到：设置环境变量 `IDADIR` 指向你的 IDA 安装目录（含 `idalib`/`idapython`）。

## 安装
```bash
pip install ida-multi-mcp
# 或固定到当前已验证版本：
pip install ida-multi-mcp==0.1.0
```

## 在 Claude Code 里登记（stdio 方式，推荐）
把下面片段并入你的 MCP 配置（`~/.claude.json` 的 `mcpServers`，或项目内 `.mcp.json`）：

```json
{
  "mcpServers": {
    "ida-multi-mcp": {
      "command": "python",
      "args": ["-m", "ida_multi_mcp"],
      "env": { "IDADIR": "/path/to/IDA" }
    }
  }
}
```

- **Linux/Mac**：`command` 用 `python3` 或 `python` 均可（确保该解释器装了 `ida-multi-mcp`）。
- **Windows**：`command` 可写 `python`，或填绝对路径，如
  `C:\\Users\\YOURNAME\\AppData\\Local\\Programs\\Python\\Python3xx\\python.exe`。
- `IDADIR` 改成你本机 IDA 目录；能自动探测时可省略。

登记后由 Claude Code 以 stdio 自动拉起，**无需手动起服务**。可用工具：`idalib_open` / `idalib_list` / `list_funcs` / `analyze_function` / `decompile` / `callees` / `idalib_close` 等。

## （可选）HTTP 服务方式
如果你用的是 HTTP 变体（老的 `idalib-mcp --host --port`），可用 `skills/ida-reverse/scripts/start.sh`（Linux/Mac）或 `start.ps1`（Windows）拉起；但 Claude Code 场景推荐上面的 stdio 方式。

## 踩坑提示
- 一台机器上 idalib **许可通常单实例**：GUI 的 IDA 和 headless 会抢许可。跑 headless 分析时先关掉占用许可的 GUI/残留进程。
- 大型库（数十万函数）首次分析较久；分析好的 `.i64` 复用可秒开。
