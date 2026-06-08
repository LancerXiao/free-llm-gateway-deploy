#!/bin/bash
# ============================================
# API.ENLYAI.COM 完整部署指南
# ============================================
#
# 请在阿里云 ECS 上按顺序执行以下步骤
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
step() { echo -e "\n${BLUE}[STEP]${NC} $1"; }

# ============================================
# 第一步：配置域名解析
# ============================================
step "1. 配置域名 DNS 解析（需在阿里云控制台操作）"

cat <<'DNS_GUIDE'
请在阿里云控制台完成以下操作：

1. 登录 https://dns.console.aliyun.com
2. 找到 enlyai.com 域名
3. 添加记录：
   - 记录类型: A
   - 主机记录: api
   - 记录值: <你的ECS公网IP>
   - TTL: 10分钟

4. 等待 DNS 生效（通常 1-10 分钟）
5. 验证: ping api.enlyai.com 应该解析到你的 ECS IP
DNS_GUIDE

echo ""
read -p "域名解析已配置完成？(y/N): " dns_done
[ "$dns_done" = "y" ] || { warn "请先完成域名解析再继续"; exit 0; }

# ============================================
# 第二步：克隆项目到 ECS
# ============================================
step "2. 克隆项目到 ECS"

if [ ! -d "/root/new-api" ]; then
    git clone https://github.com/LancerXiao/free-llm-gateway-deploy.git /root/new-api 2>/dev/null || \
    git clone https://github.com/QuantumNous/new-api.git /root/new-api
fi

cd /root/new-api

# ============================================
# 第三步：启动服务
# ============================================
step "3. 启动 New API 服务"

# 先用 HTTP 模式启动（签发证书前需要）
cat > nginx/conf.d/default.conf <<'NGINX_HTTP'
upstream new_api_backend {
    server new-api:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name api.enlyai.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://new_api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        client_max_body_size 100m;
    }

    location ~ ^/v1/(chat|completions|audio|images|files) {
        proxy_pass http://new_api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding on;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_set_header Accept-Encoding "";
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
NGINX_HTTP

# 生成随机密码
DB_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
SESSION_SECRET=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)

# 替换密码
sed -i "s/YourStrongPassword123!/${DB_PASSWORD}/g" docker-compose.prod.yml
sed -i "s/YourRedisPassword123!/${REDIS_PASSWORD}/g" docker-compose.prod.yml
sed -i "s/change_this_to_a_random_string_in_production/${SESSION_SECRET}/g" docker-compose.prod.yml

# 保存密码
cat > .env.production <<EOF
DB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
SESSION_SECRET=${SESSION_SECRET}
EOF
chmod 600 .env.production

# 创建必要目录
mkdir -p data logs nginx/certbot/webroot

# 启动
docker compose -f docker-compose.prod.yml up -d
info "等待服务启动..."
sleep 20

# 检查
docker compose -f docker-compose.prod.yml ps

# ============================================
# 第四步：签发 SSL 证书
# ============================================
step "4. 签发 Let's Encrypt SSL 证书"

docker compose -f docker-compose.prod.yml run --rm certbot \
    certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "admin@enlyai.com" \
    --agree-tos \
    --no-eff-email \
    -d "api.enlyai.com"

# 切换到 HTTPS 配置
cat > nginx/conf.d/default.conf <<'NGINX_HTTPS'
upstream new_api_backend {
    server new-api:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name api.enlyai.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.enlyai.com;

    ssl_certificate /etc/letsencrypt/live/api.enlyai.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.enlyai.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    location / {
        proxy_pass http://new_api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        client_max_body_size 100m;
    }

    location ~ ^/v1/(chat|completions|audio|images|files) {
        proxy_pass http://new_api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding on;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_set_header Accept-Encoding "";
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
NGINX_HTTPS

docker compose -f docker-compose.prod.yml restart nginx

info "HTTPS 已启用！"

# ============================================
# 第五步：配置 Key 池
# ============================================
step "5. 在 New API 管理后台配置 Key 池"

cat <<'KEY_GUIDE'
============================================
现在请打开浏览器完成以下操作：
============================================

1. 访问 https://api.enlyai.com
   - 默认账号: root
   - 默认密码: 123456
   - ⚠️ 登录后立即修改密码！

2. 添加渠道（Channel）- 你的 free-llm-gateway 后端
   ────────────────────────────────────────
   左侧菜单 → 渠道 → 添加新的渠道

   方案 A：直接添加后端代理（推荐）
   ─────────────────────────────────
   类型: OpenAI
   名称: free-llm-pool
   Base URL: https://aiapiv2.pekpik.com/v1
   密钥: （从 https://raw.githubusercontent.com/alistaitsacle/free-llm-api-keys/main/README.md 获取）
   模型: kimi-k2.5,deepseek-v4-pro,deepseek-v4-flash,claude-opus-4-7,gemini-2.5-flash,smart-chat,qwen/qwen3.6-flash

   方案 B：通过你的 Railway 网关中转
   ─────────────────────────────────
   类型: OpenAI
   名称: railway-gateway
   Base URL: https://gateway-production-f831.up.railway.app/v1
   密钥: sk-free-llm-gateway
   模型: kimi-k2.5,deepseek-v4-pro,deepseek-v4-flash,claude-opus-4-7,gemini-2.5-flash,smart-chat

3. 创建统一令牌（Token）
   ─────────────────────────────────
   左侧菜单 → 令牌 → 添加新的令牌
   名称: enlyai-unified-key
   额度: 无限（或按需设置）
   允许模型: 全部

   创建后会生成一个 sk-xxx 的统一 Key
   这就是你唯一需要记住的 Key！

4. 测试
   ─────────────────────────────────
   curl https://api.enlyai.com/v1/chat/completions \
     -H "Authorization: Bearer sk-你的统一Token" \
     -H "Content-Type: application/json" \
     -d '{"model":"kimi-k2.5","messages":[{"role":"user","content":"Hello"}]}'
============================================
KEY_GUIDE

echo ""
info "部署完成！"
info "管理后台: https://api.enlyai.com"
info "API 端点: https://api.enlyai.com/v1/chat/completions"
