#!/usr/bin/env python3
"""Comprehensive fix: dedup, disable pekpik, clean abilities, fix sync script."""
import subprocess
import time
import base64
import json

ECS_INSTANCE = "i-bp1it561iut50ewj0tk4"
ECS_REGION = "cn-hangzhou"

def run_ecs_cmd(cmd_content, wait_time=20):
    encoded = base64.b64encode(cmd_content.encode('utf-8')).decode('ascii')
    r = subprocess.run(
        ['aliyun', 'ecs', 'RunCommand', '--RegionId', ECS_REGION,
         '--InstanceId.1', ECS_INSTANCE, '--Type', 'RunShellScript',
         '--CommandContent', encoded, '--ContentEncoding', 'Base64',
         '--Timeout', '300'],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        return f"CLI_ERROR: {r.stderr[:500]}"
    try:
        data = json.loads(r.stdout)
        invoke_id = data.get('InvokeId')
        if not invoke_id:
            return f"No InvokeId: {r.stdout[:500]}"
    except Exception as e:
        return f"Parse error: {e}"
    time.sleep(wait_time)
    for attempt in range(5):
        r2 = subprocess.run(
            ['aliyun', 'ecs', 'DescribeInvocationResults', '--RegionId', ECS_REGION,
             '--InvokeId', invoke_id],
            capture_output=True, text=True
        )
        try:
            data2 = json.loads(r2.stdout)
            outputs = data2.get('Invocation', {}).get('InvocationResults', {}).get('InvocationResult', [])
            if outputs:
                output = outputs[0].get('Output', '')
                if output:
                    return base64.b64decode(output).decode('utf-8', errors='ignore')
        except Exception as e:
            return f"Result error: {e}"
        time.sleep(5)
    return "Timeout"

print("=" * 80)
print("全面修复: 去重 + 禁用 pekpik + 清理 abilities + 修复同步脚本")
print("=" * 80)

cmd = r"""echo "============================================================"
echo "  Step 1: 禁用所有 pekpik.com 渠道"
echo "============================================================"
docker exec -i postgres psql -U newapi -d newapi -c "UPDATE channels SET status = 0 WHERE base_url LIKE '%pekpik%' AND status = 1;"

echo ""
echo "============================================================"
echo "  Step 2: 删除 P20 重复 Agnes 渠道"
echo "============================================================"
docker exec -i postgres psql -U newapi -d newapi -c "DELETE FROM channels WHERE id NOT IN (SELECT MIN(id) FROM channels WHERE priority = 20 AND status = 1 GROUP BY key) AND priority = 20 AND status = 1;"

echo ""
echo "============================================================"
echo "  Step 3: 清理 abilities 表"
echo "============================================================"
docker exec -i postgres psql -U newapi -d newapi -c "DELETE FROM abilities WHERE channel_id NOT IN (SELECT id FROM channels WHERE status=1);"

echo ""
echo "============================================================"
echo "  Step 4: 修复同步脚本 - 添加去重和 pekpik 过滤"
echo "============================================================"
if [ -f /root/sync-free-keys.py ]; then
    cp /root/sync-free-keys.py /root/sync-free-keys.py.backup 2>/dev/null
    
    # 检查是否已有去重逻辑
    if grep -q "dedup_channels" /root/sync-free-keys.py; then
        echo "  sync-free-keys.py already has dedup logic"
    else
        # 在文件末尾添加去重和 pekpik 过滤
        cat >> /root/sync-free-keys.py << 'SYNCFIX'

# ============================================================
# Post-sync cleanup: dedup channels and disable pekpik
# ============================================================
def post_sync_cleanup():
    # Clean up after sync: remove duplicates and disable pekpik channels
    # 1. Disable all pekpik channels (reasoning_content incompatibility)
    psql_exec("UPDATE channels SET status = 0 WHERE base_url LIKE '%%pekpik%%' AND status = 1;")
    
    # 2. Dedup: keep only one channel per unique key
    psql_exec("DELETE FROM channels WHERE id NOT IN (SELECT MIN(id) FROM channels WHERE status = 1 GROUP BY key) AND status = 1;")
    
    # 3. Clean up orphaned abilities
    psql_exec("DELETE FROM abilities WHERE channel_id NOT IN (SELECT id FROM channels WHERE status=1);")
    
    print("Post-sync cleanup: dedup + pekpik disable done")

# Auto-run after sync
post_sync_cleanup()
SYNCFIX
        echo "  sync-free-keys.py: added post_sync_cleanup()"
    fi
fi

echo ""
echo "============================================================"
echo "  Step 5: 更新 permanent-free-keys.json"
echo "============================================================"
cat > /root/permanent-free-keys.json << 'EOF'
[
  {"name": "agnes-1", "base_url": "https://apihub.agnes-ai.com", "key": "sk-TuKWa0JQb9nGiUc7d6goWxpRzhUGfRpALI1DASAf1qOIXNCs", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-2", "base_url": "https://apihub.agnes-ai.com", "key": "sk-GmCUMCkI0OBpnEgEYmueLV1zFPIPd3lvoNHUVrOYHSp4w67H", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-3", "base_url": "https://apihub.agnes-ai.com", "key": "sk-LTKgWPhpP0t6TPbY1z5O2oVNzziOhSWurIaP1CVJnUECr4kH", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-4", "base_url": "https://apihub.agnes-ai.com", "key": "sk-o4wVmeEhWdBFVkOZdtbyydW0Km0EmE2vX4Ve3As3b8OHJXux", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-5", "base_url": "https://apihub.agnes-ai.com", "key": "sk-RaoeOCMHAAU8bdSw8PyLgvDasoQWRZRQjiJSfxX8nj3UJtEi", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-6", "base_url": "https://apihub.agnes-ai.com", "key": "sk-Nd3AiXAOPApegPtVCNmWaySf0eZH3xeFadxlt9tEYFLmryJc", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-7", "base_url": "https://apihub.agnes-ai.com", "key": "sk-rXyyR9XFkCbAQir9CNtopQyF3fX4hjq0fTtBhj5WIOJYxsSp", "models": ["agnes-2.0-flash"], "priority": 20},
  {"name": "agnes-8", "base_url": "https://apihub.agnes-ai.com", "key": "sk-8YAts7i7ZmqLQTLubRhY8iqiDi3LIhugZgVUapLEikDxbkb5", "models": ["agnes-2.0-flash"], "priority": 20}
]
EOF
echo "  permanent-free-keys.json updated (8 Agnes keys only)"

echo ""
echo "============================================================"
echo "  Step 6: 最终状态"
echo "============================================================"
echo ""
echo "=== 活跃渠道 ==="
docker exec -i postgres psql -U newapi -d newapi -c "SELECT id, name, priority, status, base_url, model_mapping FROM channels WHERE status=1 ORDER BY priority DESC, id;"

echo ""
echo "=== abilities 表 ==="
docker exec -i postgres psql -U newapi -d newapi -c "SELECT * FROM abilities ORDER BY channel_id;"

echo ""
echo "=== 验证: 10 次请求 ==="
TEST_KEY="sk-scz5ymhelfKbuckZK04znfZmtrjKrOtIMDT6j8NLcL3rq1qM"
OK=0
for i in $(seq 1 10); do
    RESULT=$(curl -s -m 30 -X POST "https://api.enlyai.com/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TEST_KEY" \
        -d '{"model": "enlyai-chat", "messages": [{"role": "user", "content": "Say ok"}], "max_tokens": 20, "stream": false}' 2>&1)
    echo "$RESULT" | grep -q "choices" && OK=$((OK+1))
done
echo "  Result: $OK/10 success"
"""

result = run_ecs_cmd(cmd, 35)
print(result)
