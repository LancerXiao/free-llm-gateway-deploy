#!/usr/bin/env python3
"""完全移除 beian 注入脚本和浮层"""
import subprocess, time, base64, json

ECS_INSTANCE = "i-bp1it561iut50ewj0tk4"
ECS_REGION = "cn-hangzhou"

def run_ecs_cmd(cmd_content, wait_time=25):
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
    except Exception as e:
        return f"Parse error: {e}"
    time.sleep(wait_time)
    for attempt in range(10):
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

# Python 修复脚本 - 完全移除 beian 注入脚本
fix_py = r'''#!/usr/bin/env python3
import re

CONF = "/etc/nginx/conf.d/enlyai.com.conf"

with open(CONF, 'r') as f:
    content = f.read()

print("=== 修改前 ===")
# 查找 beian 相关的 sub_filter
body_match = re.search(r"sub_filter '</body>' '[^']*';", content)
if body_match:
    print("当前 </body> sub_filter (前 200 字符):")
    print(body_match.group(0)[:200])
    print("...")

# 完全移除 beian 注入脚本
# 原内容: <script>(function(){function _bf(){...atob("...")...}})();</script>
# 移除整个 _bf 函数及其调用的 <script>...</script>
old_pattern = r"<script>\(function\(\)\{function _bf\(\).*?_bm\.observe\(document\.body,\{childList:true,subtree:false\}\)\}\)\(\);</script>"
new_content = re.sub(old_pattern, "", content, count=1, flags=re.DOTALL)

if new_content != content:
    print("\n✅ 已移除 beian 注入脚本")
    content = new_content
else:
    print("\n⚠️ 未找到 beian 脚本，尝试另一种模式")
    # 尝试更宽松的匹配
    old_pattern2 = r"<script>\(function\(\)\{function _bf.*?</script>"
    new_content = re.sub(old_pattern2, "", content, count=1, flags=re.DOTALL)
    if new_content != content:
        print("✅ 已移除 beian 注入脚本 (宽松匹配)")
        content = new_content
    else:
        print("❌ 仍未找到")

with open(CONF, 'w') as f:
    f.write(content)

print("\n=== 修改后 ===")
body_match = re.search(r"sub_filter '</body>' '[^']*';", content)
if body_match:
    print("</body> sub_filter (前 300 字符):")
    print(body_match.group(0)[:300])
    print("...")

# 统计剩余 beian 相关内容
beian_count = content.count("_enlyai_beian")
print(f"\n剩余 _enlyai_beian 引用数: {beian_count}")
'''

fix_py_b64 = base64.b64encode(fix_py.encode('utf-8')).decode('ascii')

bash_cmd = f"""#!/bin/bash
echo "{fix_py_b64}" | base64 -d > /tmp/remove_beian.py
python3 /tmp/remove_beian.py

echo ""
echo "=== 验证 nginx ==="
nginx -t 2>&1 | tail -3

echo ""
echo "=== 重载 nginx ==="
if nginx -t 2>&1 | grep -q successful; then
    nginx -s reload 2>&1 && echo "nginx reload OK"
fi

sleep 2
echo ""
echo "=== 验证: 首页是否还有 _enlyai_beian ==="
COUNT=$(curl -s --max-time 10 https://enlyai.com/ | grep -c "_enlyai_beian")
echo "_enlyai_beian 出现次数: $COUNT"

echo ""
echo "=== 验证: 首页是否还有 atob( 备案 ==="
COUNT2=$(curl -s --max-time 10 https://enlyai.com/ | grep -c 'atob(')
echo "atob( 出现次数: $COUNT2"

echo ""
echo "=== 验证: 首页底部 HTML (最后 500 字符) ==="
curl -s --max-time 10 https://enlyai.com/ | tail -c 500
"""

print("=" * 70)
print("完全移除 beian 注入脚本")
print("=" * 70)
print(run_ecs_cmd(bash_cmd, wait_time=30))
