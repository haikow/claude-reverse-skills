#!/usr/bin/env bash
# manifest-summary.sh — 汇总 apktool 解出的 AndroidManifest.xml（对应 manifest-summary.ps1）
# 用 python3 解析 XML（跨平台）。从 .ps1 移植，未在 Linux/Mac 实测。
# 用法: manifest-summary.sh <AndroidManifest.xml>
set -euo pipefail
MAN="${1:-}"
[ -n "$MAN" ] && [ -f "$MAN" ] || { echo "manifest not found: $MAN" >&2; exit 1; }
command -v python3 >/dev/null && PY=python3 || PY=python

"$PY" - "$MAN" <<'PY'
import sys, xml.etree.ElementTree as ET
A='{http://schemas.android.com/apk/res/android}'
root=ET.parse(sys.argv[1]).getroot()
def a(n,k): return n.get(A+k,'')
print("package="+root.get('package',''))
perms=root.findall('uses-permission')
print("permission_count=%d"%len(perms))
for p in perms:
    if a(p,'name'): print("permission="+a(p,'name'))
app=root.find('application')
for label,tag in [('activity','activity'),('service','service'),('receiver','receiver'),('provider','provider')]:
    nodes=app.findall(tag) if app is not None else []
    print("%s_count=%d"%(label,len(nodes)))
    for n in nodes:
        print("%s=%s\t%s\t%s"%(label,a(n,'name'),a(n,'exported'),a(n,'enabled')))
mains=set()
for act in (app.findall('activity') if app is not None else []):
    for f in act.findall('intent-filter'):
        hasM=any(a(x,'name')=='android.intent.action.MAIN' for x in f.findall('action'))
        hasL=any(a(x,'name')=='android.intent.category.LAUNCHER' for x in f.findall('category'))
        if hasM and hasL: mains.add(a(act,'name'))
for m in sorted(mains): print("main_activity="+m)
PY
