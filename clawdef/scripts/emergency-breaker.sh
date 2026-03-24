#!/bin/bash
# OpenClaw Monitor - 紧急熔断脚本
# 当 token 消耗或异常行为触发阈值时自动禁用指定技能并重启 Gateway
# 用法: /opt/openclaw-monitor/scripts/emergency-breaker.sh [--dry-run]

DRY_RUN=""
[ "$1" = "--dry-run" ] && DRY_RUN="echo [DRY-RUN] "

API="http://localhost:3456/api"
OPENCLAW_DIR="${OPENCLAW_DIR:-/root/.openclaw}"
CONFIG="$OPENCLAW_DIR/openclaw.json"

# ─── 阈值配置 ───
# 单次请求最大 token（超过此值视为异常）
MAX_TOKENS_PER_REQUEST=500000
# 每小时最大 token 消耗
MAX_TOKENS_PER_HOUR=2000000
# 每日最大 token 消耗
MAX_TOKENS_PER_DAY=10000000

# 需要熔断的技能列表（高风险技能，可自定义）
HIGH_RISK_SKILLS=()

echo "=== OpenClaw 紧急熔断检查 $(date) ==="

# 1. Check hourly token consumption
echo "[1] 检查每小时 Token 消耗..."
python3 << 'PYEOF'
import urllib.request, json, sys
try:
    resp = urllib.request.urlopen('http://localhost:3456/api/dashboard', timeout=5)
    d = json.loads(resp.read())
    stats = d.get('stats', {})
    total = stats.get('total_tokens', 0)

    MAX_PER_DAY = 10000000
    if total > MAX_PER_DAY:
        data = json.dumps({
            'level': 'critical',
            'category': 'circuit-breaker',
            'title': '日 Token 消耗超限',
            'message': f'今日已消耗 {total} tokens，超过阈值 {MAX_PER_DAY}'
        }).encode()
        req = urllib.request.Request('http://localhost:3456/api/alerts', data=data,
            headers={'Content-Type':'application/json'}, method='POST')
        urllib.request.urlopen(req, timeout=5)
        print(f"    🚨 日消耗 {total} 超过阈值 {MAX_PER_DAY}！")
    else:
        print(f"    ✅ 日消耗 {total} / {MAX_PER_DAY}")

    # Check hourly
    hourly = d.get('hourly', [])
    current_hour = str(__import__('datetime').datetime.now().hour).zfill(2)
    for h in hourly:
        if h.get('hour') == current_hour and h.get('tokens', 0) > 2000000:
            data = json.dumps({
                'level': 'critical',
                'category': 'circuit-breaker',
                'title': '小时 Token 消耗超限',
                'message': f'当前小时已消耗 {h["tokens"]} tokens'
            }).encode()
            req = urllib.request.Request('http://localhost:3456/api/alerts', data=data,
                headers={'Content-Type':'application/json'}, method='POST')
            urllib.request.urlopen(req, timeout=5)
            print(f"    🚨 小时消耗 {h['tokens']} 超过阈值！")
            break
    else:
        cur_tokens = next((h.get('tokens',0) for h in hourly if h.get('hour')==current_hour), 0)
        print(f"    ✅ 当前小时消耗 {cur_tokens} / 2000000")

except Exception as e:
    print(f"    ❌ 检查失败: {e}")
PYEOF

# 2. Check for skills with suspicious token patterns
echo "[2] 检查技能异常消耗模式..."
python3 << 'PYEOF'
import urllib.request, json
try:
    resp = urllib.request.urlopen('http://localhost:3456/api/tools?limit=500', timeout=5)
    d = json.loads(resp.read())
    tools = d.get('data', [])

    # Group by skill, check for unusual patterns
    from collections import defaultdict
    skill_tokens = defaultdict(int)
    skill_calls = defaultdict(int)

    for t in tools:
        skill = t.get('skill_name') or 'direct'
        skill_tokens[skill] += (t.get('tokens_in_request',0) or 0) + (t.get('tokens_in_response',0) or 0)
        skill_calls[skill] += 1

    for skill, tokens in sorted(skill_tokens.items(), key=lambda x: -x[1]):
        if skill == 'direct': continue
        avg = tokens / max(skill_calls[skill], 1)
        if avg > 200000:
            data = json.dumps({
                'level': 'warning',
                'category': 'circuit-breaker',
                'title': f'技能 {skill} 消耗异常',
                'message': f'平均 {avg:.0f} tokens/调用 ({skill_calls[skill]} 次调用, 共 {tokens} tokens)'
            }).encode()
            req = urllib.request.Request('http://localhost:3456/api/alerts', data=data,
                headers={'Content-Type':'application/json'}, method='POST')
            urllib.request.urlopen(req, timeout=5)
            print(f"    ⚠️ {skill}: 平均 {avg:.0f} tokens/调用")

    if not any(tokens / max(skill_calls[s], 1) > 200000 for s, tokens in skill_tokens.items() if s != 'direct'):
        print("    ✅ 所有技能消耗正常")

except Exception as e:
    print(f"    ❌ 检查失败: {e}")
PYEOF

# 3. Check if gateway is responsive
echo "[3] 检查 Gateway 健康状态..."
GW_OK=1
if timeout 5 bash -c 'openclaw gateway status &>/dev/null' 2>/dev/null; then
    echo "    ✅ Gateway 正常响应"
else
    echo "    ❌ Gateway 无响应"
    python3 -c "
import urllib.request, json
data = json.dumps({
    'level': 'critical',
    'category': 'health',
    'title': 'Gateway 无响应',
    'message': 'Gateway 进程未响应或已崩溃'
}).encode()
req = urllib.request.Request('http://localhost:3456/api/alerts', data=data,
    headers={'Content-Type':'application/json'}, method='POST')
urllib.request.urlopen(req, timeout=5)
" 2>/dev/null
    GW_OK=0
fi

echo ""
echo "=== 熔断检查完成 ==="
