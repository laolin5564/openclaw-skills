# 模型提供商 - OpenClaw

> Source: https://docs.openclaw.ai/zh-CN/providers

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

##### 概览

- 

模型提供商
- 

模型提供商快速入门

##### 模型概念

- 

模型 CLI

##### 配置

- 

模型提供商
- 

模型故障转移

##### 提供商

- 

Anthropic
- 

Amazon Bedrock
- 

Claude Max API 代理
- 

Deepgram
- 

GitHub Copilot
- 

GLM 模型
- 

Moonshot AI
- 

MiniMax
- 

OpenCode Zen
- 

Ollama
- 

OpenAI
- 

OpenRouter
- 

千帆（Qianfan）
- 

Qwen
- 

Synthetic
- 

Venice AI
- 

Vercel AI Gateway
- 

Xiaomi MiMo
- 

Z.AI

- 模型提供商
- 亮点：Venice（Venice AI）
- 快速开始
- 提供商文档
- 转录提供商
- 社区工具

概览

# 模型提供商

# 
​
模型提供商
OpenClaw 可以使用许多 LLM 提供商。选择一个提供商，进行认证，然后将默认模型设置为`provider/model`。正在寻找聊天渠道文档（WhatsApp/Telegram/Discord/Slack/Mattermost（插件）等）？参见渠道。
## 
​
亮点：Venice（Venice AI）
Venice 是我们推荐的 Venice AI 设置，用于隐私优先的推理，并可选择使用 Opus 处理困难任务。

- 默认：`venice/llama-3.3-70b`
- 最佳综合：`venice/claude-opus-45`（Opus 仍然是最强的）参见Venice AI。
## 
​
快速开始

- 与提供商进行认证（通常通过`openclaw onboard`）。
- 设置默认模型：

复制

```
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } },
}

```

## 
​
提供商文档

- Amazon Bedrock
- Anthropic（API + Claude Code CLI）
- GLM 模型
- MiniMax
- Moonshot AI（Kimi + Kimi Coding）
- Ollama（本地模型）
- OpenAI（API + Codex）
- OpenCode Zen
- OpenRouter
- Qwen（OAuth）
- Venice（Venice AI，注重隐私）
- Xiaomi
- Z.AI
## 
​
转录提供商

- Deepgram（音频转录）
## 
​
社区工具

- Claude Max API Proxy- 将 Claude Max/Pro 订阅作为 OpenAI 兼容的 API 端点使用有关完整的提供商目录（xAI、Groq、Mistral 等）和高级配置， 参见模型提供商。
模型提供商快速入门

⌘I