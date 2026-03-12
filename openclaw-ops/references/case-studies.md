# 实战案例库

## 案例1：Session 膨胀导致 CPU 爆炸（苏总🦞）

### 症状
- Gateway 每次重启后 CPU 飙到 130%+
- Discord 回复一条消息后又挂
- Cron 执行失败日志

### 排查过程
1. `openclaw gateway restart` → 短暂恢复后又挂
2. 检查 API 中转站连通性 → 正常（排除网络问题）
3. 检查 Gateway CPU → 异常高
4. **关键发现**：`sessions.json` 膨胀到 **140MB**，cron 历史 session **2599个**
5. 清理 session 后 Discord 恢复

### 根因
- 一个 cron 任务 **每10秒触发一次**，每次在内存留下 session 对象
- 另一个巡检 cron 每5分钟一次
- session 疯狂堆积 → sessions.json 膨胀 → Gateway 启动时加载巨大 JSON → CPU 爆炸

### 后续发现（🦞自检）
- 清理后仍有 **4099个** session
- 各子 agent sessions 在 **19万行** 级别
- 主会话上下文满 **400k**

### 修复步骤
1. 暂停所有异常 cron 任务
2. 清理历史 session（旧的 cron session、过期 session）
3. 优化 cron 频率（最低不低于5分钟）
4. 配置 session 自动归档和清理机制
5. 检查工作区 .md 文件，去除冗余重复内容

### 经验教训

| 教训 | 规则 |
|------|------|
| Cron 间隔不能太短 | 最低5分钟，isolated cron 每次创建新 session |
| sessions.json 必须监控 | ≥50MB 告警，≥100MB 是定时炸弹 |
| CPU 异常先查 session | 不要在 API/网络上浪费时间 |
| 清理后要自检 | 第一次清理可能不够，让🦞自检更准确 |
| 工作区文件要精简 | 重复内容浪费 token，影响每次请求 |
| Cron 必须 review | 新学员的 cron 是高危区，频率+数量都要检查 |

### 排查优先级（CPU 爆炸时）
1. ❶ `sessions.json` 大小 → `ls -lh ~/.openclaw/agents/*/sessions/sessions.json`
2. ❷ Cron 任务频率 → `openclaw cron list --json`
3. ❸ 活跃 session 数量 → `openclaw status`
4. ❹ 然后才看网络/API/模型问题

---

## 通用排查心法

1. **万金油命令**：`openclaw gateway restart` — 先试，能恢复就继续排查根因
2. **让🦞自检**：OpenClaw 对自身有模型预设，自检比外部 Claude CLI 更准确
3. **先看大小再看内容**：文件大小异常是最快的信号
4. **Cron 是高危区**：每个学员的 cron 都要 review 频率和 sessionTarget

---

## 案例2：Windows 学员 frpc 连接失败 + Discord 无回复

### 症状
- Windows 机器运行 `setup.ps1` 报错 `json: cannot unmarshal string`
- 连上后 Discord 发消息不回复

### 排查过程
1. frpc 启动失败，报 JSON 解析错误
2. 检查 `frpc.toml` 内容 → 发现两个 bug

### 根因

**Bug 1：TOML 格式错误**
```toml
# 错误写法（frp v0.52+ 不支持点号路径）
auth.method = "token"
auth.token = "xxx"

# 正确写法
[auth]
method = "token"
token = "xxx"
```

**Bug 2：PowerShell BOM 污染**
- `Set-Content -Encoding UTF8` 在 PS 5.x 会在文件头加 BOM（\xEF\xBB\xBF）
- frpc TOML 解析器遇到 BOM 报 JSON 错误
- 修复：用 `[System.IO.File]::WriteAllText(..., [System.Text.UTF8Encoding]::new($false))`

**Bug 3：Discord groupPolicy 无白名单**
```json
// 问题配置：allowlist 但没有 allowFrom，所有消息被拒
{ "groupPolicy": "allowlist" }

// 修复
{ "groupPolicy": "open" }
// 或
{ "groupPolicy": "allowlist", "allowFrom": ["user_id"] }
```

### 修复步骤
1. 修复 `setup.ps1` 的 TOML 格式和 BOM 问题
2. 重新跑脚本让 frpc 正常连接
3. `openclaw config set channels.discord.groupPolicy open`
4. `openclaw gateway stop && openclaw gateway start`

### 经验教训

| 问题 | 原因 | 修复 |
|------|------|------|
| frpc TOML 解析失败 | 旧版点号语法/BOM污染 | 用 `[auth]` 节 + 无BOM写法 |
| Discord 不回消息 | allowlist 无 allowFrom | 改 open 或补充 allowFrom |
| `Start-Process` 进程崩溃 | 同时重定向 stdout+stderr | 用 `System.Diagnostics.Process` |
| Windows Discord WebSocket 1006 | 配置错误导致频繁断连 | 修配置后重启 Gateway |

---

## 案例3：ClashMac 报 "CPU类型不正确"（M4 Mac mini）

### 症状
- M4 Mac mini 上 ClashMac 启动报 "CPU类型不正确"

### 根因
ClashMac 自动从 GitHub 下载的 `mihomo` 内核是 x86_64，但机器是 arm64

### 修复
```bash
# 替换 mihomo 内核为 arm64 版本
curl -fsSL "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.20/mihomo-darwin-arm64-v1.19.20.gz" | gunzip > ~/Library/Application\ Support/ClashMac/core/mihomo
chmod +x ~/Library/Application\ Support/ClashMac/core/mihomo
pkill -f ClashMac && open /Applications/ClashMac.app
```
