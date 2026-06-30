# claude-reverse-skills

一套面向 **Claude Code**（及兼容的文件系统型 Agent）的**逆向工程 Skill 集合**，外加 IDA Pro MCP 的接入说明。跨平台（Linux / macOS / Windows），一条命令装进 `~/.claude/skills/`。

> 🙏 **来源**：核心 Skill 来自 **linux.do 论坛 [@hisence](https://linux.do/u/hisence) 大佬**的分享 —— 原帖 👉 https://linux.do/t/topic/2142539 。本仓库仅做整理与跨平台适配，致谢原作者（详见文末「许可与致谢」）。

## 相关资源（备选）

做逆向时，AI（含 Claude Code）有时会因为安全策略对某些操作拒答。
多数情况用本仓库的 skill + 本机工具（jadx / frida / r2 / IDA）就能完成，不必提权。
仅在确认是合理安全研究、却被护栏硬拦住时，可参考：

- **ClawGod** — https://github.com/0Chencc/clawgod
  - 性质：对官方 Claude Code 的 **runtime 补丁**，会替换本地 `claude` 可执行文件
    （原版备份为 `claude.orig`），并改写 guard policy / scene-router 等安全钩子，
    本质是**绕过 Claude Code 的安全护栏**。
  - 适用：撞到 AI 因安全策略拒绝执行，且无法靠调整请求或换 skill 解决时。
  - ⚠️ 风险：替换官方二进制、绕过安全机制、可能违反 Anthropic 服务条款；
    与官方升级存在兼容/稳定性风险。启用前自行评估，后果自负。
  - 本仓库仅作**信息收录**，不分发其源码、不背书其使用。

## 包含的 Skill

| Skill | 用途 |
|---|---|
| `reverse-engineering` | 通用逆向方法论（混淆/壳/字节码/反调试/固件/CTF 等思路） |
| `ida-reverse` | IDA Pro / idalib 逆向（配合 `ida-multi-mcp`，见 `mcp/`） |
| `apk-reverse` | Android APK：解包、Java 反编译、smali、重打包签名、Frida Hook、so 分析 |
| `radare2` | radare2 / rabin2 命令行逆向（侦察、反汇编、补丁、diff） |
| `mcp-js-reverse-playbook` | 前端 JavaScript 逆向（签名链定位、补环境、运行时采样） |

## 快速安装

```bash
# Linux / macOS
git clone https://github.com/haikow/claude-reverse-skills && cd claude-reverse-skills
./install.sh        # 拷到 ~/.claude/skills/

# Windows (PowerShell)
git clone https://github.com/haikow/claude-reverse-skills; cd claude-reverse-skills
powershell -ExecutionPolicy Bypass -File install.ps1
```

安装脚本会把 5 个 skill 复制到 Claude Code 的 skills 目录，并列出**还需自行安装的命令行工具**（见下）。

## 前置工具（按需安装，均走 PATH）

| 工具 | Linux/Mac | Windows |
|---|---|---|
| radare2 | `apt/brew install radare2` | `choco install radare2` |
| frida-tools | `pipx install frida-tools` | `pip install --user frida-tools` |
| jadx | `brew install jadx` | `choco install jadx` |
| apktool | `brew install apktool` | 官方 bat+jar 入 PATH |
| Android SDK | platform-tools + build-tools（adb/aapt2/zipalign/apksigner） | 同左 |
| JDK | keytool（签名） | 同左 |
| Node.js | JS 逆向用 | 同左 |

> 设备端 Frida 需另跑 `frida-server`；Android 重打包/Hook 需 Root + 设备。

## IDA Pro MCP（可选）

`ida-reverse` 配合第三方 MIT 包 **`ida-multi-mcp`**（从 [GitHub 源码](https://github.com/MeroZemory/ida-multi-mcp) 安装，未上 PyPI；本身跨平台），但**需自备 IDA Pro 9.x + idalib（商业授权）**。安装与 MCP 配置见 **[`mcp/README.md`](mcp/README.md)**。

## 跨平台说明

- **Skill 正文**（`SKILL.md` 及参考 `.md`）是纯 Markdown，三平台通用。
- **脚本**：每个带脚本的 skill 同时提供
  - `.ps1`（Windows，原始、已在 Windows 使用）
  - `.sh`（Linux/macOS，从 .ps1 移植，**走 PATH 查找、无写死路径**；⚠️ 未在 Linux/Mac 实测，欢迎反馈/PR）

## 许可与致谢

- **核心 Skill 来源**：linux.do 论坛 **[@hisence](https://linux.do/u/hisence)** 大佬分享的帖子 👉 **https://linux.do/t/topic/2142539** 。本仓库只做了**整理 + 跨平台（Linux/Mac）适配**，核心内容归功于原作者，特此致谢 🙏。
- 本仓库是 Skill 的**整理与跨平台适配**集合，非全部原创。
- `reverse-engineering` skill 标注 **MIT**；`ida-multi-mcp` 为第三方 **MIT** 包（仅文档引用，未分发其源码）。
- 适配时把原帖中写死的本机路径占位化（`YOURNAME`）。如原作者 @hisence 希望补充/调整署名、变更授权或下架，请提 Issue 或与我联系。
- `apk-reverse/debug.keystore` 仅为本地调试签名用的占位密钥，**切勿用于正式发布**。

## 免责声明

仅供个人学习与安全研究。请勿用于侵犯他人权益或违反相关服务条款的用途，因使用本仓库内容产生的一切后果由使用者自行承担。
