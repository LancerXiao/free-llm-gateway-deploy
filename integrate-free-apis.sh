#!/bin/bash
# ============================================================
# 集成免费 LLM API 来源到 New API 系统
# 日期: 2026-06-10
# 说明: 添加 LLM7.io、OpenRouter 免费模型等渠道
# ============================================================

set -e

PSQL="docker exec postgres psql -U newapi -d newapi -t -A"

echo "=========================================="
echo "  免费LLM API来源集成脚本"
echo "=========================================="

# ----------------------------------------------------------
# 1. 验证 LLM7.io 可用性
# ----------------------------------------------------------
echo ""
echo "[1/7] 验证 LLM7.io 可用性..."
LLM7_RESULT=$(curl -s --max-time 15 https://api.llm7.io/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3-235b-a22b:free","messages":[{"role":"user","content":"Say hi"}],"max_tokens":10}' 2>&1)

if echo "$LLM7_RESULT" | grep -q '"choices"'; then
  echo "  ✅ LLM7.io 可用"
else
  echo "  ❌ LLM7.io 不可用: $(echo $LLM7_RESULT | head -c 200)"
fi

# ----------------------------------------------------------
# 2. 验证 OpenRouter 免费模型
# ----------------------------------------------------------
echo ""
echo "[2/7] 验证 OpenRouter 免费模型..."
OR_MODELS=$(curl -s --max-time 15 https://openrouter.ai/api/v1/models | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
free = [m for m in data.get('data', []) if m.get('pricing', {}).get('prompt', '1') == '0' and m.get('pricing', {}).get('completion', '1') == '0']
print(len(free))
" 2>&1)
echo "  OpenRouter 免费模型数量: $OR_MODELS"

# ----------------------------------------------------------
# 3. 获取现有 OpenRouter Key
# ----------------------------------------------------------
echo ""
echo "[3/7] 查找现有 OpenRouter API Key..."
OR_KEY=""
if [ -f /root/permanent-free-keys.json ]; then
  OR_KEY=$(python3 -c "
import json
with open('/root/permanent-free-keys.json') as f:
    data = json.load(f)
for ch in data:
    if 'openrouter' in ch.get('base_url','').lower():
        print(ch['key'])
        break
" 2>&1)
fi

if [ -z "$OR_KEY" ]; then
  echo "  ⚠️ 未找到 OpenRouter Key，将跳过 OpenRouter 渠道"
  echo "  提示: 注册 https://openrouter.ai/keys 获取免费 Key"
else
  echo "  ✅ 找到 OpenRouter Key: ${OR_KEY:0:20}..."

  # 测试 OpenRouter Key
  OR_TEST=$(curl -s --max-time 15 https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OR_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"openrouter/free","messages":[{"role":"user","content":"Say hi"}],"max_tokens":10}' 2>&1)

  if echo "$OR_TEST" | grep -q '"choices"'; then
    echo "  ✅ OpenRouter Key 有效"
  else
    echo "  ❌ OpenRouter Key 无效: $(echo $OR_TEST | head -c 200)"
    OR_KEY=""
  fi
fi

# ----------------------------------------------------------
# 4. 添加 LLM7.io 渠道（无需 Key，最高优先级）
# ----------------------------------------------------------
echo ""
echo "[4/7] 添加 LLM7.io 渠道..."

# 检查是否已存在
LLM7_EXISTS=$($PSQL -c "SELECT COUNT(*) FROM channels WHERE name LIKE 'LLM7-%';" 2>&1)
if [ "$LLM7_EXISTS" -gt 0 ] 2>/dev/null; then
  echo "  LLM7 渠道已存在，跳过"
else
  $PSQL -c "
  INSERT INTO channels (name, type, key, base_url, models, model_mapping, priority, status, auto_ban, created_time, test_time)
  VALUES
  ('LLM7-qwen3-235b', 1, 'no-key-needed', 'https://api.llm7.io', 'enlyai-chat', '{\"enlyai-chat\": \"qwen3-235b-a22b:free\"}', 15, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
  ('LLM7-mistral-small', 1, 'no-key-needed', 'https://api.llm7.io', 'enlyai-chat', '{\"enlyai-chat\": \"mistral-small-3.2:free\"}', 14, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
  ('LLM7-codestral', 1, 'no-key-needed', 'https://api.llm7.io', 'enlyai-chat', '{\"enlyai-chat\": \"codestral-latest\"}', 13, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int);
  " 2>&1
  echo "  ✅ 添加了 3 个 LLM7.io 渠道 (优先级 13-15)"
fi

# ----------------------------------------------------------
# 5. 添加 OpenRouter 免费模型渠道
# ----------------------------------------------------------
echo ""
echo "[5/7] 添加 OpenRouter 免费模型渠道..."

if [ -n "$OR_KEY" ]; then
  OR_EXISTS=$($PSQL -c "SELECT COUNT(*) FROM channels WHERE name LIKE 'OR-free-%';" 2>&1)
  if [ "$OR_EXISTS" -gt 0 ] 2>/dev/null; then
    echo "  OpenRouter 渠道已存在，跳过"
  else
    $PSQL -c "
    INSERT INTO channels (name, type, key, base_url, models, model_mapping, priority, status, auto_ban, created_time, test_time)
    VALUES
    ('OR-free-router', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"openrouter/free\"}', 11, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
    ('OR-free-gemma4', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"google/gemma-4-26b-a4b-it:free\"}', 10, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
    ('OR-free-qwen3', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"qwen/qwen3-next-80b-a3b-instruct:free\"}', 9, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
    ('OR-free-kimi', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"moonshotai/kimi-k2.6:free\"}', 8, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
    ('OR-free-llama', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"meta-llama/llama-3.3-70b-instruct:free\"}', 7, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int),
    ('OR-free-nemotron', 1, '$OR_KEY', 'https://openrouter.ai/api/v1', 'enlyai-chat', '{\"enlyai-chat\": \"nvidia/nemotron-3-ultra-550b-a55b:free\"}', 6, 1, 0, EXTRACT(EPOCH FROM NOW())::int, EXTRACT(EPOCH FROM NOW())::int);
    " 2>&1
    echo "  ✅ 添加了 6 个 OpenRouter 免费渠道 (优先级 6-11)"
  fi
else
  echo "  ⚠️ 跳过 OpenRouter 渠道（无有效 Key）"
  echo "  获取免费 Key: https://openrouter.ai/keys"
fi

# ----------------------------------------------------------
# 6. 修复 abilities 表
# ----------------------------------------------------------
echo ""
echo "[6/7] 修复 abilities 表..."

# 为新渠道添加 abilities
$PSQL -c "
INSERT INTO abilities (channel_id, model, enabled, priority, weight, created_time)
SELECT id, 'enlyai-chat', 1, priority, 1, EXTRACT(EPOCH FROM NOW())::int
FROM channels
WHERE (name LIKE 'LLM7-%' OR name LIKE 'OR-free-%')
  AND status = 1
  AND id NOT IN (SELECT channel_id FROM abilities WHERE model = 'enlyai-chat');
" 2>&1

echo "  ✅ abilities 表已更新"

# 清理 models 表（只保留 enlyai-* 模型）
$PSQL -c "DELETE FROM models WHERE model_name NOT LIKE 'enlyai-%%';" 2>&1
echo "  ✅ models 表已清理"

# ----------------------------------------------------------
# 7. 验证渠道配置
# ----------------------------------------------------------
echo ""
echo "[7/7] 验证渠道配置..."
echo ""
echo "=== 所有活跃渠道（按优先级排序）==="
$PSQL -c "SELECT id, name, priority, status, model_mapping FROM channels WHERE status=1 ORDER BY priority DESC, id;" 2>&1

echo ""
echo "=== enlyai-chat 可用渠道数 ==="
$PSQL -c "SELECT COUNT(*) FROM abilities WHERE model='enlyai-chat' AND enabled=1;" 2>&1

echo ""
echo "=========================================="
echo "  集成完成！"
echo "=========================================="
echo ""
echo "新增渠道优先级:"
echo "  LLM7.io (无需Key):   P15-P13"
echo "  OpenRouter (免费模型): P11-P6"
echo "  原有永久免费渠道:     P10-P5"
echo "  原有共享Key渠道:      P3"
echo ""
echo "测试命令:"
echo "  curl -s https://api.enlyai.com/v1/chat/completions \\"
echo "    -H 'Authorization: Bearer $ENLYAI_API_KEY' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\":\"enlyai-chat\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}],\"max_tokens\":30}'"
