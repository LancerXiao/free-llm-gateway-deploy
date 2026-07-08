#!/usr/bin/env python3
"""Quick check: ECS test results and recent logs."""
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

cmd = r"""echo "=== Quick test: 10 requests ==="
TEST_KEY="sk-scz5ymhelfKbuckZK04znfZmtrjKrOtIMDT6j8NLcL3rq1qM"
OK=0
FAIL=0
for i in $(seq 1 10); do
    RESULT=$(curl -s -m 30 -X POST "https://api.enlyai.com/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TEST_KEY" \
        -d '{"model": "enlyai-chat", "messages": [{"role": "user", "content": "Say ok"}], "max_tokens": 20, "stream": false}' 2>&1)
    if echo "$RESULT" | grep -q "choices"; then
        OK=$((OK+1))
    else
        FAIL=$((FAIL+1))
        echo "  #$i: FAIL"
    fi
done
echo "  Result: $OK/10 success"

echo ""
echo "=== Recent errors ==="
docker logs --tail 30 new-api 2>&1 | grep "\[ERR\]" | tail -5 || echo "  (none)"

echo ""
echo "=== reasoning_content check ==="
docker logs --tail 50 new-api 2>&1 | grep "reasoning_content" | tail -3 || echo "  (none)"

echo ""
echo "=== Current channel config ==="
docker exec -i postgres psql -U newapi -d newapi -t -A -F ' | ' -c "SELECT id, name, priority, base_url, model_mapping FROM channels WHERE status=1 ORDER BY priority DESC, id;"
"""

result = run_ecs_cmd(cmd, 30)
print(result)
