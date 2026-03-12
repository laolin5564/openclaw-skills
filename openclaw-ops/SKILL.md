---
name: openclaw-ops
description: OpenClaw Gateway 运维技能：远程 SSH 排查学员部署问题、Gateway 启停与状态检查、配置修改、渠道连接、模型认证、心跳/Cron 调度、日志分析、故障诊断与修复。当需要帮助学员排查 OpenClaw 问题、检查 Gateway 状态、调试渠道连接、修复配置错误、处理认证问题时使用此技能。
---

# OpenClaw 运维技能

## 标准化巡检流程

使用 `scripts/openclaw-checkup.sh` 一键巡检，通过 SSH 远程执行：

```bash
cat scripts/openclaw-checkup.sh | ssh -p <PORT> <USER>@<HOST> 'bash -s'
```

巡检内容：
1. **版本检查** — 当前版本 + 是否有更新（不自动更新，只报告）
2. **Cron 检查** — 数量、调度频率、合理性分析（间隔<1min 🔴、<5min ⚠️）
3. **Session 检查** — 文件大小、数量、token 占比排序（≥60% 提醒 /compact）
4. **Session 深度检查** — sessions.json 文件大小（≥100MB 🔴）+ Gateway CPU 占用
5. **Gateway 状态** — 服务是否运行、LaunchAgent 状态
6. **渠道状态** — 各渠道连接探测
7. **工作区文件检查** — 各 .md 文件存在性、大小、是否冗余重复

如需更新版本，巡检后手动执行：
```bash
ssh ... 'export PATH="/opt/homebrew/bin:$PATH"; openclaw update'
```

## 排查流程（标准命令阶梯）

按顺序执行，任一步异常即停下来分析：

```bash
openclaw status                    # 总览：渠道、认证、版本
openclaw status --all              # 完整诊断（可粘贴分享）
openclaw gateway status            # Runtime: running + RPC probe: ok
openclaw doctor                    # 配置/服务健康检查
openclaw channels status --probe   # 渠道连接状态
openclaw logs --follow             # 实时日志
```

## 常见故障速查

### Gateway 无法启动
```bash
openclaw gateway status            # 确认状态
openclaw doctor                    # 查配置错误
openclaw doctor --fix              # 自动修复
openclaw gateway --force           # 强制占端口启动
openclaw gateway --port 18789 --verbose  # 前台 debug 启动
```
- 端口占用 → `--force` 或换端口
- 配置校验失败 → `openclaw doctor --fix`，或手动编辑 `~/.openclaw/openclaw.json`
- 服务未注册 → `openclaw gateway install`（注册 launchd/systemd）

### 无回复（消息发了没反应）
```bash
openclaw channels status --probe
openclaw pairing list --channel <channel>
openclaw config get channels
openclaw logs --follow
```
日志关键词：
- `drop guild message (mention required` → Discord 群需 @提及
- `pairing request` → 发送者待审批，`openclaw pairing approve`
- `blocked` / `allowlist` → 被策略拦截

### 渠道连接问题
```bash
openclaw channels status --probe   # 看哪个渠道断了
openclaw channels logout           # 登出
openclaw channels login --verbose  # 重新登录（会出 QR 码等）
```

### 模型认证
```bash
openclaw models status             # 查看当前模型和认证状态
openclaw models scan               # 扫描可用模型
```
- API Key 方式（推荐）：设 `ANTHROPIC_API_KEY` 或写入 `~/.openclaw/.env`
- setup-token：`openclaw models auth setup-token --provider anthropic`
- OpenRouter：`OPENROUTER_API_KEY` 环境变量

### Dashboard/Control UI 无法访问
- 默认地址 `http://127.0.0.1:18789`
- 需要 token：`openclaw dashboard`（自动打开带 token 的 URL）
- 远程访问需配置 `gateway.bind` 和认证

## 配置管理

配置文件：`~/.openclaw/openclaw.json`（JSON5 格式，支持注释）

```bash
openclaw config get <key>          # 读配置
openclaw config set <key> <value>  # 写配置
openclaw configure                 # 交互式配置向导
openclaw onboard                   # 完整新手引导
```

### 最小配置示例
```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { discord: { token: "BOT_TOKEN", allowFrom: ["user_id"] } },
}
```

### 配置热重载
Gateway 监听配置文件变化，自动应用。模式：`gateway.reload.mode="hybrid"`。

## 心跳与 Cron

### 心跳
```json5
{
  agents: { defaults: { heartbeat: { every: "30m", target: "last" } } }
}
```
- 默认 30m（Anthropic OAuth 为 1h）
- 无事回复 `HEARTBEAT_OK`，有事直接告警
- `activeHours` 可限制活跃时段

### Cron
```bash
openclaw cron list                 # 列出定时任务
openclaw cron runs <jobId>         # 查看执行历史
```
排查 → 见 [references/automation-troubleshooting.md](references/automation-troubleshooting.md)

## 日志分析

```bash
openclaw logs --follow             # 实时跟踪
openclaw logs --json               # JSON 格式
```
- 文件日志：`/tmp/openclaw/openclaw-YYYY-MM-DD.log`
- 级别：`logging.level`（文件）、`logging.consoleLevel`（控制台）
- `--verbose` 只影响控制台输出，不影响文件日志

## 远程运维（SSH 排查学员机器）

标准流程：
1. SSH 进入学员机器
2. 执行命令阶梯检查状态
3. 根据输出定位问题
4. 修复后验证 `openclaw status`
5. 在频道回报结果

### 环境变量
- Gateway 读取顺序：`~/.openclaw/.env` → shell env → systemd/launchd env
- 代理 key 放 `~/.openclaw/.env` 最可靠
- `OPENCLAW_GATEWAY_PORT`、`OPENCLAW_GATEWAY_TOKEN` 可覆盖默认值

### macOS LaunchAgent
```bash
launchctl list | grep openclaw     # 检查服务
openclaw gateway install           # 安装服务
openclaw gateway restart           # 重启
```

## 安装与更新

```bash
# 安装
curl -fsSL https://openclaw.ai/install.sh | bash
# 更新
openclaw update
# 新手引导
openclaw onboard --install-daemon
```

Node.js 22+ 必需。检查：`node --version`

## 安全检查

```bash
openclaw security                  # 安全审计
openclaw security --fix            # 自动修复安全问题
```
关注：hooks token 长度、反代 header、bind 模式、文件权限等。

## 详细参考

### 内部经验文档
- 自动化故障排查 → [references/automation-troubleshooting.md](references/automation-troubleshooting.md)
- 渠道配置详情 → [references/channels.md](references/channels.md)
- 实战案例库 → [references/case-studies.md](references/case-studies.md)

### 官方文档（已爬取本地化）
- **速查手册（必读）** → [references/official-docs-quickref.md](references/official-docs-quickref.md)
  - 安装命令、CLI 速查、配置结构、渠道配置、故障排查、Windows/Linux 注意事项
- Gateway 故障排查官方版 → [references/gateway-troubleshooting-official.md](references/gateway-troubleshooting-official.md)
- 安装指南官方版 → [references/install-official.md](references/install-official.md)
- 平台差异（macOS/Windows/Linux/Pi）→ [references/platforms-official.md](references/platforms-official.md)
- 模型 Provider 配置 → [references/providers-official.md](references/providers-official.md)

**文档更新**：`docs/openclaw/` 存有完整爬取版本（22个页面）。
