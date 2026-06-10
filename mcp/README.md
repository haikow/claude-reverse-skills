# MCP：ida-multi-mcp（IDA Pro 多实例 MCP 服务）

本仓库**不分发** `ida-multi-mcp` 的源码——它是第三方 **MIT** 包，来自 GitHub 仓库 **[MeroZemory/ida-multi-mcp](https://github.com/MeroZemory/ida-multi-mcp)**（本身跨平台）。

> `ida-multi-mcp`：Multi-instance IDA Pro MCP server for simultaneous reverse engineering（License: MIT）。
> ⚠️ 该包**未发布到 PyPI**，`pip install ida-multi-mcp` 会 404；只能从 GitHub 源码安装（见下）。

## 前置：IDA Pro + idalib（商业授权，需自备）
- 需要 **IDA Pro 9.x** 且带 **idalib**（headless 分析库）。这是商业软件，本仓库不提供。
- 让 idalib 能被找到：设置环境变量 `IDADIR` 指向你的 IDA 安装目录（含 `idalib`/`idapython`）。
- **只设 `IDADIR` 还不够**：headless 用 idalib 前，要先装 IDA 自带的 `idapro` wheel 并激活，否则 `import idapro` 会报 `ModuleNotFoundError`：
  ```bash
  # 路径按你的 IDA 安装目录调整
  pip install "$IDADIR/idalib/python/idapro-"*.whl
  python "$IDADIR/idalib/python/py-activate-idalib.py" -d "$IDADIR"
  ```

## 安装
`ida-multi-mcp` 未上 PyPI，从 GitHub 源码装（建议用独立 venv，避免污染系统 Python）：
```bash
python3 -m venv ~/.venvs/ida-mcp
# 直接装最新源码：
~/.venvs/ida-mcp/bin/pip install "git+https://github.com/MeroZemory/ida-multi-mcp"
# 或先 clone 再装（可固定到已验证的 v0.1.0）：
#   git clone https://github.com/MeroZemory/ida-multi-mcp && \
#   ~/.venvs/ida-mcp/bin/pip install ./ida-multi-mcp
```

### 可选：一键配置 MCP 客户端
该包自带 `--install`，会软链 IDA 插件并自动把配置写进各 MCP 客户端（Claude Code / Cursor / Codex 等）：
```bash
~/.venvs/ida-mcp/bin/python -m ida_multi_mcp --install --ida-dir "$IDADIR"
```
> 注意：`--install` 写入的 `command` 可能指向当前 PATH 里的 python，未必是上面的 venv。请核对各客户端配置里的 `command` 是否为 `~/.venvs/ida-mcp/bin/python`，并在 `env` 里补上 `IDADIR`。手动登记见下一节。

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

## IDA GUI 插件加载失败（命名冲突 / venv 解释器）
如果用 `--install` 装完后，打开 IDA（或 `idat`）报：
```
[ida-multi-mcp] ERROR: Could not load plugin: No module named 'ida_multi_mcp.plugin'; 'ida_multi_mcp' is not a package
```
有两个叠加原因：
1. **命名冲突**：`--install` 把 loader 软链成 `plugins/ida_multi_mcp.py`，**与包名 `ida_multi_mcp` 同名**——IDA 会把这个单文件当成顶层模块 `ida_multi_mcp`，于是子模块 `.plugin` 报 "is not a package"。
2. **解释器找不到包**：IDA 9.x 启动时**跟随当前 `VIRTUAL_ENV` 选 Python 解释器**（日志会打印 `Requested to use virtual environment interpreter at ...`），未必是你装 `ida-multi-mcp` 的那个 venv；而 loader 内置的候选搜索路径只覆盖 pip-user / pipx / 系统，**不含自定义 venv**。

**解决**：删掉撞名软链，换一个**文件名不与包名冲突**、且**主动把你的 venv 注入 `sys.path`** 的独立 loader：
```bash
rm -f "$IDADIR/plugins/ida_multi_mcp.py"
cat > "$IDADIR/plugins/mcp_multi_loader.py" <<'PY'
import sys, os, glob
# 改成你安装 ida-multi-mcp 的 venv
for sp in sorted(glob.glob(os.path.expanduser("~/.venvs/ida-mcp/lib/python3.*/site-packages"))):
    if sp not in sys.path:
        sys.path.insert(0, sp)
def PLUGIN_ENTRY():
    from ida_multi_mcp.plugin.ida_multi_mcp import PLUGIN_ENTRY as _entry
    return _entry()
PY
```
> ⚠️ venv 的 Python 版本要和 IDA 实际用的解释器一致（如都 3.14），否则 `pydantic-core` 等带 C/Rust 扩展的依赖会 ABI 不匹配。
>
> 验证（无需开 GUI）：`idat -A -S"/tmp/pp.py" -L/tmp/ida.log <可写目录里的目标文件>`，日志出现 `[ida-multi-mcp] Plugin loaded` 即成功（注意 9.x 只有 `idat`，没有 `idat64`；目标要放在可写目录，否则 `.i64` 写不出来）。

## 踩坑提示
- 一台机器上 idalib **许可通常单实例**：GUI 的 IDA 和 headless 会抢许可。跑 headless 分析时先关掉占用许可的 GUI/残留进程。
- 大型库（数十万函数）首次分析较久；分析好的 `.i64` 复用可秒开。
