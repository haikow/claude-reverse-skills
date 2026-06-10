# install.ps1 — 把仓库里的逆向 skill 安装到 Claude Code 的 skills 目录（Windows）
# 用法: powershell -ExecutionPolicy Bypass -File install.ps1
#       $env:SKILLS_DIR='D:\custom'; ./install.ps1
$ErrorActionPreference = 'Stop'
$SelfDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src  = Join-Path $SelfDir 'skills'
$Dest = if ($env:SKILLS_DIR) { $env:SKILLS_DIR } else { Join-Path $env:USERPROFILE '.claude\skills' }

New-Item -ItemType Directory -Force $Dest | Out-Null
Write-Host "==> 安装 skill 到 $Dest"
Get-ChildItem -Directory $Src | ForEach-Object {
    $name = $_.Name
    $target = Join-Path $Dest $name
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    Copy-Item $_.FullName $target -Recurse -Force
    Write-Host "    + $name"
}

Write-Host ""
Write-Host "==> 完成。已安装："
Get-ChildItem -Directory $Dest | ForEach-Object { Write-Host "    $($_.Name)" }

@"

==> 还需自行安装的命令行工具（按需，加进 PATH）：
    - radare2     : choco install radare2 / 官方 release
    - frida       : pip install --user frida-tools  (设备端另需 frida-server)
    - jadx        : choco install jadx / 官方 release
    - apktool     : 官方 bat + jar 放进 PATH
    - Android SDK : adb / aapt2 / zipalign / apksigner（platform-tools + build-tools）
    - JDK         : keytool（签名用）
    - Node.js     : mcp-js-reverse-playbook 用
    - NDK         : 编 native（如需）

==> IDA MCP（可选，需自备 IDA Pro + idalib 商业授权）：
    见 mcp\README.md：pip install ida-multi-mcp，再把配置片段加进 %USERPROFILE%\.claude.json
"@ | Write-Host
