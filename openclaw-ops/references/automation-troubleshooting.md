# 自动化故障排查

## Cron 不触发

1. 确认 Gateway 运行中：`openclaw gateway status`
2. 查看 cron 列表：`openclaw cron list`
3. 查看执行历史：`openclaw cron runs <jobId>`
4. 检查 cron 配置是否正确（schedule、payload、sessionTarget）
5. 手动触发测试：`openclaw cron run <jobId>`

### sessionTarget 规则
- `sessionTarget: "main"` → `payload.kind: "systemEvent"`
- `sessionTarget: "isolated"` → `payload.kind: "agentTurn"`

### delivery 配置
- `mode: "announce"` → 发送到聊天频道
- `mode: "none"` → 静默执行
- `mode: "webhook"` → POST 到 URL

## 心跳不触发

1. 检查配置：`openclaw config get agents.defaults.heartbeat`
2. `every: "0m"` = 禁用
3. `activeHours` 限制了时段？
4. Gateway 是否运行？
5. 日志搜 `heartbeat`：`openclaw logs --follow | grep -i heartbeat`

## 心跳发了但没收到

- `target: "none"`（默认）= 不投递到任何渠道
- 改为 `target: "last"` 投递到最近联系的渠道
- `directPolicy: "block"` 会阻止私聊投递

## Cron 执行了但结果没发出

- isolated 任务默认 delivery = announce
- 检查 delivery 配置
- 确认目标频道/用户 ID 正确
- 查日志：`openclaw logs --follow | grep cron`

## 常见错误

| 症状 | 原因 | 修复 |
|------|------|------|
| cron 完全不触发 | Gateway 未运行 | `openclaw gateway start` |
| 执行但无输出 | delivery mode = none | 改为 announce |
| "session not found" | sessionTarget 不匹配 | main→systemEvent, isolated→agentTurn |
| 时间不对 | 时区问题 | cron schedule 加 tz 字段 |
