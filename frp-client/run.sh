#!/usr/bin/env bashio

CONFIG_PATH='/share/frpc.toml'
DEFAULT_CONFIG_PATH='/frpc.toml'
FRPC_BIN='/usr/src/frpc'
LOCK_FILE='/tmp/frpc.lock'

bashio::log.info "RUN.SH START $(date)"

# 停掉旧的 FRPC
if pgrep -f "frpc -c" >/dev/null; then
    bashio::log.info "Stopping existing FRPC..."
    pkill -TERM -f "frpc -c"
    # 等待退出
    for i in {1..10}; do
        if ! pgrep -f "frpc -c" >/dev/null; then
            bashio::log.info "FRPC stopped"
            break
        fi
        sleep 1
    done
    # 如果还没退出，直接 kill -9
    if pgrep -f "frpc -c" >/dev/null; then
        bashio::log.warning "Force killing FRPC"
        pkill -9 -f "frpc -c"
    fi
fi

# 如果是 watchdog 或 restart 触发，给系统一点缓冲时间
if [[ "${1:-}" == "restart" ]]; then
    bashio::log.info "Restart detected, waiting extra 5s to avoid goroutine overlap..."
    sleep 5
fi

# 生成配置文件
function prepare_config() {
    bashio::log.info "Copying configuration..."
    cp "$DEFAULT_CONFIG_PATH" "$CONFIG_PATH"
    sed -i "s/serverAddr = \"your_server_addr\"/serverAddr = \"$(bashio::config 'serverAddr')\"/" "$CONFIG_PATH"
    sed -i "s/serverPort = 7000/serverPort = $(bashio::config 'serverPort')/" "$CONFIG_PATH"
    sed -i "s/auth.token = \"123456789\"/auth.token = \"$(bashio::config 'authToken')\"/" "$CONFIG_PATH"
    sed -i "s/webServer.port = 7500/webServer.port = $(bashio::config 'webServerPort')/" "$CONFIG_PATH"
    sed -i "s/webServer.user = \"admin\"/webServer.user = \"$(bashio::config 'webServerUser')\"/" "$CONFIG_PATH"
    sed -i "s/webServer.password = \"123456789\"/webServer.password = \"$(bashio::config 'webServerPassword')\"/" "$CONFIG_PATH"
    sed -i "s/customDomains = \[\"your_domain\"\]/customDomains = [\"$(bashio::config 'customDomain')\"]/" "$CONFIG_PATH"
    UNIQUE_NAME="homeassistant-$(date +%s)"
    sed -i "s/name = \"your_proxy_name\"/name = \"$UNIQUE_NAME\"/" "$CONFIG_PATH"
}

prepare_config

bashio::log.info "Starting frp client with config:"
cat "$CONFIG_PATH"

# 自动重试逻辑
while true; do
    "$FRPC_BIN" -c "$CONFIG_PATH"
    EXIT_CODE=$?
    bashio::log.warning "frpc exited with code $EXIT_CODE, retrying in 10 seconds..."
    sleep 10
done

# 清理锁文件（理论上不会执行，除非退出循环）
rm -f "$LOCK_FILE"
