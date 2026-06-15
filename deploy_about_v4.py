#!/usr/bin/env python3
"""Deploy About HTML v4 to server - fix language adaptation and hero icon"""
import subprocess
import sys

SERVER_ID = 'i-bp1it561iut50ewj0tk4'

def run_remote(cmd, name=""):
    """Execute command on remote server via aliyun CLI"""
    full_cmd = [
        'aliyun', 'ecs', 'RunCommand',
        '--RegionId', 'cn-hangzhou',
        '--Type', 'RunShellScript',
        '--CommandContent', cmd,
        '--InstanceId.1', SERVER_ID,
        '--Timeout', '60'
    ]
    if name:
        print(f"  [{name}] Running...")
    result = subprocess.run(full_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ERROR: {result.stderr[:200]}")
        return None
    return result.stdout.strip()

def main():
    # Read the HTML content
    with open('/workspace/about_content_v4.html', 'r', encoding='utf-8') as f:
        html_content = f.read()

    print(f"HTML content: {len(html_content)} chars")

    # Encode to base64
    import base64
    b64 = base64.b64encode(html_content.encode('utf-8')).decode('ascii')
    print(f"Base64 length: {len(b64)} chars")

    # Split into chunks of 3500 chars for aliyun CLI
    chunk_size = 3500
    chunks = [b64[i:i+chunk_size] for i in range(0, len(b64), chunk_size)]
    print(f"Will upload in {len(chunks)} chunks")

    # Step 1: Clear the file on server
    print("\n[1/5] Clearing temp file on server...")
    run_remote('> /tmp/about_v4_b64.txt', "clear")

    # Step 2: Upload chunks
    print("\n[2/5] Uploading base64 chunks...")
    for i, chunk in enumerate(chunks):
        result = run_remote(f'echo -n "{chunk}" >> /tmp/about_v4_b64.txt', f"chunk {i+1}/{len(chunks)}")
        if result is None:
            print(f"  Failed on chunk {i+1}, aborting")
            sys.exit(1)

    # Step 3: Decode and verify
    print("\n[3/5] Decoding on server...")
    run_remote('base64 -d /tmp/about_v4_b64.txt > /tmp/about_v4.html', "decode")
    result = run_remote('wc -c /tmp/about_v4.html', "verify")
    print(f"  Server file size: {result}")

    # Step 4: Update database
    print("\n[4/5] Updating PostgreSQL database...")
    db_cmd = '''
python3 -c "
import psycopg2
conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='new_api', user='postgres', password='postgres')
cur = conn.cursor()
with open('/tmp/about_v4.html', 'r') as f:
    content = f.read()
content_escaped = content.replace(\"'\", \"''\")
cur.execute(\"UPDATE options SET value='%s' WHERE key='About'\" % content_escaped)
conn.commit()
cur.execute(\"SELECT length(value) FROM options WHERE key='About'\")
row = cur.fetchone()
print('DB value length:', row[0])
conn.close()
"
'''
    result = run_remote(db_cmd, "db update")
    print(f"  DB update result: {result}")

    # Step 5: Restart new-api container
    print("\n[5/5] Restarting new-api container...")
    result = run_remote('docker restart new-api', "restart")
    print(f"  Container restart: {result}")

    # Verify API response
    print("\n[Verifying] Checking API response...")
    import time
    time.sleep(5)
    result = run_remote('curl -s http://127.0.0.1:3000/api/about | head -c 500', "api check")
    print(f"  API response (first 500 chars): {result}")

    # Check for key markers
    result_full = run_remote('curl -s http://127.0.0.1:3000/api/about', "api full")
    if result_full:
        has_onerror = 'onerror' in result_full
        has_logo = '/logo.png' in result_full
        has_lang_class = 'ea-lang-' in result_full
        print(f"\n  Verification:")
        print(f"    - onerror trick present: {has_onerror}")
        print(f"    - /logo.png in hero: {has_logo}")
        print(f"    - Language class switching: {has_lang_class}")
    else:
        print("  Could not verify API response")

    print("\nDeployment complete!")

if __name__ == '__main__':
    main()
