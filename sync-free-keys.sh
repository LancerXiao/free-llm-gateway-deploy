#!/bin/bash
# ============================================
# 自动从 GitHub 免费 API Key 仓库抓取 Key
# 并通过 New API 管理接口批量导入
# ============================================
#
# 使用方式:
#   chmod +x sync-free-keys.sh
#   ./sync-free-keys.sh
#
# 定时同步（crontab -e）:
#   0 */6 * * * /root/new-api/sync-free-keys.sh >> /var/log/sync-keys.log 2>&1

set -e

# ============ 配置 ============
NEW_API_BASE="${NEW_API_BASE:-http://localhost:3000}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"

# 免费 Key 仓库列表（按优先级排序）
KEY_SOURCES=(
    "https://raw.githubusercontent.com/alistaitsacle/free-llm-api-keys/main/README.md"
)

# 后端 Base URL（这些 Key 共用的上游 API）
BACKEND_BASE_URL="https://aiapiv2.pekpik.com/v1"

# 支持的模型列表
MODELS="kimi-k2.5,deepseek-v4-pro,deepseek-v4-flash,claude-opus-4-7,gemini-2.5-flash,smart-chat,qwen/qwen3.6-flash,openrouter/owl-alpha,gpt-4o,gpt-4o-mini,o3-mini"
# ============ 配置结束 ============

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

check_config() {
    if [ -z "$ADMIN_TOKEN" ]; then
        error "请设置 ADMIN_TOKEN 环境变量"
        echo "  export ADMIN_TOKEN=sk-xxx  # 在 New API 管理后台生成的管理员令牌"
        exit 1
    fi
}

api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            "${NEW_API_BASE}${endpoint}" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" \
            "${NEW_API_BASE}${endpoint}" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json"
    fi
}

# 从 GitHub 仓库抓取 Key
fetch_keys_from_source() {
    local url=$1
    info "从 $url 抓取 Key..."

    local content=$(curl -sL --connect-timeout 15 "$url" 2>/dev/null)

    if [ -z "$content" ]; then
        warn "无法获取内容: $url"
        return
    fi

    # 提取 sk- 开头的 Key
    local keys=$(echo "$content" | grep -oP 'sk-[a-zA-Z0-9_-]{10,}' | sort -u)

    if [ -z "$keys" ]; then
        warn "未找到 Key: $url"
        return
    fi

    local count=$(echo "$keys" | wc -l)
    info "发现 ${count} 个 Key"

    echo "$keys"
}

# 获取现有渠道列表（避免重复添加）
get_existing_channels() {
    local response=$(api_call GET "/api/channel/?p=0&page_size=200")
    echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('success'):
        for ch in data.get('data', []):
            print(ch.get('key', ''))
except: pass
" 2>/dev/null
}

# 添加 Key 到 New API
add_key_to_newapi() {
    local key=$1
    local key_suffix="${key: -8}"
    local channel_name="free-pool-${key_suffix}"

    local request_data="{\"name\":\"${channel_name}\",\"type\":1,\"key\":\"${key}\",\"models\":\"${MODELS}\",\"base_url\":\"${BACKEND_BASE_URL}\",\"group\":\"default\",\"priority\":0,\"weight\":1}"

    local response=$(api_call POST /api/channel/ "$request_data")
    local success=$(echo "$response" | grep -o '"success":true' || true)

    if [ -n "$success" ]; then
        info "  添加成功: ${channel_name}"
        return 0
    else
        warn "  添加失败: ${channel_name} - $(echo $response | head -c 150)"
        return 1
    fi
}

# 清理已失效的旧渠道
cleanup_disabled_channels() {
    info "清理已禁用的渠道..."

    local response=$(api_call GET "/api/channel/?p=0&page_size=200")
    local disabled_ids=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('success'):
        for ch in data.get('data', []):
            # 状态 3 = 自动禁用，且名称以 free-pool- 开头
            if ch.get('status') == 3 and ch.get('name', '').startswith('free-pool-'):
                print(ch['id'])
except: pass
" 2>/dev/null)

    for id in $disabled_ids; do
        api_call DELETE "/api/channel/${id}" > /dev/null
        info "  已删除失效渠道 #${id}"
    done
}

# 主流程
main() {
    echo "=========================================="
    info "[$(timestamp)] 开始同步免费 API Key"
    echo "=========================================="

    check_config

    # 1. 获取现有 Key（避免重复）
    existing_keys=$(get_existing_channels)
    info "现有渠道中的 Key 数: $(echo "$existing_keys" | grep -c 'sk-' || echo 0)"

    # 2. 从所有源抓取 Key
    all_keys=""
    for source in "${KEY_SOURCES[@]}"; do
        keys=$(fetch_keys_from_source "$source")
        if [ -n "$keys" ]; then
            all_keys="${all_keys}${keys}\n"
        fi
    done

    if [ -z "$all_keys" ]; then
        warn "未从任何源获取到 Key"
        exit 0
    fi

    # 3. 去重并添加
    unique_keys=$(echo -e "$all_keys" | sort -u | grep -v '^$')
    total=$(echo "$unique_keys" | wc -l)
    added=0
    skipped=0

    info "共 ${total} 个唯一 Key，开始导入..."

    while IFS= read -r key; do
        [ -z "$key" ] && continue

        # 检查是否已存在
        if echo "$existing_keys" | grep -q "$key"; then
            skipped=$((skipped + 1))
            continue
        fi

        if add_key_to_newapi "$key"; then
            added=$((added + 1))
        fi
    done <<< "$unique_keys"

    # 4. 清理失效渠道
    cleanup_disabled_channels

    echo ""
    info "同步完成: 新增 ${added}, 跳过 ${skipped}, 总计 ${total}"
    echo "=========================================="
}

main "$@"
