# 平台 - OpenClaw

> Source: https://docs.openclaw.ai/zh-CN/platforms

---

跳转到主要内容

OpenClawhome page

快速开始
安装
消息渠道
代理
工具
模型
平台
网关与运维
参考
帮助

##### 平台概览

- 

平台
- 

macOS 应用
- 

Linux 应用
- 

Windows (WSL2)
- 

Android 应用
- 

iOS 应用
- 

DigitalOcean
- 

Oracle Cloud
- 

Raspberry Pi

##### macOS 配套应用

- 

macOS 开发设置
- 

菜单栏
- 

语音唤醒
- 

语音浮层
- 

WebChat
- 

Canvas
- 

Gateway 网关生命周期
- 

健康检查
- 

菜单栏图标
- 

macOS 日志
- 

macOS 权限
- 

远程控制
- 

macOS 签名
- 

macOS 发布
- 

macOS 上的 Gateway 网关
- 

macOS IPC
- 

Skills
- 

Peekaboo Bridge

- 平台
- 选择你的操作系统
- VPS 和托管
- 常用链接
- Gateway 网关服务安装（CLI）

平台概览

# 平台

# 
​
平台
OpenClaw 核心使用 TypeScript 编写。**Node 是推荐的运行时**。 不推荐 Bun 用于 Gateway 网关（WhatsApp/Telegram 存在 bug）。配套应用适用于 macOS（菜单栏应用）和移动节点（iOS/Android）。Windows 和 Linux 配套应用已在计划中，但 Gateway 网关目前已完全支持。 Windows 原生配套应用也在计划中；推荐通过 WSL2 使用 Gateway 网关。
## 
​
选择你的操作系统

- macOS：macOS
- iOS：iOS
- Android：Android
- Windows：Windows
- Linux：Linux
## 
​
VPS 和托管

- VPS 中心：VPS 托管
- Fly.io：Fly.io
- Hetzner（Docker）：Hetzner
- GCP（Compute Engine）：GCP
- exe.dev（VM + HTTPS 代理）：exe.dev
## 
​
常用链接

- 安装指南：入门指南
- Gateway 网关运行手册：Gateway 网关
- Gateway 网关配置：配置
- 服务状态：`openclaw gateway status`
## 
​
Gateway 网关服务安装（CLI）
使用以下任一方式（均支持）：

- 向导（推荐）：`openclaw onboard --install-daemon`
- 直接安装：`openclaw gateway install`
- 配置流程：`openclaw configure`→ 选择**Gateway service**
- 修复/迁移：`openclaw doctor`（提供安装或修复服务）服务目标取决于操作系统：

- macOS：LaunchAgent（`bot.molt.gateway`或`bot.molt.<profile>`；旧版`com.openclaw.*`）
- Linux/WSL2：systemd 用户服务（`openclaw-gateway[-<profile>].service`）
macOS 应用

⌘I