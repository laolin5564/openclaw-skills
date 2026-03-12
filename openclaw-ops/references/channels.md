# 渠道配置参考

## Discord

```json5
{
  channels: {
    discord: {
      token: "BOT_TOKEN",        // Discord Bot Token
      allowFrom: ["user_id"],    // 允许的用户 ID
      groups: {
        allowList: ["guild_id:channel_id"],  // 允许的频道
        requireMention: true,    // 群聊需要 @
      }
    }
  }
}
```

Bot 必须开启 **Message Content Intent**（Discord Developer Portal → Bot → Privileged Gateway Intents）。

### 群聊无回复排查
- `requireMention: true` → 必须 @bot
- `mentionPatterns` → 自定义触发词
- `allowList` 未包含该频道
- Bot 缺少 Message Content Intent

## Telegram

```json5
{
  channels: {
    telegram: {
      token: "BOT_TOKEN",       // @BotFather 获取
      allowFrom: ["username"],   // 用户名或 user_id
    }
  }
}
```

### 排查
```bash
openclaw channels status --probe
openclaw pairing list --channel telegram
```

## WhatsApp（Web 渠道）

```json5
{
  channels: {
    whatsapp: {
      allowFrom: ["+15555550123"],
    }
  }
}
```

登录：`openclaw channels login`（扫 QR 码）

### 常见问题
- 掉线 409/515 → `openclaw channels logout && openclaw channels login`
- 确保手机在线且有网络
- creds 文件：`~/.openclaw/credentials/whatsapp/`

## Signal

需要先安装 signal-cli。配置：
```json5
{
  channels: {
    signal: {
      number: "+15555550123",
    }
  }
}
```

## iMessage（仅 macOS）

需要 imsg CLI。配置：
```json5
{
  channels: {
    imessage: {
      dmPolicy: "allowlist",
      allowFrom: ["+15555550123"],
    }
  }
}
```

## Slack

```json5
{
  channels: {
    slack: {
      botToken: "xoxb-...",
      appToken: "xapp-...",     // Socket Mode
    }
  }
}
```

## 通用排查命令

```bash
openclaw channels status --probe   # 所有渠道状态
openclaw channels logout           # 登出指定渠道
openclaw channels login --verbose  # 重新登录
openclaw pairing list --channel <name>  # 查看配对状态
openclaw config get channels       # 查看渠道配置
```

## 配对与权限

- `dmPolicy`: `open` | `allowlist` | `pairing`
- `allowFrom`: 白名单（用户名、ID、电话号码）
- `pairing` 模式：新用户需审批 → `openclaw pairing approve`
