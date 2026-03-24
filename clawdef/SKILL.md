---
name: clawdef
version: 1.0.0
description: |
  ClawDef — AI Agent Token Optimization & Control Platform / AI Agent Token 优化与管控平台.
  一键部署监控仪表盘：Token 实时追踪、智能成本预估、自动选最便宜模型、
  傻瓜式模型接入（8大厂商一键 Key）、智能守护引擎（自动省 Token）、预算管控、故障转移、实时日志、多用户管理。
  Help users minimize token consumption and costs / 帮用户最大限度节省 Token 和费用。
metadata:
  tags: [monitoring, cost-optimization, dashboard, token-management, multi-model, smart-optimizer]
  category: productivity
---

# ClawDef — AI Agent Token Optimization & Control / AI Agent Token 优化与管控平台

> 🇨🇳 中文用户友好 | 🌐 Built-in i18n (中文/English) | 🧠 Smart Auto-Optimizer

## What It Does / 功能

ClawDef is a self-hosted monitoring & optimization platform for OpenClaw that helps users:

ClawDef 是 OpenClaw 的自托管监控与优化平台：

| Feature | 功能 |
|---------|------|
| 🧠 **Smart Auto-Optimizer** — Analyzes task complexity & budget, auto-switches to cheapest model every 5min | 🧠 **智能守护引擎** — 每5分钟自动分析任务复杂度和预算，自动切到最便宜模型 |
| 💰 **Cost Estimator** — Input task → see estimated cost, compare models, one-click switch | 💰 **成本预估** — 输入任务→显示费用预估、模型对比、一键切换 |
| 📊 **Real-time Dashboard** — Token/cost tracking, cache hit rate, waste detection | 📊 **实时仪表盘** — Token/费用追踪、Cache命中率、浪费检测 |
| 🤖 **Fool-proof Model Setup** — 8 providers (Zhipu/OpenAI/Claude/DeepSeek/Qwen/Kimi/Gemini), just fill API Key | 🤖 **傻瓜式模型接入** — 8大厂商一键Key接入 |
| 💳 **Budget Control** — Daily/monthly limits, 80%/95% auto-downgrade | 💳 **预算管控** — 日/月限额，80%/95%自动降级 |
| 🔄 **Failover** — Auto-detect unhealthy models, switch automatically | 🔄 **故障转移** — 自动检测不健康模型并切换 |
| 🚨 **Emergency** — One-click shutdown Gateway or disable all skills | 🚨 **紧急控制** — 一键停Gateway/禁用全部技能 |
| 👥 **Multi-user** — Admin/Editor/Viewer roles | 👥 **多用户** — 管理员/编辑/查看者角色 |

## 🧠 How It Saves Tokens / 如何省钱

The smart optimizer runs automatically in the background. Users don't need to do anything:

智能守护引擎在后台自动运行，用户无需操作：

1. **Budget Guard** / 预算守卫 — Auto-downgrade when budget >80%, emergency stop at >95%
2. **Rate Anomaly** / 消费异常 — Detect abnormal spending rate, auto-downgrade
3. **Complexity Awareness** / 复杂度感知 — 70%+ simple tasks → switch to cheap model; tasks get complex + budget OK → upgrade back
4. **Auto-Recover** / 自动恢复 — Budget back to normal → restore balanced model
5. **Cache Optimization** / 缓存优化 — Monitor cache hit rate, suggest improvements

## Prerequisites / 前置条件

- Node.js v18+ (Node.js v18+)
- OpenClaw installed and running (已安装并运行 OpenClaw)
- Root or sudo access for systemd service (需要 root/sudo 权限)

## Quick Install / 快速安装

```bash
# Just one command / 只需一行命令
bash ~/.openclaw/workspace/skills/clawdef/scripts/install.sh
```

## Access / 访问

- URL: `http://<your-server-ip>:3456`
- Default login / 默认账号: `admin` / `admin` (change immediately / 请立即修改)

## API Endpoints

All endpoints require `Authorization: Bearer <token>` (所有接口需认证).

### Core / 核心
- `POST /api/auth/login` — Login / 登录
- `GET /api/dashboard` — Dashboard stats / 仪表盘数据
- `POST /api/collect` — Trigger data collection / 触发数据收集

### Token Optimization / Token 优化
- `POST /api/optimize/estimate` — Estimate cost for a task / 任务成本预估
- `GET /api/optimizer/status` — Smart optimizer status / 智能守护状态
- `POST /api/optimizer/force-cheap` — Force cheapest model / 强制省钱模式
- `POST /api/optimizer/force-balanced` — Force balanced model / 均衡模式
- `POST /api/optimizer/disable` — Pause optimizer 24h / 暂停24小时
- `GET /api/waste-analysis` — Token waste analysis / Token 浪费分析

### Models / 模型
- `GET /api/templates` — List provider templates / 模型厂商模板列表
- `POST /api/templates/setup` — One-click setup / 一键接入
- `GET /api/models` — List configured providers / 已配置的 Provider
- `POST /api/models/active` — Set active model / 设置当前模型
- `GET /api/failover` — Model health & failover / 模型健康与故障转移
- `POST /api/failover/check` — Health check a model / 检测模型
- `POST /api/failover/cheapest` — Switch to cheapest / 切到最便宜

### Budget & Alerts / 预算与告警
- `GET /api/budgets` — List budgets / 预算列表
- `POST /api/budgets` — Create/update budget / 创建/更新预算
- `GET /api/alerts` — List alerts / 告警列表

### Skills / 技能
- `GET /api/skills` — List skills with usage stats / 技能列表（含使用统计）
- `POST /api/skills/:name/toggle` — Enable/disable skill / 启用/禁用技能

### Control / 控制
- `POST /api/emergency/shutdown` — Stop Gateway / 停止 Gateway
- `POST /api/emergency/disable-all-skills` — Disable all skills / 禁用全部技能
- `POST /api/gateway/restart` — Restart Gateway / 重启 Gateway
- `POST /api/chat` — Chat with OpenClaw Agent / AI 对话

## Supported Providers / 支持的模型厂商

| Provider | API | Models |
|----------|-----|--------|
| 🇨🇳 智谱 Zhipu | OpenAI Compat | GLM-5-Turbo, glm-5, glm-4.7, glm-4.6, glm-4.5-air, glm-4.5 |
| 🇺🇸 OpenAI | OpenAI | gpt-4o, gpt-4o-mini, o3-mini |
| 🤖 Anthropic Claude | Anthropic | claude-sonnet-4-6, claude-3-5-haiku |
| 🔍 DeepSeek | OpenAI Compat | deepseek-chat, deepseek-reasoner |
| ☁️ 通义 Qwen | OpenAI Compat | qwen-max, qwen-plus, qwen-turbo |
| 🌙 Moonshot/Kimi | OpenAI Compat | moonshot-v1-128k, moonshot-v1-32k |
| 💎 Google Gemini | OpenAI Compat | gemini-2.5-pro, gemini-2.5-flash, gemini-2.0-flash |
| 🔧 Custom | OpenAI Compat | Any OpenAI-compatible API |

## Uninstall / 卸载

```bash
systemctl stop openclaw-monitor && systemctl disable openclaw-monitor
rm -rf /opt/openclaw-monitor && rm /etc/systemd/system/openclaw-monitor.service
systemctl daemon-reload
```
