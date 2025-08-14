#!/usr/bin/env bashio

CONFIG_PATH='/share/frpc.toml'
DEFAULT_CONFIG_PATH='/frpc.toml'

echo "RUN.SH START $(date)" >> /share/run.log

function prepare_config() {
    bashio::log.info "Copying configuration."
    cp $DEFAULT_CONFIG_PATH $CONFIG_PATH
    sed -i "s/serverAddr = \"your_server_addr\"/serverAddr = \"$(bashio::config 'serverAddr')\"/" $CONFIG_PATH
    sed -i "s/serverPort = 7000/serverPort = $(bashio::config 'serverPort')/" $CONFIG_PATH
    sed -i "s/auth.token = \"123456789\"/auth.token = \"$(bashio::config 'authToken')\"/" $CONFIG_PATH
    sed -i "s/webServer.port = 7500/webServer.port = $(bashio::config 'webServerPort')/" $CONFIG_PATH
    sed -i "s/webServer.user = \"admin\"/webServer.user = \"$(bashio::config 'webServerUser')\"/" $CONFIG_PATH
    sed -i "s/webServer.password = \"123456789\"/webServer.password = \"$(bashio::config 'webServerPassword')\"/" $CONFIG_PATH
    sed -i "s/customDomains = \[\"your_domain\"\]/customDomains = [\"$(bashio::config 'customDomain')\"]/" $CONFIG_PATH
    UNIQUE_NAME="homeassistant-$(date +%s)"
    sed -i "s/name = \"your_proxy_name\"/name = \"$UNIQUE_NAME\"/" $CONFIG_PATH
}

prepare_config

bashio::log.info "Starting frp client"
cat $CONFIG_PATH

# 使用 exec 替代后台运行
exec /usr/src/frpc -c $CONFIG_PATH
