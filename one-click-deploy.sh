#!/bin/bash
# ============================================
# API.ENLYAI.COM 一键部署脚本
# 在阿里云 ECS 上通过 Workbench 执行
# ============================================

set -e

echo "============================================"
echo "  API.ENLYAI.COM - New API 一键部署"
echo "============================================"

# 1. 安装 Docker
if ! command -v docker &> /dev/null; then
    echo "[1/6] 安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
else
    echo "[1/6] Docker 已安装: $(docker --version)"
fi

# 2. 克隆 New API
if [ ! -d "/root/new-api" ]; then
    echo "[2/6] 克隆 New API..."
    git clone https://github.com/QuantumNous/new-api.git /root/new-api
else
    echo "[2/6] New API 已存在"
fi
cd /root/new-api

# 3. 生成密码并配置
echo "[3/6] 配置环境..."
DB_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
SESSION_SECRET=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)

# 写入生产配置
cat > docker-compose.prod.yml <<'COMPOSEEOF'
services:
  new-api:
    image: calciumion/new-api:latest
    container_name: new-api
    restart: always
    command: --log-dir /app/logs
    ports:
      - "3000:3000"
    volumes:
      - ./data:/data
      - ./logs:/app/logs
    environment:
      - SQL_DSN=postgresql://newapi:DBPASS@postgres:5432/newapi
      - REDIS_CONN_STRING=redis://:REDISPASS@redis:6379
      - TZ=Asia/Shanghai
      - ERROR_LOG_ENABLED=true
      - BATCH_UPDATE_ENABLED=true
      - MEMORY_CACHE_ENABLED=true
      - CHANNEL_UPDATE_FREQUENCY=30
      - SYNC_FREQUENCY=60
      - STREAMING_TIMEOUT=300
      - NODE_NAME=aliyun-ecs-node-1
      - SESSION_SECRET=SESSIONSECRET
      - AUTOMATIC_DISABLE_CHANNEL_ENABLED=true
      - AUTOMATIC_ENABLE_CHANNEL_ENABLED=false
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    networks:
      - new-api-network
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost:3000/api/status | grep -o '\"success\":\\s*true' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: always
    command: ["redis-server", "--requirepass", "REDISPASS", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
    volumes:
      - redis_data:/data
    networks:
      - new-api-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "REDISPASS", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: always
    environment:
      POSTGRES_USER: newapi
      POSTGRES_PASSWORD: DBPASS
      POSTGRES_DB: newapi
    volumes:
      - pg_data:/var/lib/postgresql/data
    networks:
      - new-api-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U newapi -d newapi"]
      interval: 10s
      timeout: 5s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/logs:/var/log/nginx
      - certbot-etc:/etc/letsencrypt
      - certbot-webroot:/var/www/certbot
    depends_on:
      - new-api
    networks:
      - new-api-network

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - certbot-webroot:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h; done'"
    networks:
      - new-api-network

volumes:
  pg_data:
  redis_data:
  certbot-etc:
  certbot-webroot:

networks:
  new-api-network:
    driver: bridge
COMPOSEEOF

sed -i "s/DBPASS/${DB_PASSWORD}/g" docker-compose.prod.yml
sed -i "s/REDISPASS/${REDIS_PASSWORD}/g" docker-compose.prod.yml
sed -i "s/SESSIONSECRET/${SESSION_SECRET}/g" docker-compose.prod.yml

# 保存密码
cat > /root/new-api/.env.production <<EOF
DB_PASSWORD=${DB_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
SESSION_SECRET=${SESSION_SECRET}
EOF
chmod 600 /root/new-api/.env.production

# 4. 配置 Nginx（HTTP 先启动，签证书后切换 HTTPS）
echo "[4/6] 配置 Nginx..."
mkdir -p nginx/conf.d nginx/logs nginx/certbot/webroot

cat > nginx/conf.d/default.conf <<'NGINXEOF'
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
NGINXEOF

# 5. 启动服务
echo "[5/6] 启动服务..."
mkdir -p data logs
docker compose -f docker-compose.prod.yml up -d
echo "等待服务启动..."
sleep 20
docker compose -f docker-compose.prod.yml ps

# 6. 签发 SSL 证书
echo "[6/6] 签发 SSL 证书..."
sleep 5
docker compose -f docker-compose.prod.yml run --rm certbot \
    certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "admin@enlyai.com" \
    --agree-tos \
    --no-eff-email \
    -d "api.enlyai.com" && \
SSL_SUCCESS=true || SSL_SUCCESS=false

if [ "$SSL_SUCCESS" = "true" ]; then
    echo "SSL 证书签发成功！切换到 HTTPS..."

    cat > nginx/conf.d/default.conf <<'NGINXHTTPS'
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
NGINXHTTPS

    docker compose -f docker-compose.prod.yml restart nginx
else
    echo "⚠️ SSL 证书签发失败（域名可能还没解析到本服务器）"
    echo "请确保 api.enlyai.com 已解析到 $(curl -s ifconfig.me 2>/dev/null || echo '本服务器IP')"
    echo "解析完成后重新执行: cd /root/new-api && ./setup-ssl.sh api.enlyai.com admin@enlyai.com"
fi

echo ""
echo "============================================"
echo "  部署完成！"
echo "============================================"
echo ""
echo "管理后台: http://114.215.183.45:3000"
echo "  (配置域名后: https://api.enlyai.com)"
echo ""
echo "默认账号: root / 123456"
echo "⚠️  请立即登录修改密码！"
echo ""
echo "密码已保存到: /root/new-api/.env.production"
echo ""
echo "下一步："
echo "  1. 登录管理后台修改密码"
echo "  2. 添加渠道 - 填入免费 API Key"
echo "  3. 创建令牌 - 生成统一对外 Key"
echo "  4. 配置域名 DNS 解析（如尚未配置）"
echo "============================================"
