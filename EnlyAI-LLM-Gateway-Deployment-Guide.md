# EnlyAI LLM 网关部署与优化文档

> 最后更新: 2026-06-14

---

## 1. 系统架构概览

```
用户请求 (api.enlyai.com)
    ↓ HTTPS (Let's Encrypt SSL)
    ↓ Nginx 反向代理 (443 → 3000)
    ↓
New API 网关 (calciumion/new-api, port 3000)
    ├── PostgreSQL 15 (渠道/用户/Token 数据)
    └── Redis 8.8 (缓存/会话)
    ↓
路由选择 (priority + weight)
    ↓
上游 API 端点
    ├── apihub.agnes-ai.com (Agnes AI, P20)
    └── openrouter.ai/api (OpenRouter, P10)
```

### 1.1 服务器环境

| 项目 | 配置 |
|------|------|
| 云平台 | 阿里云 ECS |
| 实例 ID | i-bp1it561iut50ewj0tk4 |
| 操作系统 | Alibaba Cloud Linux (kernel 5.10) |
| CPU | 2 核 |
| 内存 | 1.8 GB (可用 1.5 GB) |
| 磁盘 | 40 GB (已用 87%, 剩余 5.1 GB) |
| Swap | 4 GB |

### 1.2 Docker 容器

| 容器 | 镜像 | 端口 |
|------|------|------|
| new-api | calciumion/new-api | 3000 |
| postgres | PostgreSQL 15 | 5432 |
| redis | Redis 8.8 | 6379 |

### 1.3 域名与 SSL

| 域名 | SSL 证书 | 到期 |
|------|---------|------|
| api.enlyai.com | Let's Encrypt RSA | 2026-09-06 |
| enlyai.com / www.enlyai.com | Let's Encrypt RSA | 2026-07-28 |

SSL 自动续期: crontab `0 3 * * * certbot renew`

---

## 2. 渠道来源

### 2.1 永久免费渠道 (permanent-free-keys.json)

由 `/root/permanent-free-keys.json` 配置，Key 永久有效，优先级最高。

| 来源 | 数量 | base_url | 模型 | 优先级 |
|------|------|----------|------|--------|
| Agnes AI | 8 个 key | https://apihub.agnes-ai.com | agnes-2.0-flash | P20 |
| OpenRouter | 1 个 key | https://openrouter.ai/api | openai/gpt-oss-120b:free | P10 |

**Agnes Key 列表 (8 个):**

| 渠道 ID | 名称 | Key 前缀 |
|---------|------|---------|
| #17 | permanent-agnes-1 | sk-TuKW... |
| #20 | permanent-agnes-2 | sk-GmCU... |
| #23 | permanent-agnes-3 | sk-LTKg... |
| #24 | permanent-agnes-4 | sk-o4wV... |
| #25 | permanent-agnes-5 | sk-Raoe... |
| #31 | permanent-agnes-key6 | sk-Nd3A... |
| #32 | permanent-agnes-key7 | sk-rXyy... |
| #44 | permanent-agnes-8 | sk-8YAt... |

### 2.2 GitHub 共享免费 Key (自动同步)

- **来源**: `alistaitsacle/free-llm-api-keys` (GitHub 仓库 README.md)
- **同步频率**: 每 10 分钟 (crontab `*/10 * * * *`)
- **同步脚本**: `/root/sync-free-keys.py`
- **日志**: `/var/log/sync-free-keys.log`
- **默认 base_url**: `https://aiapiv2.pekpik.com` (pekpik.com 通用转发)

### 2.3 已禁用的渠道来源

| 来源 | 禁用原因 | 处理方式 |
|------|---------|---------|
| pekpik.com | DeepSeek thinking 模式的 `reasoning_content` 字段与 New API 不兼容 | `post_sync_cleanup()` 自动禁用 |

---

## 3. 路由策略

### 3.1 优先级分层

New API 使用 `priority` 字段决定渠道选择顺序，数值越高越优先：

```
P20 (最高) ── Agnes AI (8个key, 随机轮询)
    ↓ 全部不可用时降级
P10 ── OpenRouter gpt-oss-120b (1个key)
    ↓ 不可用时
P8  ── ChatAnywhere / OpenRouter gemma (status=2, 已禁用)
    ↓
P5  ── ChatAnywhere deepseek / OpenRouter nemotron (status=2, 已禁用)
    ↓
P3  ── pekpik kimi (status=2, 已禁用)
    ↓
P1  ── pekpik owl-alpha (status=0, 已禁用)
```

### 3.2 当前活跃路由表 (abilities)

| group | model | channel_id | priority | weight |
|-------|-------|-----------|----------|--------|
| default | enlyai-chat | #17 | 20 | 20 |
| default | enlyai-chat | #20 | 20 | 20 |
| default | enlyai-chat | #23 | 20 | 20 |
| default | enlyai-chat | #24 | 20 | 20 |
| default | enlyai-chat | #25 | 20 | 20 |
| default | enlyai-chat | #31 | 20 | 20 |
| default | enlyai-chat | #32 | 20 | 20 |
| default | enlyai-chat | #44 | 20 | 20 |
| default | enlyai-chat | #52 | 10 | 10 |

### 3.3 路由选择算法

1. **同优先级内**: 按 `weight` 加权随机选择（当前所有 P20 weight=20，即等概率随机轮询）
2. **失败重试**: 当前渠道返回错误时，在同优先级内选择下一个渠道重试
3. **降级**: 同优先级全部失败后，降级到下一优先级
4. **最终失败**: 所有优先级都失败后，返回错误给用户

### 3.4 模型映射 (model_mapping)

用户请求统一模型名 `enlyai-chat`，New API 根据渠道的 `model_mapping` 字段映射到实际模型名：

| 渠道 | model_mapping | 实际请求模型 |
|------|--------------|-------------|
| Agnes | `{"enlyai-chat": "agnes-2.0-flash"}` | agnes-2.0-flash |
| OpenRouter | `{"enlyai-chat": "openai/gpt-oss-120b:free"}` | openai/gpt-oss-120b:free |

---

## 4. 负载均衡

### 4.1 机制

8 个 P20 Agnes 渠道 weight 均为 20，New API 采用**加权随机**策略：

- 每个请求随机分配到 8 个渠道之一
- 概率 = channel_weight / sum(all_P20_weights) = 20/160 = 12.5%
- 8 个 key 均匀分担流量

### 4.2 实测分布

20 次连续请求的路由分布：

| 渠道 | 次数 | 占比 |
|------|------|------|
| #17 | 1 | 5% |
| #20 | 3 | 15% |
| #23 | 1 | 5% |
| #24 | 2 | 10% |
| #25 | 1 | 5% |
| #32 | 2 | 10% |
| #44 | 1 | 5% |

分布合理，符合随机轮询预期。

### 4.3 限流容错

- Agnes 免费 key 有速率限制 (429)
- 单个 key 429 时，New API 自动重试其他 P20 渠道
- 8 个 key 全部 429 时，降级到 P10 OpenRouter
- 理论限流阈值: 单 key 的 8 倍

---

## 5. 同步脚本机制

### 5.1 执行流程

```
crontab (每10分钟) 触发
    ↓
/root/sync-free-keys.py
    ├── 1. 从 GitHub 抓取免费 Key (alistaitsacle/free-llm-api-keys)
    ├── 2. 去重 Key-Model 对
    ├── 3. cleanup_all_channels() — 清理 free-key-sync-* 渠道
    ├── 4. 禁用 pekpik 渠道 (reasoning_content 不兼容)
    ├── 5. 创建新渠道 (free-key-sync-*)
    ├── 6. add_permanent_free_channels() — 添加永久免费渠道
    ├── 7. ensure_model_pricing() — 确保模型定价
    ├── 8. apply_smart_routing() — 智能路由优化
    ├── 9. test_and_disable_dead_channels() — 并行测试渠道
    ├── 10. enforce_token_limits() — Token 权限管理
    ├── 11. apply_param_overrides() — 参数覆盖 (EnlyAI 身份注入)
    └── 12. post_sync_cleanup() — 去重 + 禁用 pekpik + 清理 abilities
```

### 5.2 关键防护: post_sync_cleanup()

每次同步后自动执行，防止问题积累：

```python
def post_sync_cleanup():
    # 1. 禁用所有 pekpik 渠道 (reasoning_content 不兼容)
    psql_exec("UPDATE channels SET status = 0 WHERE base_url LIKE '%%pekpik%%' AND status = 1;")
    
    # 2. 去重: 每个 key 只保留最小 ID 的渠道
    psql_exec("DELETE FROM channels WHERE id NOT IN (SELECT MIN(id) FROM channels WHERE status = 1 GROUP BY key) AND status = 1;")
    
    # 3. 清理孤立的 abilities 记录
    psql_exec("DELETE FROM abilities WHERE channel_id NOT IN (SELECT id FROM channels WHERE status=1);")
```

### 5.3 参数覆盖 (param_override)

每个活跃渠道自动注入以下参数：

1. **max_tokens 上限**: 超过 16384 时自动截断
2. **EnlyAI 身份注入**: 在 messages 前插入系统提示，确保模型自称 EnlyAI

### 5.4 DeepSeek thinking 模式处理

同步脚本对 DeepSeek 渠道设置了 `thinking_to_content: True`：

```python
_deepseek_setting = json.dumps({'thinking_to_content': True})
psql_exec("UPDATE channels SET setting = '%s' WHERE status = 1 AND model_mapping::text LIKE '%%deepseek%%';" % _deepseek_setting)
```

但由于 pekpik 渠道已被禁用，此设置目前不影响路由。

---

## 6. 已解决的问题

### 6.1 "Invalid model name" 错误 (已修复)

| 项目 | 详情 |
|------|------|
| 错误 | `Invalid model name passed in model=agnes-2.0-flash` |
| 根因 | Agnes 渠道 `base_url` 包含 `/v1`，New API 自动拼接导致 `/v1/v1/` 双重前缀 |
| 修复 | `base_url` 改为 `https://apihub.agnes-ai.com`（不带 `/v1`），New API 自动添加 |
| 注意 | New API 对 `type=1` (OpenAI 兼容) 渠道会自动在 `base_url` 后添加 `/v1` |

### 6.2 "reasoning_content" 错误 (已修复)

| 项目 | 详情 |
|------|------|
| 错误 | `The reasoning_content in the thinking mode must be passed back to the API` |
| 根因 | P20 Agnes 429 限流 → 降级到 P10 pekpik DeepSeek → DeepSeek thinking 模式要求回传 `reasoning_content` → New API 未透传该字段 → 400 错误 |
| 修复 | 禁用所有 pekpik 渠道，降级目标改为 OpenRouter (无 thinking 模式问题) |

### 6.3 P20 渠道重复 (已修复)

| 项目 | 详情 |
|------|------|
| 根因 | `add_permanent_free_channels()` 未检查 key 是否已存在，每次同步新增 8 条重复渠道 |
| 修复 | `post_sync_cleanup()` 每次同步后自动去重 |

---

## 7. base_url 配置规则

| 上游 API | base_url | 说明 |
|----------|----------|------|
| Agnes AI | `https://apihub.agnes-ai.com` | **不带** `/v1`，New API 自动添加 |
| OpenRouter | `https://openrouter.ai/api` | **不带** `/v1`，New API 自动添加 |
| pekpik.com | `https://aiapiv2.pekpik.com` | **不带** `/v1`（已禁用） |

**关键规则**: `base_url` 永远不要包含 `/v1` 后缀，New API 会自动拼接 `/v1/chat/completions` 等路径。

---

## 8. 监控与告警

### 8.1 日志位置

| 日志 | 路径 |
|------|------|
| New API 运行日志 | `docker logs new-api` |
| 同步脚本日志 | `/var/log/sync-free-keys.log` |
| 渠道健康数据 | `/var/log/channel-health.json` |
| 告警日志 | `/var/log/channel-alerts.log` |

### 8.2 关键监控指标

- **429 Rate Limit**: Agnes 免费 key 正常限流，会自动重试
- **reasoning_content**: 不应出现，出现说明 pekpik 渠道未被禁用
- **Invalid model name**: 不应出现，出现说明 base_url 配置错误
- **/v1/v1/ 双重前缀**: 不应出现，出现说明 base_url 包含了 /v1

### 8.3 健康检查命令

```bash
# 检查活跃渠道数
docker exec -i postgres psql -U newapi -d newapi -t -A -c \
  "SELECT priority, count(*) FROM channels WHERE status=1 GROUP BY priority ORDER BY priority DESC;"

# 检查重复渠道
docker exec -i postgres psql -U newapi -d newapi -c \
  "SELECT key, count(*) FROM channels WHERE status=1 GROUP BY key HAVING count(*) > 1;"

# 检查 pekpik 渠道是否被禁用
docker exec -i postgres psql -U newapi -d newapi -t -A -c \
  "SELECT count(*) FROM channels WHERE base_url LIKE '%pekpik%' AND status=1;"

# 检查孤立 abilities
docker exec -i postgres psql -U newapi -d newapi -c \
  "SELECT a.* FROM abilities a LEFT JOIN channels c ON a.channel_id = c.id WHERE c.id IS NULL OR c.status != 1;"

# 测试 API
curl -s -X POST "https://api.enlyai.com/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "enlyai-chat", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 10}'
```

---

## 9. 运维操作手册

### 9.1 添加新的 Agnes Key

1. 编辑 `/root/permanent-free-keys.json`，添加新条目
2. 等待下次同步（10 分钟内自动生效），或手动执行：
   ```bash
   python3 /root/sync-free-keys.py
   ```

### 9.2 紧急禁用渠道

```bash
docker exec -i postgres psql -U newapi -d newapi -c \
  "UPDATE channels SET status = 0 WHERE id = CHANNEL_ID;"
docker exec -i postgres psql -U newapi -d newapi -c \
  "DELETE FROM abilities WHERE channel_id = CHANNEL_ID;"
```

### 9.3 手动修复 base_url

```bash
docker exec -i postgres psql -U newapi -d newapi -c \
  "UPDATE channels SET base_url = 'https://apihub.agnes-ai.com' WHERE model_mapping::text LIKE '%agnes%';"
```

### 9.4 清理重复渠道

```bash
docker exec -i postgres psql -U newapi -d newapi -c \
  "DELETE FROM channels WHERE id NOT IN (SELECT MIN(id) FROM channels WHERE status=1 GROUP BY key) AND status=1;"
docker exec -i postgres psql -U newapi -d newapi -c \
  "DELETE FROM abilities WHERE channel_id NOT IN (SELECT id FROM channels WHERE status=1);"
```

### 9.5 重启 New API

```bash
docker restart new-api
```

---

## 10. 磁盘空间警告

当前磁盘使用率 **87%** (剩余 5.1 GB)，需要关注：

- Docker 日志可能快速增长：`docker logs new-api` 会持续写入
- 同步脚本日志：`/var/log/sync-free-keys.log` 已达 7.6 MB
- 建议：配置 logrotate 或定期清理日志

```bash
# 清理 Docker 日志
truncate -s 0 $(docker inspect --format='{{.LogPath}}' new-api)

# 清理同步日志
> /var/log/sync-free-keys.log
```
