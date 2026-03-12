# OpenClaw 快速参考手册 (QUICK-REF)

> 从官方文档提炼，适合运维排查和学员引导。
> 文档来源：https://docs.openclaw.ai
> 整理时间：2026-03-02

---

## 目录

1. [安装命令](#1-安装命令)
2. [常用 CLI 命令速查](#2-常用-cli-命令速查)
3. [openclaw.json 配置结构](#3-openclaw-json-配置结构)
4. [渠道配置方法](#4-渠道配置方法)
5. [常见故障排查](#5-常见故障排查)
6. [Windows/Linux 特殊注意事项](#6-windowslinux-特殊注意事项)

---

## 1. 安装命令

### 推荐安装（脚本）

```bash
# macOS / Linux
curl -fsSL https://openclaw.ai/install.sh | bash

# Windows（PowerShell）
iwr -useb https://openclaw.ai/install.ps1 | iex
```

### 跳过新手引导安装

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
```

### 手动全局安装（已有 Node >=22）

```bash
npm install -g openclaw@latest

# 如遇 sharp/libvips 报错：
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest

# 使用 pnpm：
pnpm add -g openclaw@latest
pnpm approve-builds -g   # 批准构建脚本
pnpm add -g openclaw@latest   # 重跑以执行 postinstall
```

### 从源码安装（开发者）

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build
pnpm build
openclaw onboard --install-daemon
```

### 安装后初始化

```bash
openclaw onboard --install-daemon   # 新手引导 + 安装服务
openclaw doctor                      # 健康检查
openclaw status                      # 快速状态
openclaw health                      # Gateway 健康状态
```

### 更新

```bash
curl -fsSL https://openclaw.ai/install.sh | bash   # 重新运行安装器即可更新
```

### PATH 修复（找不到 openclaw 命令）

```bash
# 诊断
node -v && npm -v && npm prefix -g && echo "$PATH"

# 修复（写入 ~/.zshrc 或 ~/.bashrc）
export PATH="$(npm prefix -g)/bin:$PATH"
```

---

## 2. 常用 CLI 命令速查

### 状态与诊断

```bash
openclaw status                  # 快速状态概览
openclaw status --all            # 完整诊断（可粘贴分享）
openclaw status --deep           # 深度探测渠道
openclaw gateway status          # Gateway 服务状态
openclaw gateway status --deep   # 含系统级扫描
openclaw health                  # Gateway 健康检查
openclaw health --verbose        # 详细健康检查
openclaw doctor                  # 自动发现问题
openclaw doctor --fix            # 自动修复问题
openclaw logs --follow           # 实时日志
openclaw logs --limit 200        # 最近 200 条日志
```

### Gateway 管理

```bash
openclaw gateway start           # 启动 Gateway
openclaw gateway stop            # 停止 Gateway
openclaw gateway restart         # 重启 Gateway
openclaw gateway install         # 安装为系统服务
openclaw gateway uninstall       # 卸载系统服务
openclaw gateway --verbose       # 调试模式启动
openclaw gateway probe           # 探测 Gateway 可达性
```

### 渠道管理

```bash
openclaw channels list                                    # 列出所有渠道
openclaw channels status                                  # 渠道状态
openclaw channels status --probe                          # 深度探测渠道
openclaw channels logs                                    # 渠道日志
openclaw channels add --channel telegram --token $TOKEN   # 添加 Telegram
openclaw channels add --channel discord --token $TOKEN    # 添加 Discord
openclaw channels remove --channel discord --delete       # 删除渠道

# WhatsApp 专用
openclaw channels login          # 扫码登录 WhatsApp
openclaw channels logout         # 退出 WhatsApp

# 配对审批
openclaw pairing list telegram   # 待审批的配对请求
openclaw pairing approve telegram <CODE>   # 批准配对
```

### 模型管理

```bash
openclaw models                             # 模型状态概览
openclaw models list                        # 列出可用模型
openclaw models status                      # 认证 + 状态
openclaw models status --probe              # 实时探测
openclaw models set <model-id>              # 设置默认模型
openclaw models auth setup-token            # 设置 Anthropic token
openclaw models auth setup-token --provider anthropic
openclaw models auth paste-token --provider anthropic
openclaw models scan                        # 扫描可用模型
openclaw models fallbacks list              # 查看回退模型
openclaw models fallbacks add <model>       # 添加回退模型
```

### 配置管理

```bash
openclaw config get agents.defaults.workspace   # 读取配置
openclaw config set gateway.mode local           # 设置配置
openclaw config set gateway.bind loopback        # 设置绑定
openclaw config unset gateway.auth               # 删除配置
openclaw configure                                # 交互式配置向导
openclaw onboard                                  # 完整新手引导
```

### 会话与记忆

```bash
openclaw sessions                    # 列出会话
openclaw memory status               # 记忆索引状态
openclaw memory index                # 重建索引
openclaw memory search "关键词"      # 搜索记忆
```

### 重置与卸载

```bash
# 重置配置（保留 CLI）
openclaw reset --scope config --yes
openclaw reset --scope config+creds+sessions --yes
openclaw reset --scope full --yes

# 完全卸载
openclaw uninstall --all --yes
```

### 快捷命令

```bash
openclaw tui                    # 打开终端 UI
openclaw dashboard              # 打开仪表板
openclaw docs "关键词"          # 搜索文档
openclaw security audit         # 安全审计
openclaw security audit --deep  # 深度安全审计
```

---

## 3. openclaw.json 配置结构

**配置文件路径：** `~/.openclaw/openclaw.json`
**格式：** JSON5（支持注释和尾逗号）

> ⚠️ 严格验证：未知键或格式错误 → Gateway 拒绝启动

### 最小配置（推荐起点）

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { whatsapp: { allowFrom: ["+15555550123"] } },
}
```

### 完整配置结构示例

```json5
{
  // ── 智能体设置 ──────────────────────────────────────
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",     // 工作区路径
      repoRoot: "~/projects",                  // 仓库根目录
      userTimezone: "Asia/Shanghai",           // 时区
      timeFormat: "24h",                       // 时间格式
      model: {
        primary: "anthropic/claude-sonnet-4-5",
      },
      sandbox: {
        mode: "non-main",   // off | non-main | all
      },
    },
    // 多智能体配置
    list: [
      {
        id: "main",
        identity: {
          name: "大黄",
          emoji: "🐾",
          theme: "helpful assistant",
        },
        workspace: "~/.openclaw/workspace",
      },
    ],
  },

  // ── 渠道配置 ──────────────────────────────────────
  channels: {
    whatsapp: {
      selfChatMode: true,             // 自聊天模式
      dmPolicy: "allowlist",          // pairing | allowlist | open | disabled
      allowFrom: ["+8613800000000"],  // 白名单
      sendReadReceipts: false,        // 已读回执
      groups: {
        "*": { requireMention: true }, // 群组需要 @ 才回复
      },
    },
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",
      allowFrom: ["tg:123456789"],
      groups: {
        "*": { requireMention: true },
      },
    },
    discord: {
      enabled: true,
      token: "your-bot-token",
      dm: {
        enabled: true,
        policy: "pairing",
      },
      guilds: {
        "123456789012345678": {
          requireMention: false,
          channels: {
            general: { allow: true },
          },
        },
      },
    },
  },

  // ── Gateway 设置 ──────────────────────────────────
  gateway: {
    mode: "local",            // local | remote（必须设置！）
    port: 18789,
    bind: "loopback",        // loopback | lan | tailnet | auto | custom
    auth: {
      mode: "token",
      token: "your-secret-token",
    },
  },

  // ── 自定义模型/提供商 ─────────────────────────────
  models: {
    providers: {
      "openai-compatible": {
        baseUrl: "http://localhost:1234/v1",
        models: [{ id: "local-model" }],
      },
    },
  },

  // ── 会话设置 ──────────────────────────────────────
  session: {
    historyLimit: 100,       // 最大消息历史数
    reset: {
      mode: "daily",
      atHour: 4,
      idleMinutes: 10080,    // 7天无活动后重置
    },
  },

  // ── 日志设置 ──────────────────────────────────────
  logging: {
    level: "info",           // trace | debug | info | warn | error
    consoleLevel: "info",
    file: "/tmp/openclaw/openclaw.log",  // 日志文件路径
  },

  // ── 超时设置 ──────────────────────────────────────
  reply: {
    timeoutSeconds: 1800,    // 默认 30 分钟
  },
}
```

### 关键配置字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `gateway.mode` | `"local"\|"remote"` | **必填**，否则 Gateway 拒绝启动 |
| `agents.defaults.workspace` | string | 工作区目录路径 |
| `channels.*.dmPolicy` | string | 私聊策略：pairing/allowlist/open/disabled |
| `channels.*.allowFrom` | array | 白名单用户列表 |
| `channels.*.groups` | object | 群组白名单+行为 |
| `models.providers` | object | 自定义 AI 提供商 |
| `session.historyLimit` | number | 对话历史保留数量 |
| `logging.level` | string | 日志详细程度 |

### 环境变量（替代配置文件）

```bash
TELEGRAM_BOT_TOKEN=...        # Telegram Bot Token（默认账号）
DISCORD_BOT_TOKEN=...         # Discord Bot Token（默认账号）
OPENCLAW_GATEWAY_TOKEN=...    # Gateway 认证 Token
OPENCLAW_CONFIG_PATH=...      # 自定义配置文件路径
OPENCLAW_STATE_DIR=...        # 自定义状态目录
OPENCLAW_SHOW_SECRETS=0       # 隐藏日志中的 token 预览
```

---

## 4. 渠道配置方法

### Telegram 配置

#### 步骤

1. 与 `@BotFather` 对话，创建机器人，获取 Token
2. 配置 `~/.openclaw/openclaw.json`：

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123456:ABC...",   // 从 BotFather 获取
      dmPolicy: "pairing",         // 推荐：配对模式
      groups: {
        "*": { requireMention: true },  // 群组需要 @bot 才回复
      },
    },
  },
}
```

3. 启动 Gateway：

```bash
openclaw gateway restart
```

4. 私信机器人，审批配对：

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

#### 群组配置（特定群）

```json5
{
  channels: {
    telegram: {
      botToken: "...",
      groups: {
        "-1001234567890": {          // 群组 ID（负数）
          requireMention: false,      // 无需 @
          allowFrom: ["@admin"],      // 限制用户
          systemPrompt: "简洁回答。",
        },
      },
    },
  },
}
```

#### 多账号 Telegram

```json5
{
  channels: {
    telegram: {
      accounts: [
        { accountId: "alerts", botToken: "123:abc", name: "Alert Bot" },
        { accountId: "support", botToken: "456:xyz", name: "Support Bot" },
      ],
    },
  },
}
```

---

### Discord 配置

#### 步骤

1. 在 [Discord Developer Portal](https://discord.com/developers) 创建应用
2. 创建 Bot，获取 Token
3. 开启以下权限：
   - `Message Content Intent`（必须！）
   - `Server Members Intent`
4. 配置：

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: "your-bot-token",      // 从 Developer Portal 获取
      dm: {
        enabled: true,
        policy: "pairing",           // 推荐：配对模式
      },
      guilds: {
        "123456789012345678": {      // 服务器 ID（推荐用 ID 不用名称）
          requireMention: false,      // 无需 @ 就回复
          channels: {
            "general": { allow: true },
            "openclaw-help": { allow: true, requireMention: false },
          },
        },
      },
    },
  },
}
```

5. 邀请机器人加入服务器（需要读写消息权限）
6. 重启 Gateway：

```bash
openclaw gateway restart
openclaw channels status --probe   # 验证连接
```

#### 常见 Discord 配置问题

- ❌ 机器人不回复群组：检查是否设置了 `guilds`（默认白名单模式）
- ❌ 开了 `requireMention: false` 还不回复：确保 guild 在白名单里
- ❌ 没有开 `Message Content Intent`：去 Developer Portal → Bot → 开启

#### 添加 Discord 渠道（CLI 方式）

```bash
openclaw channels add --channel discord --account work \
  --name "Work Bot" --token $DISCORD_BOT_TOKEN
```

---

### WhatsApp 配置

```json5
{
  channels: {
    whatsapp: {
      selfChatMode: true,           // 如果用个人号
      dmPolicy: "allowlist",
      allowFrom: ["+8613800000000"],
      sendReadReceipts: false,
      groups: {
        "Group Name@g.us": {
          requireMention: true,
          allowFrom: ["+8613800000000"],
        },
      },
    },
  },
}
```

```bash
openclaw channels login   # 扫码登录
```

---

## 5. 常见故障排查

### 快速诊断流程

```bash
# 按顺序执行
openclaw status                    # 1. 快速概览
openclaw gateway status            # 2. 服务状态
openclaw doctor                    # 3. 自动诊断
openclaw logs --follow             # 4. 实时日志
openclaw channels status --probe   # 5. 渠道健康
```

---

### 故障一：Gateway 启动失败

#### 症状：`Gateway won't start — configuration invalid`

```bash
openclaw doctor          # 查看具体错误
openclaw doctor --fix    # 自动修复
```

**常见原因：**
- 配置有未知字段 → 删除无效字段
- `gateway.mode` 未设置

```bash
openclaw config set gateway.mode local
```

#### 症状：`Gateway start blocked: set gateway.mode=local`

```bash
openclaw config set gateway.mode local
# 或者临时跳过（仅开发）：
openclaw gateway --allow-unconfigured
```

#### 症状：端口 18789 被占用

```bash
openclaw gateway status   # 查看监听状态
lsof -nP -iTCP:18789 -sTCP:LISTEN
```

#### 症状：服务已安装但没在运行

```bash
openclaw gateway status   # 查看监管程序状态
openclaw logs --follow    # 看具体报错

# 日志文件位置
tail -f /tmp/openclaw/openclaw-*.log

# macOS 服务日志
cat ~/.openclaw/logs/gateway.log
cat ~/.openclaw/logs/gateway.err.log

# Linux systemd 日志
journalctl --user -u openclaw-gateway.service -n 200 --no-pager
```

#### 症状：Gateway 卡在 "Starting…"

```bash
# macOS
openclaw gateway stop
lsof -nP -iTCP:18789 -sTCP:LISTEN
# 杀掉占用进程
kill -TERM <PID>

# 强制重装服务
openclaw gateway install --force
```

---

### 故障二：渠道不通（消息收不到）

#### 排查步骤

```bash
openclaw channels status --probe   # 渠道健康探测
openclaw status --deep             # 深度状态
openclaw logs --follow             # 实时日志
```

#### 常见原因

**1. 发送者不在白名单**

```bash
openclaw status   # 查看 AllowFrom 设置
```

检查配置里的 `allowFrom`，确认发送者 ID/号码在其中。

**2. 群组需要 @ 但没有设置**

```bash
# 检查 requireMention 设置
grep -n "requireMention\|groups" ~/.openclaw/openclaw.json
```

**3. Discord 没加 guild 白名单**

```json5
{
  channels: {
    discord: {
      guilds: {
        "YOUR_GUILD_ID": { requireMention: false }  // 必须显式添加
      }
    }
  }
}
```

**4. 配对码未批准（pairing 模式）**

```bash
openclaw pairing list telegram   # 查看待审批
openclaw pairing approve telegram <CODE>
```

---

### 故障三：消息不回（有收到但无响应）

#### 排查步骤

```bash
# 过滤关键词
tail -f /tmp/openclaw/openclaw-*.log | grep "blocked\|skip\|unauthorized\|error"
```

#### 常见原因

**1. 模型认证失败**

```bash
openclaw models status          # 查看认证状态
openclaw models auth setup-token --provider anthropic
```

**2. API Key 缺失**

```bash
# 症状：No API key found for provider "anthropic"
openclaw models auth setup-token --provider anthropic
# 或
openclaw models auth paste-token --provider anthropic
```

**3. OAuth token 过期（Anthropic）**

```bash
openclaw models auth setup-token --provider anthropic
openclaw models status
```

**4. 模型名称不对**

```bash
# 症状：Unknown model: anthropic/claude-haiku-3-5
openclaw models list     # 查看支持的模型
openclaw models set <正确的模型ID>
```

**5. 智能体超时**

```json5
{
  "reply": { "timeoutSeconds": 3600 }  // 改大超时时间
}
```

---

### 故障四：WhatsApp 断开/被踢出

```bash
# 检查状态
openclaw status --deep
openclaw logs --limit 200 | grep "connection\|disconnect\|logout"

# 重新登录
openclaw channels logout
openclaw channels login --verbose   # 重新扫码
```

---

### 重置大法（终极手段）

```bash
# ⚠️ 警告：会丢失所有会话，需要重新配对 WhatsApp
openclaw gateway stop
# 备份！
cp -r ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d)
# 重置
openclaw reset --scope full --yes
# 重新配置
openclaw onboard --install-daemon
```

---

### 日志位置速查

| 日志类型 | 位置 |
|---------|------|
| Gateway 运行日志 | `/tmp/openclaw/openclaw-YYYY-MM-DD.log` |
| macOS 服务 stdout | `~/.openclaw/logs/gateway.log` |
| macOS 服务 stderr | `~/.openclaw/logs/gateway.err.log` |
| Linux systemd | `journalctl --user -u openclaw-gateway.service` |
| Windows schtasks | `schtasks /Query /TN "OpenClaw Gateway" /V /FO LIST` |
| 会话文件 | `~/.openclaw/agents/<agentId>/sessions/` |
| 凭证 | `~/.openclaw/credentials/` |

---

## 6. Windows/Linux 特殊注意事项

### Windows

#### 要求
- 必须通过 **WSL2** 运行（不支持 Windows 原生）
- Node >=22 安装在 WSL2 内
- Windows 原生伴侣 App 正在开发中

#### 安装步骤

```powershell
# PowerShell（在 Windows 里执行安装器）
iwr -useb https://openclaw.ai/install.ps1 | iex

# 或在 WSL2 里：
curl -fsSL https://openclaw.ai/install.sh | bash
```

#### 服务管理（Windows 计划任务）

```powershell
# 查看服务状态
schtasks /Query /TN "OpenClaw Gateway" /V /FO LIST

# 手动启动
openclaw gateway start

# 查看日志
openclaw logs --follow
```

#### Windows 常见问题

- **PATH 问题**：WSL2 和 Windows 的 npm 路径是分开的，在 WSL2 里装的 openclaw 只能在 WSL2 里用
- **文件路径**：配置里用 Linux 风格路径（`/home/user/...`），不要用 Windows 路径（`C:\...`）
- **端口访问**：WSL2 的端口默认不对 Windows 开放，需要端口转发

---

### Linux

#### 系统服务（systemd）

```bash
# 安装服务
openclaw gateway install

# 服务管理
systemctl --user start openclaw-gateway
systemctl --user stop openclaw-gateway
systemctl --user restart openclaw-gateway
systemctl --user status openclaw-gateway

# 查看日志
journalctl --user -u openclaw-gateway.service -n 200 --no-pager
journalctl --user -u openclaw-gateway.service -f   # 实时跟踪
```

#### Linux 运行时要求

- Node >=22（**必须**，Bun 不支持 WhatsApp/Telegram）
- 不支持版本管理器（nvm/fnm/volta）管理的 Node 作为服务运行时（服务使用最小 PATH）
- 推荐系统安装 Node：`apt install nodejs` 或 `n` 全局安装

```bash
# 验证 Node 版本
node -v   # 必须 >= 22

# 如果服务找不到 node
openclaw doctor   # 会提示修复建议
openclaw gateway install --runtime node --force   # 强制重装服务
```

#### Linux 浏览器工具问题

**症状：** `Failed to start Chrome CDP on port 18800`

**原因：** Ubuntu 的 Snap Chromium 不兼容

**修复：**

```bash
# 安装 Google Chrome（非 Snap 版）
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# 配置浏览器路径
openclaw config set browser.executablePath /usr/bin/google-chrome-stable
```

#### Linux 环境变量

Gateway 服务使用**最小 PATH**，不加载用户 shell 初始化文件：
- 可用路径：`/usr/local/bin`、`/usr/bin`、`/bin`
- 不包含：nvm、fnm、volta、pnpm 等版本管理器

**在服务里用额外的环境变量：**

```bash
# 在 ~/.openclaw/.env 里设置（Gateway 会早期加载）
echo "DISPLAY=:0" >> ~/.openclaw/.env
echo "MY_API_KEY=xxx" >> ~/.openclaw/.env
```

---

### macOS 特殊注意

#### Homebrew libvips 冲突

```bash
# 如果 sharp 安装失败
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
```

#### macOS 服务（launchd）

```bash
# 停止服务（不要直接 kill，launchd 会重启）
openclaw gateway stop
# 或
launchctl bootout gui/$UID/bot.molt.gateway

# 查看服务状态
openclaw gateway status
```

#### 权限问题（语音/麦克风崩溃）

```bash
tccutil reset All bot.molt.mac.debug
```

---

## 附录：有用的配置示例

### 自定义提供商（兼容 OpenAI API 格式）

```json5
{
  models: {
    providers: {
      "lmstudio": {
        baseUrl: "http://localhost:1234/v1",
        models: [
          { id: "llama-3-8b" },
        ],
      },
    },
  },
  agents: {
    defaults: {
      model: { primary: "lmstudio/llama-3-8b" },
    },
  },
}
```

### 多智能体不同渠道路由

```json5
{
  agents: {
    list: [
      {
        id: "telegram-agent",
        workspace: "~/.openclaw/workspace-tg",
        bindings: [{ channel: "telegram", accountId: "default" }],
      },
      {
        id: "discord-agent",
        workspace: "~/.openclaw/workspace-dc",
        bindings: [{ channel: "discord", accountId: "default" }],
      },
    ],
  },
}
```

### Cron 定时任务

```bash
# 添加定时任务（每天早上 9 点）
openclaw cron add --name "morning-report" \
  --cron "0 9 * * *" \
  --message "发送今日日报"

# 查看定时任务
openclaw cron list
openclaw cron status

# 手动触发
openclaw cron run <id>
```

---

*文档整理自：https://docs.openclaw.ai*
*本地文件：docs/openclaw/*
