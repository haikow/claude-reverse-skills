#!/usr/bin/env bash
# install.sh — 把仓库里的逆向 skill 安装到 Claude Code 的 skills 目录（Linux/Mac）
# 用法: ./install.sh            # 安装全部 skill 到 ~/.claude/skills/
#       SKILLS_DIR=/custom ./install.sh
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SELF_DIR/skills"
DEST="${SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$DEST"
echo "==> 安装 skill 到 $DEST"
for d in "$SRC"/*/; do
  name="$(basename "$d")"
  rm -rf "$DEST/$name"
  cp -r "$d" "$DEST/$name"
  # 给脚本加可执行位
  find "$DEST/$name" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  echo "    + $name"
done

echo
echo "==> 完成。已安装："
ls -1 "$DEST" | sed 's/^/    /'

cat <<'EOF'

==> 还需自行安装的命令行工具（按需，走包管理器）：
    - radare2     : brew install radare2 / apt install radare2
    - frida       : pipx install frida-tools  (设备端另需 frida-server)
    - jadx        : brew install jadx / 官方 release
    - apktool     : brew install apktool / 官方脚本
    - Android SDK : adb / aapt2 / zipalign / apksigner（platform-tools + build-tools）
    - JDK         : keytool（签名用）
    - Node.js     : mcp-js-reverse-playbook 用
    - NDK         : 编 native（如需）

==> IDA MCP（可选，需自备 IDA Pro + idalib 商业授权）：
    见 mcp/README.md：pip install ida-multi-mcp，再把配置片段加进 ~/.claude.json
EOF
