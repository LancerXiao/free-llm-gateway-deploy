#!/usr/bin/env python3
"""更新 crawler_server.py: 所有爬虫获取中文"""
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

# 更新后的 crawler_server.py - 所有爬虫获取中文
crawler_server_py = r'''#!/usr/bin/env python3
import http.server
import socketserver
import os

ZH_FILE = '/var/www/enlyai.com/seo/crawler_home_zh.html'
EN_FILE = '/var/www/enlyai.com/seo/crawler_home.html'

# 已知爬虫 User-Agent 关键词
SPIDER_KEYWORDS = [
    'spider', 'bot', 'crawler', 'slurp', 'archiver',
    'feed', 'fetcher', 'monitor', 'scan', 'linkcheck',
    'preview', 'renderer'
]

class CrawlerHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        ua = self.headers.get('User-Agent', '').lower()
        accept_lang = self.headers.get('Accept-Language', '').lower()

        # 判断是否是爬虫
        is_spider = any(kw in ua for kw in SPIDER_KEYWORDS)
        # 判断是否明确请求英文
        is_en = accept_lang.startswith('en') and 'zh' not in accept_lang

        # 逻辑：爬虫→中文（搜索引擎显示中文）；浏览器：英文Accept→英文，其他→中文
        if is_spider:
            filepath = ZH_FILE
        elif is_en:
            filepath = EN_FILE
        else:
            filepath = ZH_FILE

        if not os.path.exists(filepath):
            filepath = EN_FILE if os.path.exists(EN_FILE) else ZH_FILE

        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Vary', 'Accept-Language')
        self.end_headers()
        with open(filepath, 'rb') as f:
            self.wfile.write(f.read())

    def log_message(self, format, *args):
        pass

server = socketserver.TCPServer(('127.0.0.1', 8902), CrawlerHandler)
server.serve_forever()
'''

py_b64 = base64.b64encode(crawler_server_py.encode('utf-8')).decode('ascii')

bash_cmd = f"""#!/bin/bash
echo "{py_b64}" | base64 -d > /opt/enlyai/crawler_server.py
echo "crawler_server.py 已更新 (爬虫全部中文)"

systemctl restart enlyai-crawler-server 2>/dev/null || (pkill -f "crawler_server.py" 2>/dev/null; sleep 2; nohup python3 /opt/enlyai/crawler_server.py > /var/log/crawler_server.log 2>&1 &)
sleep 3

echo ""
echo "=== 验证 ==="
echo "--- bingbot, Accept-Language: en → 应中文 ---"
curl -s --max-time 10 -A "bingbot/2.0" -H "Accept-Language: en" http://127.0.0.1:8902 | grep -o '<title>[^<]*</title>' | head -1
echo "--- Googlebot, Accept-Language: en → 应中文 ---"
curl -s --max-time 10 -A "Googlebot" -H "Accept-Language: en" http://127.0.0.1:8902 | grep -o '<title>[^<]*</title>' | head -1
echo "--- Baiduspider → 应中文 ---"
curl -s --max-time 10 -A "Baiduspider" http://127.0.0.1:8902 | grep -o '<title>[^<]*</title>' | head -1
echo "--- 普通浏览器, en-US → 应英文 ---"
curl -s --max-time 10 -A "Mozilla/5.0 Chrome" -H "Accept-Language: en-US" http://127.0.0.1:8902 | grep -o '<title>[^<]*</title>' | head -1
echo "--- 普通浏览器, zh-CN → 应中文 ---"
curl -s --max-time 10 -A "Mozilla/5.0 Chrome" -H "Accept-Language: zh-CN" http://127.0.0.1:8902 | grep -o '<title>[^<]*</title>' | head -1
"""

print(run_ecs_cmd(bash_cmd, wait_time=25))
