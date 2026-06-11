#!/bin/bash
echo "=== STEP 1: Register User ==="
curl -s -X POST http://localhost:3000/api/user/register -H 'Content-Type: application/json' -d '{"username":"final_verify","password":"FinalTest123!","email":"final@test.com"}' --max-time 10
echo ""

echo "=== STEP 2: Run enforce_token_limits ==="
python3 << 'PYEOF'
import sys, os
sys.path.insert(0, '/root')
os.chdir('/root')
with open('/root/sync-free-keys.py') as f:
    code = f.read()
func_code = code.split('if __name__')[0]
exec(func_code)
enforce_token_limits()
PYEOF
echo ""

echo "=== STEP 3: Get Token ==="
TOKEN_KEY=$(docker exec postgres psql -U newapi -d newapi -t -A -c "SELECT key FROM tokens WHERE user_id=(SELECT id FROM users WHERE username='final_verify') AND deleted_at IS NULL LIMIT 1;" | tr -d ' ')
echo "Token: sk-${TOKEN_KEY}"
echo ""

echo "=== STEP 4: Chat API Test ==="
curl -s http://localhost:3000/v1/chat/completions -H "Authorization: Bearer sk-$TOKEN_KEY" -H 'Content-Type: application/json' -d '{"model":"enlyai-chat","messages":[{"role":"user","content":"Hello! Reply in one sentence."}],"max_tokens":50}' --max-time 30
echo ""
echo ""

echo "=== STEP 5: Embedding API Test ==="
curl -s http://localhost:3000/v1/embeddings -H "Authorization: Bearer sk-$TOKEN_KEY" -H 'Content-Type: application/json' -d '{"model":"enlyai-embedding","input":"Hello world"}' --max-time 30 | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK - dim:', len(d['data'][0]['embedding'])) if 'data' in d else print('ERROR:', d)"
echo ""

echo "=== STEP 6: Models API Test ==="
curl -s http://localhost:3000/v1/models -H "Authorization: Bearer sk-$TOKEN_KEY" | python3 -c "import sys,json; data=json.load(sys.stdin); [print(m['id']) for m in data.get('data',[])]"
echo ""

echo "=== STEP 7: Token Expiry Check ==="
docker exec postgres psql -U newapi -d newapi -t -A -c "SELECT t.id, u.username, t.name, CASE WHEN t.expired_time=-1 THEN 'never' ELSE (t.expired_time - t.created_time)/86400::text || ' days' END as duration, t.unlimited_quota FROM tokens t JOIN users u ON t.user_id = u.id WHERE u.username='final_verify' AND t.deleted_at IS NULL;"
echo ""

echo "=== STEP 8: User Quota Check ==="
docker exec postgres psql -U newapi -d newapi -t -A -c "SELECT id, username, quota, used_quota FROM users WHERE username='final_verify';"
echo ""

echo "=== STEP 9: External HTTPS Access ==="
curl -s -o /dev/null -w 'HTTP %{http_code}\n' https://api.enlyai.com/ --max-time 10
echo ""

echo "=== ALL TESTS COMPLETE ==="
