#!/bin/bash
# OpenClaw Monitor - 安全审计脚本
# 定期扫描技能风险、检查 Gateway 配置安全、检测异常 token 消耗
# 建议配合 cron: */5 * * * * /opt/openclaw-monitor/scripts/security-audit.sh

OPENCLAW_DIR="${OPENCLAW_DIR:-/root/.openclaw}"
API="http://localhost:3456/api"

echo "=== OpenClaw 安全审计 $(date) ==="

# 1. Run OpenClaw's built-in audit
echo "[1] 运行 OpenClaw 内置安全审计..."
AUDIT=$(openclaw security audit --json 2>/dev/null || echo '{}')
CRITICAL=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len([f for f in d.get('findings',[]) if f.get('severity')=='critical']))" 2>/dev/null || echo "0")
echo "    发现 $CRITICAL 个严重问题"

# Report critical findings to monitor API
if [ "$CRITICAL" -gt 0 ]; then
    echo "$AUDIT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for f in d.get('findings', []):
    if f.get('severity') == 'critical':
        try:
            import urllib.request
            data = json.dumps({
                'level': 'critical',
                'category': 'security-audit',
                'title': f.get('checkId', 'unknown'),
                'message': f.get('message', f.get('checkId', ''))[:500]
            }).encode()
            req = urllib.request.Request('$API/alerts', data=data, headers={'Content-Type':'application/json'}, method='POST')
            urllib.request.urlopen(req, timeout=5)
        except: pass
" 2>/dev/null
    echo "    已上报严重告警到监控面板"
fi

# 2. Check for suspicious skill files
echo "[2] 扫描技能文件..."
find "$OPENCLAW_DIR/skills" "$OPENCLAW_DIR/workspace/skills" "$OPENCLAW_DIR/extensions" \
    -name "*.js" -not -path "*/node_modules/*" -o -name "*.sh" -not -path "*/node_modules/*" -o -name "*.py" -not -path "*/node_modules/*" 2>/dev/null | while read f; do
    # Check for common data exfil patterns
    if grep -qiE 'curl.*\$\{|wget.*\$\{|base64|eval\(|child_process|os\.system|requests\.post' "$f" 2>/dev/null; then
        echo "    ⚠️ 可疑文件: $f"
        python3 -c "
import urllib.request, json
data = json.dumps({
    'level': 'warning',
    'category': 'skill-scan',
    'title': '可疑技能代码',
    'message': '文件包含潜在危险代码: $f'
}).encode()
req = urllib.request.Request('$API/alerts', data=data, headers={'Content-Type':'application/json'}, method='POST')
urllib.request.urlopen(req, timeout=5)
" 2>/dev/null
    fi
done

# 3. Check token consumption anomaly
echo "[3] 检查 Token 消耗异常..."
python3 -c "
import urllib.request, json
try:
    req = urllib.request.Request('$API/dashboard')
    resp = urllib.request.urlopen(req, timeout=5)
    d = json.loads(resp.read())
    stats = d.get('stats', {})
    tokens = stats.get('total_tokens', 0)
    requests = stats.get('total_requests', 0)

    # If avg tokens per request > 100K, flag it
    if requests > 0:
        avg = tokens / requests
        if avg > 100000:
            data = json.dumps({
                'level': 'warning',
                'category': 'token-anomaly',
                'title': 'Token 消耗异常偏高',
                'message': f'平均每次请求 {avg:.0f} tokens (共 {requests} 次请求, {tokens} tokens)'
            }).encode()
            req = urllib.request.Request('$API/alerts', data=data, headers={'Content-Type':'application/json'}, method='POST')
            urllib.request.urlopen(req, timeout=5)
            print(f'    ⚠️ 平均 {avg:.0f} tokens/请求，已上报')
        else:
            print(f'    ✅ 平均 {avg:.0f} tokens/请求，正常')
except Exception as e:
    print(f'    检查失败: {e}')
" 2>/dev/null

# 4. Check gateway config permissions
echo "[4] 检查配置权限..."
CONFIG="$OPENCLAW_DIR/openclaw.json"
if [ -f "$CONFIG" ]; then
    PERMS=$(stat -c '%a' "$CONFIG" 2>/dev/null)
    if [ "$PERMS" != "600" ]; then
        echo "    ⚠️ 配置文件权限过宽: $PERMS (建议 600)"
        chmod 600 "$CONFIG" 2>/dev/null && echo "    已修复为 600"
    else
        echo "    ✅ 配置权限: 600"
    fi
fi

DIR_PERMS=$(stat -c '%a' "$OPENCLAW_DIR" 2>/dev/null)
if [ "$DIR_PERMS" != "700" ]; then
    echo "    ⚠️ OpenClaw 目录权限过宽: $DIR_PERMS (建议 700)"
    chmod 700 "$OPENCLAW_DIR" 2>/dev/null && echo "    已修复为 700"
else
    echo "    ✅ 目录权限: 700"
fi

# 5. Check for plugins without allowlist
echo "[5] 检查插件白名单..."
if [ -f "$CONFIG" ]; then
    ALLOW=$(python3 -c "import json; d=json.load(open('$CONFIG')); print(d.get('plugins',{}).get('allow','NOT_SET'))" 2>/dev/null)
    if [ "$ALLOW" = "NOT_SET" ] || [ "$ALLOW" = "" ]; then
        echo "    ⚠️ plugins.allow 未设置，所有插件自动加载"
        python3 -c "
import urllib.request, json
data = json.dumps({
    'level': 'warning',
    'category': 'config',
    'title': '插件白名单未设置',
    'message': 'plugins.allow 为空，所有已安装插件自动加载，建议显式白名单'
}).encode()
req = urllib.request.Request('$API/alerts', data=data, headers={'Content-Type':'application/json'}, method='POST')
urllib.request.urlopen(req, timeout=5)
" 2>/dev/null
    else
        echo "    ✅ 插件白名单已配置"
    fi
fi

echo ""
echo "=== 审计完成 ==="
