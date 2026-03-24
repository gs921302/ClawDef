#!/bin/bash
set -e
# ClawDef — One-click installer for OpenClaw Token Optimization Platform

CLAWDEF_DIR="/opt/openclaw-monitor"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NODE_BIN="${NVM_DIR:-$HOME/.nvm}/current/bin/node"

echo "═══════════════════════════════════════════"
echo "  ClawDef — Token 优化与管控平台 安装"
echo "═══════════════════════════════════════════"

# Check node
if [ -n "$NODE_BIN" ] && [ -x "$NODE_BIN" ]; then
  echo "✅ Node: $($NODE_BIN --version)"
else
  NODE_BIN=$(which node 2>/dev/null || true)
  if [ -z "$NODE_BIN" ]; then
    echo "❌ Node.js not found. Install via nvm or apt."
    exit 1
  fi
  echo "✅ Node: $($NODE_BIN --version)"
fi

# Create directory
echo "📁 Creating $CLAWDEF_DIR..."
mkdir -p "$CLAWDEF_DIR/data" "$CLAWDEF_DIR/public" "$CLAWDEF_DIR/scripts"

# Copy server
echo "📦 Copying server..."
cp "$SKILL_DIR/scripts/server.js" "$CLAWDEF_DIR/server.js"

# Copy frontend
echo "📦 Copying frontend..."
cp "$SKILL_DIR/public/index.html" "$CLAWDEF_DIR/public/index.html"

# Copy security scripts
cp "$SKILL_DIR/scripts/security-audit.sh" "$CLAWDEF_DIR/scripts/security-audit.sh" 2>/dev/null || true
cp "$SKILL_DIR/scripts/emergency-breaker.sh" "$CLAWDEF_DIR/scripts/emergency-breaker.sh" 2>/dev/null || true

# Install dependencies
echo "📦 Installing npm dependencies..."
cd "$CLAWDEF_DIR"
if [ -f package.json ]; then
  "$NODE_BIN" --version > /dev/null 2>&1 && npm install --production 2>/dev/null || "$NODE_BIN" --version > /dev/null 2>&1 && "$NODE_BIN" "$NVM_DIR/current/lib/node_modules/npm/bin/npm-cli.js" install --production 2>/dev/null
fi

# Use correct node path in systemd
NODE_PATH=$(readlink -f "$NODE_BIN")
echo "🔧 Using Node at: $NODE_PATH"

# Create systemd service
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/openclaw-monitor.service << EOF
[Unit]
Description=ClawDef — Token 优化与管控平台
After=network.target

[Service]
Type=simple
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${NVM_DIR:-$HOME/.nvm}/current/bin:${HOME}/.local/share/pnpm
ExecStart=$NODE_PATH $CLAWDEF_DIR/server.js
WorkingDirectory=$CLAWDEF_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw-monitor
systemctl restart openclaw-monitor

sleep 2
if systemctl is-active --quiet openclaw-monitor; then
  IP=$(hostname -I | awk '{print $1}')
  echo ""
  echo "═══════════════════════════════════════════"
  echo "  ✅ ClawDef 安装成功！"
  echo "═══════════════════════════════════════════"
  echo "  访问: http://$IP:3456"
  echo "  账号: admin / admin (请立即修改密码)"
  echo "  服务: systemctl status openclaw-monitor"
  echo "═══════════════════════════════════════════"
else
  echo "❌ 服务启动失败，请检查: journalctl -u openclaw-monitor -n 20"
  exit 1
fi
