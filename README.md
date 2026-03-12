# 🦞 OpenClaw Skills

> Custom skills for [OpenClaw](https://openclaw.ai) — the open-source AI agent platform.

Skills are modular instruction sets that give your OpenClaw agent specialized capabilities. Drop them into your workspace and the agent automatically picks them up when the task matches.

---

## 📦 Skills

### 🔧 openclaw-ops

**OpenClaw Gateway 运维技能** — 帮助 AI agent 远程排查和维护 OpenClaw 部署。

适用场景：
- 🏥 远程 SSH 诊断学员/用户的 OpenClaw 部署问题
- 🔄 Gateway 启停、状态检查、配置热重载
- 📡 渠道连接调试（Discord / Telegram / WeChat 等）
- 🔑 模型认证排查（API Key / OAuth / setup-token）
- ⏰ 心跳与 Cron 定时任务调度管理
- 📋 日志分析与故障诊断

**包含内容：**

```
openclaw-ops/
├── SKILL.md                          # 主技能文件（巡检流程 + 故障速查 + 配置管理）
├── scripts/
│   └── openclaw-checkup.sh           # 一键远程巡检脚本（版本/Cron/Session/渠道/工作区）
└── references/
    ├── official-docs-quickref.md      # 官方文档速查手册（安装/CLI/配置/渠道/故障排查）
    ├── gateway-troubleshooting-official.md  # Gateway 故障排查（官方）
    ├── install-official.md            # 安装指南（官方）
    ├── platforms-official.md          # 平台差异（macOS/Windows/Linux/Pi）
    ├── providers-official.md          # 模型 Provider 配置
    ├── channels.md                    # 渠道配置详情
    ├── automation-troubleshooting.md  # 心跳/Cron 自动化故障排查
    └── case-studies.md                # 实战案例库
```

**巡检脚本** (`openclaw-checkup.sh`) 一键检查：
- ✅ OpenClaw 版本 & 更新状态
- ✅ Cron 任务数量 & 调度频率合理性
- ✅ Session 文件大小 & token 占比
- ✅ Gateway 运行状态 & CPU 占用
- ✅ 渠道连接状态
- ✅ 工作区 .md 文件健康度

---

## 🚀 安装

### 方法 1：OpenClaw CLI（推荐）

```bash
openclaw skills install https://github.com/laolin5564/openclaw-skills/tree/main/openclaw-ops
```

### 方法 2：手动安装

```bash
# 克隆到本地
git clone https://github.com/laolin5564/openclaw-skills.git

# 复制到 OpenClaw skills 目录
cp -r openclaw-skills/openclaw-ops ~/.openclaw/skills/
```

安装后重启 Gateway 或等待下次心跳，agent 会自动识别新 skill。

---

## 🤝 Contributing

欢迎提交 PR 贡献新的 skills！每个 skill 应包含：

1. **`SKILL.md`** — 主技能文件（必须），包含 frontmatter 元数据和完整指令
2. **`scripts/`** — 可执行脚本（可选）
3. **`references/`** — 参考文档（可选）

Skill 编写规范参考 [OpenClaw Skills Spec](https://docs.openclaw.ai/skills)。

---

## 📄 License

[MIT](LICENSE)

---

*Built with 🐾 by [大黄](https://github.com/laolin5564) & 老林*
