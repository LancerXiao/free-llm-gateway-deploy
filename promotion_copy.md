# EnlyAI 推广文案合集

---

## 一、V2EX 推广帖

### 标题选项（选一个最合适的）
- [分享创造] 做了一个免费的大模型 API 聚合平台，一个 Key 调用所有模型
- [分享创造] EnlyAI：国内直连的免费 LLM API 平台，兼容 OpenAI 接口
- [分享创造] 不用再为 API Key 发愁了——免费大模型 API 平台 EnlyAI 上线

### 正文

大家好，最近做了一个大模型 API 聚合平台 **EnlyAI**，分享给有需要的朋友。

**是什么？**

EnlyAI 是一个 LLM API 聚合网关，提供统一的 OpenAI 兼容接口，一个 API Key 就能调用多种大模型。最大的特点是——**免费**。

**核心功能：**

- 免费使用，注册即送额度
- OpenAI API 兼容接口，现有项目零改动接入
- 国内直连，无需翻墙
- 支持流式输出（SSE）
- Chat Web 界面，开箱即用

**怎么用？**

1. 注册账号：https://www.enlyai.com
2. 获取 API Key
3. 替换你的 OpenAI base_url 为 `https://www.enlyai.com/v1`

Python 示例：
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-your-enlyai-key",
    base_url="https://www.enlyai.com/v1"
)

response = client.chat.completions.create(
    model="enlyai-chat",
    messages=[{"role": "user", "content": "你好"}],
    stream=True
)

for chunk in response:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

curl 示例：
```bash
curl https://www.enlyai.com/v1/chat/completions \
  -H "Authorization: Bearer sk-your-enlyai-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"enlyai-chat","messages":[{"role":"user","content":"Hello"}],"stream":true}'
```

也可以直接在网页上聊天使用，不需要写代码。

**适合谁？**

- 想用大模型 API 但不想付费的个人开发者
- 需要国内直连 LLM 服务的项目
- 学习 AI 开发的学生
- 想快速验证 AI 功能的产品经理

欢迎试用和反馈！

---

## 二、知乎回答 / 掘金文章

### 标题
国内免费大模型 API 怎么选？EnlyAI：一个 Key 搞定所有模型

### 正文

作为一个独立开发者，我经常需要调用大模型 API 来做各种小工具和实验。但市面上的选择要么太贵（OpenAI 官方），要么需要翻墙，要么接口不统一。

最近发现了一个免费的 LLM API 聚合平台 **EnlyAI**，用了一段时间感觉不错，分享一下。

### 为什么需要 LLM 聚合平台？

如果你做过 AI 相关的开发，一定遇到过这些问题：

1. **API 不统一**：每个模型厂商的接口格式都不一样，切换模型要改代码
2. **价格贵**：GPT-4 调用一次几毛钱，频繁测试成本很高
3. **网络问题**：国内访问 OpenAI 需要代理，增加部署复杂度
4. **Key 管理麻烦**：不同平台不同的 Key，管理混乱

### EnlyAI 怎么解决的？

**1. 统一接口**

EnlyAI 采用 OpenAI 兼容格式，你只需要改一下 `base_url`，现有代码就能直接用：

```python
# 只需要改这两行
client = OpenAI(
    api_key="sk-your-enlyai-key",
    base_url="https://www.enlyai.com/v1"  # 替换这里
)
# 其他代码完全不用动
```

**2. 免费**

注册就送额度，个人使用完全够用。对于学生和独立开发者来说，这是最大的吸引力。

**3. 国内直连**

服务器在国内，不需要翻墙，延迟低，稳定性好。

**4. Web 界面**

不想写代码？直接在网页上聊天就行。

### 接入指南

**Step 1：注册**

访问 https://www.enlyai.com 注册账号

**Step 2：获取 API Key**

在后台创建 Token，复制 API Key

**Step 3：接入**

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-your-enlyai-key",
    base_url="https://www.enlyai.com/v1"
)

# 就这么简单
response = client.chat.completions.create(
    model="enlyai-chat",
    messages=[{"role": "user", "content": "用 Python 写一个快速排序"}],
    stream=True
)

for chunk in response:
    content = chunk.choices[0].delta.content
    if content:
        print(content, end="")
```

### 和其他平台对比

| 特性 | EnlyAI | OpenRouter | 官方 API |
|------|--------|------------|---------|
| 免费额度 | 有 | 有限 | 无 |
| 国内直连 | 支持 | 需代理 | 需代理 |
| OpenAI 兼容 | 是 | 是 | 原生 |
| 注册门槛 | 低 | 中 | 高（需海外手机）|

### 总结

如果你是个人开发者或学生，需要一个免费、国内可用的 LLM API，EnlyAI 是一个不错的选择。当然，如果你有更高的需求（特定模型、大量调用），可能还是需要付费方案。

欢迎试用：https://www.enlyai.com

---

## 三、AI 工具导航站提交信息

### 网站名称
EnlyAI

### 网站地址
https://www.enlyai.com

### 一句话描述
免费的大模型 API 聚合平台，一个 Key 调用所有模型，国内直连，兼容 OpenAI 接口

### 详细描述
EnlyAI 是一个 LLM API 聚合网关，提供统一的 OpenAI 兼容接口。注册即送免费额度，支持国内直连，无需翻墙。提供 Chat Web 界面和 API 接口，适合开发者快速接入大模型能力。

### 分类
AI API / LLM 聚合 / 开发者工具

### 标签
免费, API, LLM, OpenAI兼容, 国内直连, 大模型, AI开发

### 图标/Logo
https://www.enlyai.com/logo.png

---

## 四、小红书文案

### 标题
免费AI聊天工具！不用翻墙不用花钱

### 正文
发现一个超好用的免费AI平台！

EnlyAI - 国内直连的大模型聊天平台

不用翻墙！不用付费！注册就能用！

功能超全：
- 网页直接聊天，像用ChatGPT一样
- 还提供API接口，程序员可以直接调用
- 支持流式输出，打字效果超流畅
- OpenAI接口兼容，代码改一行就能接入

注册地址：www.enlyai.com

适合：
- 想用AI但不想花钱的学生党
- 需要国内可用的AI工具
- 想尝试AI开发的程序员

快去试试吧！

#免费AI #AI工具 #大模型 #ChatGPT替代 #程序员 #AI开发

---

## 五、Product Hunt Launch

### Tagline
Free LLM API Gateway — One key, all models, zero cost

### Description
EnlyAI is a free LLM API aggregation platform that provides a unified OpenAI-compatible interface. One API key to access multiple large language models.

Key features:
- Free to use with generous quota on signup
- OpenAI API compatible — switch with just a base_url change
- Direct access from China, no VPN needed
- Streaming support (SSE)
- Web chat interface included
- Perfect for developers, students, and AI enthusiasts

Get started in 30 seconds:
1. Sign up at enlyai.com
2. Get your API key
3. Set base_url to https://www.enlyai.com/v1
4. Start building!

### Categories
Developer Tools, AI, API

### Tags
LLM, OpenAI, API Gateway, Free, AI
