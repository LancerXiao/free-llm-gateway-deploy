# 免费 LLM API 渠道完整分析报告

> **文档版本**: v1.0
> **更新日期**: 2026-06-23
> **适用范围**: EnlyAI 渠道拓展与免费 Key 池管理
> **说明**: 本文档系统梳理了 GitHub 及互联网上所有可用的免费 LLM API 渠道（除 Agnes 外），包括共享 Key 仓库、模型提供商免费额度、开源模型托管平台、国内平台等四大类共 40+ 个渠道。

---

## 目录

1. [渠道分类总览](#1-渠道分类总览)
2. [GitHub 免费 Key 共享仓库](#2-github-免费-key-共享仓库)
3. [模型提供商官方免费 API](#3-模型提供商官方免费-api)
4. [开源模型托管平台（Inference Providers）](#4-开源模型托管平台inference-providers)
5. [国内免费平台](#5-国内免费平台)
6. [渠道对比总表](#6-渠道对比总表)
7. [接入指南与代码示例](#7-接入指南与代码示例)
8. [与 EnlyAI 的竞争分析](#8-与-enlyai-的竞争分析)
9. [推荐接入策略](#9-推荐接入策略)
10. [风险与限制](#10-风险与限制)

---

## 1. 渠道分类总览

免费 LLM API 渠道按来源可分为四大类：

| 类别 | 数量 | 特点 | 稳定性 |
|------|------|------|--------|
| **GitHub 共享 Key 仓库** | 3+ | 社区维护，自动刷新，无需注册 | ⭐⭐ 不稳定，Key 随时失效 |
| **模型提供商官方免费 API** | 8+ | 厂商直供，需注册，有免费额度 | ⭐⭐⭐⭐ 稳定可靠 |
| **开源模型托管平台** | 15+ | 托管开源模型，免费推理 | ⭐⭐⭐ 较稳定 |
| **国内免费平台** | 10+ | 国内访问快，中文模型丰富 | ⭐⭐⭐⭐ 稳定 |

**当前 EnlyAI 已接入**: Agnes（已排除）、alistaitsacle 共享 Key、LLM7.io、OpenRouter 免费模型。

---

## 2. GitHub 免费 Key 共享仓库

这类仓库由社区维护，定期抓取并公开免费 API Key，**无需注册即可使用**，但 Key 随时可能失效，适合作为低成本补充渠道。

### 2.1 alistaitsacle/free-llm-api-keys ⭐核心渠道

| 属性 | 详情 |
|------|------|
| **仓库地址** | https://github.com/alistaitsacle/free-llm-api-keys |
| **提交频率** | 每日自动刷新（7366+ 次提交） |
| **Key 数量** | 约 44 个可用 Key |
| **模型数量** | 90+ 个模型 |
| **注册要求** | 无需注册、无需信用卡 |
| **Base URL** | `https://aiapiv2.pekpik.com` |
| **API 兼容** | OpenAI 格式 |

**可用模型示例**（2026年6月最新）:
- **OpenAI 系列**: `gpt-5.5`, `gpt-5.5-pro`, `gpt-5.4-mini`, `gpt-chat-latest`
- **Anthropic 系列**: `claude-opus-4-7`, `claude-sonnet-4-6`
- **Google 系列**: `gemini-2.5-flash`, `gemini-3.1-flash-lite`
- **DeepSeek 系列**: `deepseek-v4-pro`, `deepseek-v4-flash`
- **Qwen 系列**: `qwen/qwen3.6-max-preview`, `qwen/qwen3.6-flash`
- **其他**: `kimi-k2.5`, `x-ai/grok-4.3`, `mistralai/mistral-medium-3-5`

**接入方式**:
```bash
# 直接使用，无需 Key 也可（仓库提供）
curl https://aiapiv2.pekpik.com/v1/chat/completions \
  -H "Authorization: Bearer sk-xxxx" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-5.5","messages":[{"role":"user","content":"Hi"}]}'
```

**EnlyAI 当前接入状态**: ✅ 已接入，通过 `sync-free-keys.py` 每 30 分钟自动同步。

**优点**: 模型丰富、免费、无需注册
**缺点**: Key 不稳定（额度耗尽即失效）、速率限制严格、无 SLA 保障

---

### 2.2 其他类似共享 Key 仓库

| 仓库名称 | 地址 | 说明 |
|----------|------|------|
| **free-llm-api-resources** | https://github.com/free-llm/free-llm-api-resources | 整理免费 API 资源列表 |
| **awesome-free-llm-apis** | https://github.com/cheahjs/awesome-free-llm-apis | 精选免费 LLM API 列表，含验证脚本 |
| **freegpt** | https://github.com/ramonvc/freegpt | 逆向工程免费 GPT 接口 |

> **注意**: 这类仓库的 Key 来源不明，可能涉及违规使用，建议仅作参考，正式接入优先选择官方免费渠道。

---

## 3. 模型提供商官方免费 API

这类渠道由模型厂商直接提供，注册后可获得稳定的免费额度，**需要邮箱注册但无需信用卡**。

### 3.1 Google AI Studio (Gemini) ⭐推荐

| 属性 | 详情 |
|------|------|
| **官网** | https://aistudio.google.com/ |
| **API 文档** | https://ai.google.dev/gemini-api/docs |
| **Base URL** | `https://generativelanguage.googleapis.com/v1beta/openai` |
| **免费额度** | 免费层永久可用 |
| **注册要求** | Google 账号 |
| **信用卡** | 不需要 |

**免费层限制**（2026年6月）:
| 模型 | RPM | RPD | TPM |
|------|-----|-----|-----|
| Gemini 3.5 Pro | 5 | 25 | 250K |
| Gemini 3.5 Flash | 15 | 250 | 1M |
| Gemini 3.5 Flash-Lite | 30 | 1000 | 1M |
| Gemini 2.0 Flash | 15 | 1500 | 1M |

**特点**:
- 2M 超长上下文（Pro 版本）
- 支持多模态（图像、视频、音频）
- OpenAI 兼容格式
- 免费层数据可能用于训练（注意隐私）

**接入示例**:
```python
from openai import OpenAI
client = OpenAI(
    api_key="AIza...",
    base_url="https://generativelanguage.googleapis.com/v1beta/openai"
)
response = client.chat.completions.create(
    model="gemini-3.5-flash",
    messages=[{"role": "user", "content": "Hello"}]
)
```

---

### 3.2 Cohere

| 属性 | 详情 |
|------|------|
| **官网** | https://cohere.com/ |
| **Base URL** | `https://api.cohere.ai/v1` |
| **免费额度** | 1000 次/月（Trial Key） |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `command-r-plus`（聊天）
- `command-r`（聊天）
- `embed-english-v3.0`（嵌入）
- `embed-multilingual-v3.0`（多语言嵌入）

**特点**:
- 专为企业 RAG 场景优化
- 嵌入模型质量高
- 支持 Rerank API
- Trial Key 不能用于商业用途

---

### 3.3 Mistral AI

| 属性 | 详情 |
|------|------|
| **官网** | https://mistral.ai/ |
| **Base URL** | `https://api.mistral.ai/v1` |
| **免费额度** | La Plateforme 免费层 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `mistral-large-latest`
- `mistral-medium-3-5`
- `mistral-small-latest`
- `codestral-latest`（代码专用）
- `mistral-embed`

**特点**:
- 欧洲公司，GDPR 合规
- 代码模型 Codestral 表现优秀
- OpenAI 兼容格式
- 支持函数调用

---

### 3.4 智谱 AI (ZhipuAI / GLM)

| 属性 | 详情 |
|------|------|
| **官网** | https://open.bigmodel.cn/ |
| **Base URL** | `https://open.bigmodel.cn/api/paas/v4` |
| **免费额度** | 注册赠送 2000 万 Token |
| **注册要求** | 手机号注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `glm-4-plus`
- `glm-4-air`（轻量版）
- `glm-4-flash`（免费）
- `glm-4v`（多模态）
- `embedding-3`

**特点**:
- 国产模型，中文表现优秀
- GLM-4-Flash 完全免费
- 支持代码生成、函数调用
- 国内访问速度快

---

### 3.5 DeepSeek

| 属性 | 详情 |
|------|------|
| **官网** | https://platform.deepseek.com/ |
| **Base URL** | `https://api.deepseek.com/v1` |
| **免费额度** | 注册赠送 500 万 Token |
| **注册要求** | 手机号注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `deepseek-v4-pro`（1.6T 参数）
- `deepseek-v4-flash`
- `deepseek-coder`

**特点**:
- 价格极低（即使付费也很便宜）
- 代码能力突出
- OpenAI 兼容格式
- 国内访问速度快

---

### 3.6 xAI (Grok)

| 属性 | 详情 |
|------|------|
| **官网** | https://x.ai/ |
| **Base URL** | `https://api.x.ai/v1` |
| **免费额度** | 每月 $25 免费额度（限时） |
| **注册要求** | X（Twitter）账号 |
| **信用卡** | 不需要（免费层） |

**可用模型**:
- `grok-4.3`
- `grok-4.3-mini`

**特点**:
- 实时信息访问（接入 X 平台数据）
- 上下文窗口大
- OpenAI 兼容格式

---

### 3.7 Together AI

| 属性 | 详情 |
|------|------|
| **官网** | https://www.together.ai/ |
| **Base URL** | `https://api.together.xyz/v1` |
| **免费额度** | 注册赠送 $5 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**: 200+ 开源模型（Llama、Qwen、Mistral 等）

---

### 3.8 AI/ML API

| 属性 | 详情 |
|------|------|
| **官网** | https://aimlapi.com/ |
| **Base URL** | `https://api.aimlapi.com/v1` |
| **免费额度** | 注册赠送 1000 次调用 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

---

## 4. 开源模型托管平台（Inference Providers）

这类平台托管开源模型（Llama、Qwen、Mistral 等），提供免费推理服务。

### 4.1 GitHub Models ⭐推荐

| 属性 | 详情 |
|------|------|
| **官网** | https://github.com/marketplace/models |
| **Base URL** | `https://models.inference.ai.azure.com` |
| **免费额度** | 每天免费调用（低速率） |
| **注册要求** | GitHub 账号 + Personal Access Token |
| **信用卡** | 不需要 |

**可用模型**:
- `gpt-4o`, `gpt-4o-mini`
- `Phi-4`
- `Meta-Llama-3.3-70B-Instruct`
- `Mistral-large`
- `AI21-Jamba`

**速率限制**:
| 层级 | RPM | TPM | RPD |
|------|-----|-----|-----|
| Free | 15 | 8K | 150 |

**特点**:
- 使用 GitHub Token 即可访问
- OpenAI 兼容格式
- 适合开发测试
- 模型更新及时

**接入示例**:
```bash
curl https://models.inference.ai.azure.com/chat/completions \
  -H "Authorization: Bearer ghp_xxx" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hi"}]}'
```

---

### 4.2 Groq ⭐推荐（超快推理）

| 属性 | 详情 |
|------|------|
| **官网** | https://groq.com/ |
| **Base URL** | `https://api.groq.com/openai/v1` |
| **免费额度** | 免费层永久可用 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `llama-3.3-70b-versatile`
- `llama-3.1-8b-instant`
- `mixtral-8x7b-32768`
- `gemma2-9b-it`

**速率限制**:
| 模型 | RPM | RPD | TPM |
|------|-----|-----|-----|
| Llama 70B | 30 | 14400 | 6000 |
| Llama 8B | 30 | 14400 | 30000 |

**特点**:
- **推理速度极快**（500+ tokens/s）
- 使用 LPU 硬件加速
- OpenAI 兼容格式
- 适合实时对话场景

---

### 4.3 Cerebras ⭐推荐（超快推理）

| 属性 | 详情 |
|------|------|
| **官网** | https://cerebras.ai/ |
| **Base URL** | `https://api.cerebras.ai/v1` |
| **免费额度** | 免费层可用 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `llama3.1-8b`
- `llama3.1-70b`

**特点**:
- 使用 Wafer-Scale Engine 芯片
- 推理速度比 GPU 快 10-100 倍
- 适合低延迟场景

---

### 4.4 NVIDIA NIM

| 属性 | 详情 |
|------|------|
| **官网** | https://build.nvidia.com/ |
| **Base URL** | `https://integrate.api.nvidia.com/v1` |
| **免费额度** | 注册赠送 1000 次调用 |
| **注册要求** | NVIDIA 账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `meta/llama-3.3-70b-instruct`
- `meta/llama-3.1-405b-instruct`
- `nvidia/nemotron-3-ultra-550b`
- `qwen/qwen2.5-72b-instruct`
- `mistralai/mistral-large`

**特点**:
- 模型种类丰富
- 支持 RAG、Agent 场景
- OpenAI 兼容格式

---

### 4.5 OpenRouter ⭐推荐（聚合平台）

| 属性 | 详情 |
|------|------|
| **官网** | https://openrouter.ai/ |
| **Base URL** | `https://openrouter.ai/api/v1` |
| **免费额度** | 大量 `:free` 后缀模型 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**免费模型示例**（2026年6月）:
- `openai/gpt-oss-120b:free`
- `google/gemma-4-31b-it:free`
- `qwen/qwen3-coder:free`
- `moonshotai/kimi-k2.6:free`
- `nvidia/nemotron-3-ultra-550b-a55b:free`
- `meta-llama/llama-3.3-70b-instruct:free`
- `inclusionai/ling-2.6-1t:free`

**特点**:
- 聚合 200+ 模型提供商
- 统一 API 接口
- 免费模型数量最多
- 支持自动故障转移

**接入示例**:
```python
from openai import OpenAI
client = OpenAI(
    api_key="sk-or-...",
    base_url="https://openrouter.ai/api/v1"
)
response = client.chat.completions.create(
    model="openai/gpt-oss-120b:free",
    messages=[{"role": "user", "content": "Hi"}]
)
```

---

### 4.6 Cloudflare Workers AI

| 属性 | 详情 |
|------|------|
| **官网** | https://developers.cloudflare.com/workers-ai/ |
| **Base URL** | `https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/v1` |
| **免费额度** | 每天 10000 次神经元调用 |
| **注册要求** | Cloudflare 账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `@cf/meta/llama-3.3-70b-instruct`
- `@cf/mistral/mistral-7b-instruct`
- `@cf/qwen/qwen1.5-14b-chat`
- `@cf/baai/bge-large-en-v1.5`（嵌入）

**特点**:
- 边缘推理，全球低延迟
- 与 Cloudflare 生态集成
- 适合 Serverless 场景

---

### 4.7 Hugging Face Inference API

| 属性 | 详情 |
|------|------|
| **官网** | https://huggingface.co/inference-api |
| **Base URL** | `https://api-inference.huggingface.co/models` |
| **免费额度** | 免费层有限调用 |
| **注册要求** | Hugging Face 账号 |
| **信用卡** | 不需要 |

**可用模型**: 10万+ 开源模型

**特点**:
- 模型数量最多
- 支持自定义模型部署
- 适合研究实验

---

### 4.8 SambaNova

| 属性 | 详情 |
|------|------|
| **官网** | https://sambanova.ai/ |
| **Base URL** | `https://api.sambanova.ai/v1` |
| **免费额度** | 免费层可用 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `Meta-Llama-3.3-70B-Instruct`
- `Meta-Llama-3.1-405B-Instruct`

**特点**: 使用 RDU 芯片，推理速度快

---

### 4.9 LLM7.io ⭐推荐（无需 Key）

| 属性 | 详情 |
|------|------|
| **官网** | https://llm7.io/ |
| **Base URL** | `https://api.llm7.io` |
| **免费额度** | 完全免费 |
| **注册要求** | **无需注册** |
| **信用卡** | 不需要 |

**可用模型**:
- `qwen3-235b-a22b:free`
- `mistral-small-3.2:free`
- `codestral-latest`

**特点**:
- **完全无需 Key**
- OpenAI 兼容格式
- 适合快速测试

**接入示例**:
```bash
curl https://api.llm7.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3-235b-a22b:free","messages":[{"role":"user","content":"Hi"}]}'
```

---

### 4.10 Kluster AI

| 属性 | 详情 |
|------|------|
| **官网** | https://kluster.ai/ |
| **Base URL** | `https://api.kluster.ai/v1` |
| **免费额度** | 注册赠送免费额度 |
| **注册要求** | 邮箱注册 |
| **信用卡** | 不需要 |

**可用模型**: Llama、Qwen 等开源模型

---

### 4.11 其他托管平台

| 平台 | Base URL | 免费额度 | 特点 |
|------|----------|----------|------|
| **Chutes.ai** | `https://api.chutes.ai/v1` | 免费层 | 无需注册 |
| **glhf.chat** | `https://glhf.chat/api/v1` | 免费层 | 开源模型 |
| **Nebius AI** | `https://api.nebius.ai/v1` | $50 试用额度 | 云厂商 |
| **OVHcloud AI** | `https://gra.ai.cloud.ovh.net/v1` | 免费试用 | 欧洲云 |
| **IBM Watsonx.ai** | `https://us-south.ml.cloud.ibm.com` | 免费层 | 企业级 |
| **Scaleway** | `https://api.scaleway.ai/v1` | 免费试用 | 欧洲云 |
| **Nscale** | `https://api.nscale.ai/v1` | 免费层 | 欧洲 GPU |

---

## 5. 国内免费平台

国内平台访问速度快，中文模型丰富，适合国内用户使用。

### 5.1 硅基流动 SiliconFlow ⭐推荐

| 属性 | 详情 |
|------|------|
| **官网** | https://siliconflow.cn/ |
| **Base URL** | `https://api.siliconflow.cn/v1` |
| **免费额度** | 注册赠送 14 元 |
| **注册要求** | 手机号注册 |
| **信用卡** | 不需要 |

**免费模型**:
- `Qwen/Qwen2.5-7B-Instruct`（免费）
- `THUDM/glm-4-9b-chat`（免费）
- `meta-llama/Meta-Llama-3.1-8B-Instruct`（免费）
- `BAAI/bge-m3`（嵌入，免费）

**特点**:
- 国内访问速度快
- 免费模型多
- OpenAI 兼容格式
- 支持文生图、语音

---

### 5.2 魔搭 ModelScope

| 属性 | 详情 |
|------|------|
| **官网** | https://modelscope.cn/ |
| **Base URL** | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 阿里云账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `qwen-max`
- `qwen-plus`
- `qwen-turbo`
- `qwen-vl-max`（多模态）

**特点**:
- 阿里达摩院出品
- Qwen 系列模型首发
- 中文表现优秀

---

### 5.3 腾讯混元

| 属性 | 详情 |
|------|------|
| **官网** | https://cloud.tencent.com/product/hunyuan |
| **Base URL** | `https://api.hunyuan.cloud.tencent.com/v1` |
| **免费额度** | 注册赠送 100 万 Token |
| **注册要求** | 腾讯云账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `hunyuan-pro`
- `hunyuan-standard`
- `hunyuan-lite`（免费）

---

### 5.4 火山引擎（豆包）

| 属性 | 详情 |
|------|------|
| **官网** | https://www.volcengine.com/product/doubao |
| **Base URL** | `https://ark.cn-beijing.volces.com/api/v3` |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 火山引擎账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `doubao-pro-4k`
- `doubao-pro-32k`
- `doubao-lite-4k`（免费）

---

### 5.5 心流 iFlow

| 属性 | 详情 |
|------|------|
| **官网** | https://iflow.cn/ |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 手机号注册 |

---

### 5.6 快手 StreamLake

| 属性 | 详情 |
|------|------|
| **官网** | https://streamlake.com/ |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 手机号注册 |

---

### 5.7 讯飞星火

| 属性 | 详情 |
|------|------|
| **官网** | https://xinghuo.xfyun.cn/ |
| **Base URL** | `https://spark-api-open.xf-yun.com/v1` |
| **免费额度** | 注册赠送 200 万 Token |
| **注册要求** | 手机号注册 |
| **信用卡** | 不需要 |

**可用模型**:
- `spark-pro`
- `spark-max`
- `spark-lite`（免费）

---

### 5.8 百度千帆（文心一言）

| 属性 | 详情 |
|------|------|
| **官网** | https://qianfan.baidubce.com/ |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 百度账号 |
| **信用卡** | 不需要 |

**可用模型**:
- `ernie-4.0`
- `ernie-3.5`
- `ernie-speed`（免费）

---

### 5.9 零一万物

| 属性 | 详情 |
|------|------|
| **官网** | https://platform.lingyiwanwu.com/ |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 手机号注册 |

**可用模型**: `yi-large`, `yi-medium`

---

### 5.10 MiniMax

| 属性 | 详情 |
|------|------|
| **官网** | https://api.minimax.chat/ |
| **免费额度** | 注册赠送额度 |
| **注册要求** | 手机号注册 |

**可用模型**: `abab6.5`, `abab5.5`

---

## 6. 渠道对比总表

### 6.1 海外渠道对比

| 渠道 | 免费额度 | 速率限制 | OpenAI 兼容 | 多模态 | 稳定性 | 推荐度 |
|------|----------|----------|-------------|--------|--------|--------|
| Google Gemini | 永久免费 | 5-30 RPM | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Groq | 永久免费 | 30 RPM | ✅ | ❌ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Cerebras | 永久免费 | 30 RPM | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| GitHub Models | 每日免费 | 15 RPM | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| OpenRouter | 大量免费模型 | 不一 | ✅ | 部分 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| NVIDIA NIM | 1000 次 | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Cloudflare | 10K/天 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Hugging Face | 有限 | 低 | 部分 | 部分 | ⭐⭐⭐ | ⭐⭐⭐ |
| LLM7.io | 完全免费 | 中 | ✅ | ❌ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Cohere | 1000/月 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Mistral | 免费层 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| xAI Grok | $25/月 | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| SambaNova | 免费层 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Together AI | $5 试用 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

### 6.2 国内渠道对比

| 渠道 | 免费额度 | 速率限制 | OpenAI 兼容 | 多模态 | 稳定性 | 推荐度 |
|------|----------|----------|-------------|--------|--------|--------|
| SiliconFlow | 14 元 | 中 | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 智谱 GLM | 2000 万 Token | 中 | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| DeepSeek | 500 万 Token | 中 | ✅ | ❌ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| ModelScope | 赠送额度 | 中 | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 腾讯混元 | 100 万 Token | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 火山豆包 | 赠送额度 | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 讯飞星火 | 200 万 Token | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 百度文心 | 赠送额度 | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 零一万物 | 赠送额度 | 中 | ✅ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| MiniMax | 赠送额度 | 中 | ✅ | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 7. 接入指南与代码示例

### 7.1 通用接入方式（OpenAI 兼容）

大多数渠道都兼容 OpenAI API 格式，只需修改 `base_url` 和 `api_key` 即可：

```python
from openai import OpenAI

# 通用配置模板
client = OpenAI(
    api_key="your-api-key",
    base_url="provider-base-url"
)

response = client.chat.completions.create(
    model="model-name",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=100
)
print(response.choices[0].message.content)
```

### 7.2 New API 渠道配置

在 New API 系统中添加渠道的 SQL 模板：

```sql
INSERT INTO channels (
    name, type, key, base_url, models, model_mapping,
    "group", status, priority, weight, auto_ban, created_time
) VALUES (
    '渠道名称',           -- 如 'Google-Gemini'
    1,                    -- OpenAI 类型
    'your-api-key',       -- API Key
    'base-url',           -- 如 'https://generativelanguage.googleapis.com/v1beta'
    'enlyai-chat',        -- 统一模型名
    '{"enlyai-chat": "gemini-3.5-flash"}',  -- 模型映射
    'default', 1, 10, 10, 0, EXTRACT(EPOCH FROM NOW())::int
);
```

### 7.3 多渠道负载均衡配置示例

```python
# 渠道优先级配置建议
CHANNEL_PRIORITY = {
    # Tier 1: 永久免费顶级模型（优先级最高）
    "google-gemini-flash": 15,
    "groq-llama-70b": 14,
    "github-models-gpt4o": 13,

    # Tier 2: 国内稳定免费渠道
    "siliconflow-qwen": 12,
    "zhipu-glm4-flash": 11,
    "deepseek-v4-flash": 10,

    # Tier 3: OpenRouter 免费模型
    "openrouter-free-models": 8,

    # Tier 4: 共享 Key 仓库（不稳定，作为后备）
    "alistaitsacle-shared": 5,

    # Tier 5: 其他托管平台
    "llm7-io": 3,
    "cloudflare-ai": 2,
}
```

---

## 8. 与 EnlyAI 的竞争分析

### 8.1 EnlyAI 当前渠道结构

| 渠道类型 | 优先级 | 说明 |
|----------|--------|------|
| Agnes AI | P20 | 已排除 |
| alistaitsacle 共享 Key | P3-P10 | 不稳定 |
| LLM7.io | P13-P15 | 无需 Key |
| OpenRouter 免费模型 | P6-P11 | 较稳定 |

### 8.2 竞争优势分析

**EnlyAI 优势**:
- ✅ 统一 API 接口（`enlyai-chat`）
- ✅ 自动故障转移
- ✅ 智能路由（基于健康数据）
- ✅ 免费 Key 池自动同步

**EnlyAI 劣势**:
- ❌ 过度依赖 alistaitsacle 共享 Key（不稳定）
- ❌ 缺少官方免费渠道（Google、Groq 等）
- ❌ 国内渠道接入不足
- ❌ 缺少多模态支持

### 8.3 改进建议

| 改进项 | 优先级 | 预期效果 |
|--------|--------|----------|
| 接入 Google Gemini 免费层 | 高 | 稳定 5-30 RPM |
| 接入 Groq 免费层 | 高 | 超快推理速度 |
| 接入 GitHub Models | 高 | 稳定 GPT-4o-mini |
| 接入 SiliconFlow | 高 | 国内访问快 |
| 接入智谱 GLM-4-Flash | 高 | 完全免费 |
| 接入 DeepSeek | 中 | 代码能力强 |
| 扩展 OpenRouter 免费模型 | 中 | 增加模型多样性 |

---

## 9. 推荐接入策略

### 9.1 第一优先级：官方免费渠道（稳定可靠）

```
Google Gemini 3.5 Flash  →  P15（5 RPM，稳定）
Groq Llama 3.3 70B       →  P14（30 RPM，超快）
GitHub Models GPT-4o-mini →  P13（15 RPM，稳定）
智谱 GLM-4-Flash          →  P12（完全免费，国内快）
SiliconFlow Qwen          →  P11（免费，国内快）
```

### 9.2 第二优先级：聚合平台

```
OpenRouter 免费模型       →  P8-P10（多模型备选）
LLM7.io                  →  P7（无需 Key）
NVIDIA NIM               →  P6（1000 次免费）
```

### 9.3 第三优先级：共享 Key（不稳定后备）

```
alistaitsacle 共享 Key    →  P3-P5（自动同步）
其他共享 Key 仓库          →  P1-P2（应急）
```

### 9.4 接入清单

| 序号 | 渠道 | Base URL | 模型 | 优先级 | 状态 |
|------|------|----------|------|--------|------|
| 1 | Google Gemini | `generativelanguage.googleapis.com/v1beta` | gemini-3.5-flash | 15 | 待接入 |
| 2 | Groq | `api.groq.com/openai/v1` | llama-3.3-70b-versatile | 14 | 待接入 |
| 3 | GitHub Models | `models.inference.ai.azure.com` | gpt-4o-mini | 13 | 待接入 |
| 4 | 智谱 GLM | `open.bigmodel.cn/api/paas/v4` | glm-4-flash | 12 | 待接入 |
| 5 | SiliconFlow | `api.siliconflow.cn/v1` | Qwen2.5-7B-Instruct | 11 | 待接入 |
| 6 | DeepSeek | `api.deepseek.com/v1` | deepseek-chat | 10 | 待接入 |
| 7 | OpenRouter | `openrouter.ai/api/v1` | 多个免费模型 | 8 | ✅ 已接入 |
| 8 | LLM7.io | `api.llm7.io` | qwen3-235b:free | 7 | ✅ 已接入 |
| 9 | NVIDIA NIM | `integrate.api.nvidia.com/v1` | llama-3.3-70b | 6 | 待接入 |
| 10 | Cloudflare AI | `api.cloudflare.com/client/v4` | llama-3.3-70b | 5 | 待接入 |
| 11 | Cohere | `api.cohere.ai/v1` | command-r | 4 | 待接入 |
| 12 | Mistral | `api.mistral.ai/v1` | mistral-small | 4 | 待接入 |
| 13 | alistaitsacle | `aiapiv2.pekpik.com` | 多模型 | 3 | ✅ 已接入 |

---

## 10. 风险与限制

### 10.1 使用风险

| 风险类型 | 说明 | 应对措施 |
|----------|------|----------|
| **Key 失效** | 共享 Key 随时可能失效 | 多渠道备份 + 自动检测 |
| **速率限制** | 免费层速率限制严格 | 轮询多渠道 |
| **数据隐私** | 免费层数据可能用于训练 | 不传输敏感数据 |
| **服务中断** | 免费服务无 SLA 保障 | 故障转移机制 |
| **合规风险** | 共享 Key 来源不明 | 优先使用官方渠道 |

### 10.2 合规建议

1. **优先使用官方免费渠道**（Google、Groq、GitHub Models 等）
2. **共享 Key 仅作后备**，不作为主要渠道
3. **不存储用户对话内容**到免费渠道
4. **遵守各平台 ToS**，不超量使用
5. **定期审查渠道**，移除不可用渠道

### 10.3 监控建议

```bash
# 建议监控指标
- 渠道可用率（目标 > 95%）
- 平均响应时间（目标 < 3s）
- 错误率分布（按错误类型）
- 每日调用量（避免超限）
- Key 失效告警（全渠道不可用时告警）
```

---

## 附录：快速接入命令

### A.1 测试渠道可用性

```bash
# 通用测试脚本
test_channel() {
    local name=$1 base_url=$2 key=$3 model=$4
    echo -n "测试 $name: "
    result=$(curl -s --max-time 15 "$base_url/v1/chat/completions" \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"max_tokens\":10}")
    if echo "$result" | grep -q '"choices"'; then
        echo "✅ 可用"
    else
        echo "❌ 不可用: $(echo $result | head -c 100)"
    fi
}

# 测试各渠道
test_channel "Google" "https://generativelanguage.googleapis.com/v1beta" "AIza..." "gemini-3.5-flash"
test_channel "Groq" "https://api.groq.com/openai/v1" "gsk_..." "llama-3.3-70b-versatile"
test_channel "GitHub" "https://models.inference.ai.azure.com" "ghp_..." "gpt-4o-mini"
```

### A.2 批量接入 New API

```bash
# 批量添加渠道脚本
add_channel() {
    local name=$1 key=$2 base_url=$3 model=$4 priority=$5
    docker exec postgres psql -U newapi -d newapi -c "
    INSERT INTO channels (name, type, key, base_url, models, model_mapping, priority, status, auto_ban, created_time)
    VALUES ('$name', 1, '$key', '$base_url', 'enlyai-chat',
            '{\"enlyai-chat\": \"$model\"}', $priority, 1, 0, EXTRACT(EPOCH FROM NOW())::int);"
}
```

---

**文档结束**

> 本文档将持续更新，跟进各渠道的最新免费政策和模型更新。如需接入新渠道，请参考第 7 节的接入指南，或联系维护人员。
