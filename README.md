# OpenClaw Skills

A collection of custom skills for [OpenClaw](https://openclaw.ai) — the open-source AI agent platform.

## Skills

### openclaw-ops

OpenClaw Gateway 运维技能 — 远程 SSH 排查部署问题、Gateway 启停与状态检查、配置修改、渠道连接、模型认证、心跳/Cron 调度、日志分析、故障诊断与修复。

**Contents:**
- `SKILL.md` — 完整运维指南（标准化巡检流程、故障速查、配置管理）
- `scripts/openclaw-checkup.sh` — 一键巡检脚本
- `references/` — 官方文档速查、实战案例库、渠道配置详情

**Install:**
```bash
openclaw skills install https://github.com/laolin5564/openclaw-skills/tree/main/openclaw-ops
```

## License

MIT
