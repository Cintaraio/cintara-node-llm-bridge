#!/bin/bash

# Cintara Node Configuration Analysis Script
# This script analyzes your Cintara node setup and exports findings to a report

REPORT_FILE="cintara_analysis_report.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "====================================="
echo "CINTARA NODE CONFIGURATION ANALYSIS"
echo "====================================="
echo "Generated at: $TIMESTAMP"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo ""

# Function to log and display
log_section() {
    echo "==================== $1 ====================" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

log_command() {
    echo "$ $1" | tee -a "$REPORT_FILE"
    eval "$1" 2>&1 | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

log_info() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# Start fresh report
echo "CINTARA NODE CONFIGURATION ANALYSIS REPORT" > "$REPORT_FILE"
echo "Generated at: $TIMESTAMP" >> "$REPORT_FILE"
echo "Hostname: $(hostname)" >> "$REPORT_FILE"
echo "User: $(whoami)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_section "1. SYSTEM OVERVIEW"
log_command "uname -a"
log_command "df -h"
log_command "free -m"

log_section "2. DOCKER ENVIRONMENT"
log_command "docker --version"
log_command "docker-compose --version"
log_command "docker ps -a"
log_command "docker images | grep -i cintara"
log_command "docker volume ls"
log_command "docker network ls"

log_section "3. RUNNING PROCESSES"
log_command "ps aux | grep -E '(cintara|tendermint|cosmos)' | grep -v grep"
log_command "netstat -tulpn | grep -E '(26657|1317|9090|8080)'"
log_command "ss -tulpn | grep -E '(26657|1317|9090|8080)'"

log_section "4. CINTARA NODE RPC TESTS"
log_info "Testing Cintara node connectivity and capabilities..."

log_command "curl -s http://localhost:26657/status | jq '.' || curl -s http://localhost:26657/status"
log_command "curl -s http://localhost:26657/net_info | jq '.result.n_peers' || curl -s http://localhost:26657/net_info"
log_command "curl -s http://localhost:26657/genesis | jq '.result.genesis.chain_id' || curl -s http://localhost:26657/genesis | head -20"

log_section "5. TRANSACTION INDEXING CAPABILITIES"
log_info "Testing transaction search and indexing..."

log_command "curl -s 'http://localhost:26657/tx_search?query=tx.height>1&per_page=1' | jq '.result.total_count' || curl -s 'http://localhost:26657/tx_search?query=tx.height>1&per_page=1'"

# Get latest block height for further tests
LATEST_HEIGHT=$(curl -s http://localhost:26657/status 2>/dev/null | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "unknown")
log_info "Latest block height: $LATEST_HEIGHT"

if [ "$LATEST_HEIGHT" != "unknown" ] && [ "$LATEST_HEIGHT" != "null" ]; then
    log_command "curl -s 'http://localhost:26657/block?height=$LATEST_HEIGHT' | jq '.result.block.data.txs | length' || curl -s 'http://localhost:26657/block?height=$LATEST_HEIGHT' | grep -o '\"txs\":\\[.*\\]' | wc -c"

    # Test recent blocks for transactions
    log_info "Scanning recent blocks for transactions..."
    for i in $(seq $((LATEST_HEIGHT-5)) $LATEST_HEIGHT 2>/dev/null); do
        if [ "$i" -gt 0 ]; then
            TX_COUNT=$(curl -s "http://localhost:26657/block?height=$i" 2>/dev/null | jq '.result.block.data.txs | length' 2>/dev/null || echo "0")
            echo "Block $i: $TX_COUNT transactions" | tee -a "$REPORT_FILE"
        fi
    done
fi

log_section "6. REST API TESTS"
log_info "Testing various REST API endpoints..."

log_command "curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq '.default_node_info.network' || curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info"
log_command "curl -s http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info | jq '.default_node_info.network' || curl -s http://localhost:8080/cosmos/base/tendermint/v1beta1/node_info"
log_command "curl -s http://localhost:3000/cosmos/base/tendermint/v1beta1/node_info | jq '.default_node_info.network' || curl -s http://localhost:3000/cosmos/base/tendermint/v1beta1/node_info"

log_section "7. CONFIGURATION FILES"
log_info "Searching for Cintara configuration files..."

# Look for config files
CONFIG_DIRS=$(find /home /root /opt /etc 2>/dev/null | grep -E "(cintara|\.cintara)" | head -10)
if [ -n "$CONFIG_DIRS" ]; then
    log_info "Found Cintara directories:"
    echo "$CONFIG_DIRS" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

# Look for specific config files
log_command "find /home /root /opt /etc 2>/dev/null | grep -E '(app\\.toml|config\\.toml|genesis\\.json)' | head -10"

log_section "8. DOCKER CONTAINER ANALYSIS"
log_info "Analyzing Docker containers for Cintara setup..."

# Get container IDs
CINTARA_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i cintara)
if [ -n "$CINTARA_CONTAINERS" ]; then
    log_info "Found Cintara containers: $CINTARA_CONTAINERS"

    for container in $CINTARA_CONTAINERS; do
        log_info "--- Analyzing container: $container ---"
        log_command "docker inspect $container | jq '.[] | {Image, Mounts, NetworkSettings}'"
        log_command "docker exec $container ls -la / 2>/dev/null || echo 'Cannot access container filesystem'"
        log_command "docker exec $container ls -la /home 2>/dev/null || echo 'No /home in container'"
        log_command "docker exec $container ls -la /data 2>/dev/null || echo 'No /data in container'"
        log_command "docker exec $container ls -la /.cintara 2>/dev/null || echo 'No .cintara in container'"
        log_command "docker exec $container find / -name '*.toml' 2>/dev/null | head -5 || echo 'No .toml files found'"
        log_command "docker exec $container find / -name '*.db' 2>/dev/null | head -5 || echo 'No .db files found'"
    done
else
    log_info "No Cintara containers found running"

    # Check all containers for potential Cintara data
    ALL_CONTAINERS=$(docker ps --format "{{.Names}}")
    if [ -n "$ALL_CONTAINERS" ]; then
        log_info "Checking all containers for Cintara data..."
        for container in $ALL_CONTAINERS; do
            log_info "--- Checking container: $container ---"
            log_command "docker exec $container find / -name '*cintara*' 2>/dev/null | head -3 || echo 'No cintara files in $container'"
        done
    fi
fi

log_section "9. ENVIRONMENT VARIABLES"
log_command "env | grep -E '(CINTARA|CHAIN|NODE|DB|POSTGRES)' || echo 'No relevant environment variables found'"

if [ -f "/home/ubuntu/cintara-node-llm-bridge/.env" ]; then
    log_info "Found .env file:"
    log_command "cat /home/ubuntu/cintara-node-llm-bridge/.env"
fi

log_section "10. FILESYSTEM SEARCH"
log_info "Searching filesystem for Cintara-related files..."

log_command "find /home/ubuntu 2>/dev/null | grep -i cintara | head -20"
log_command "find /opt 2>/dev/null | grep -i cintara | head -10"
log_command "find /var 2>/dev/null | grep -i cintara | head -10"

log_section "11. PORT ANALYSIS"
log_info "Checking what services are running on common blockchain ports..."

PORTS="26657 1317 9090 8080 3000 5432 8000"
for port in $PORTS; do
    SERVICE=$(ss -tulpn | grep ":$port " | head -1)
    if [ -n "$SERVICE" ]; then
        echo "Port $port: $SERVICE" | tee -a "$REPORT_FILE"
    else
        echo "Port $port: Not in use" | tee -a "$REPORT_FILE"
    fi
done

log_section "12. SAMPLE TRANSACTION DATA"
log_info "Attempting to retrieve sample transaction data..."

# Try to get a sample transaction
SAMPLE_TX=$(curl -s "http://localhost:26657/tx_search?query=tx.height>1&per_page=1" 2>/dev/null | jq -r '.result.txs[0].hash' 2>/dev/null)
if [ "$SAMPLE_TX" != "null" ] && [ -n "$SAMPLE_TX" ]; then
    log_info "Found sample transaction: $SAMPLE_TX"
    log_command "curl -s 'http://localhost:26657/tx?hash=$SAMPLE_TX' | jq '.result' || curl -s 'http://localhost:26657/tx?hash=$SAMPLE_TX'"
else
    log_info "No sample transactions found via tx_search"
fi

log_section "13. TAXBIT SERVICE TEST"
log_info "Testing current TaxBit service availability..."

log_command "curl -s http://localhost:8080/health || echo 'TaxBit service not responding'"
log_command "curl -s http://localhost:8080/taxbit/tokens || echo 'TaxBit tokens endpoint not responding'"

log_section "14. SUMMARY AND RECOMMENDATIONS"
log_info "Analysis complete. Key findings:"

if command -v jq >/dev/null; then
    NODE_RUNNING=$(curl -s http://localhost:26657/status 2>/dev/null | jq -r '.result.sync_info.catching_up' 2>/dev/null)
    if [ "$NODE_RUNNING" = "false" ]; then
        echo "✅ Cintara node is running and synced" | tee -a "$REPORT_FILE"
    elif [ "$NODE_RUNNING" = "true" ]; then
        echo "⚠️  Cintara node is running but still syncing" | tee -a "$REPORT_FILE"
    else
        echo "❌ Cintara node status unclear" | tee -a "$REPORT_FILE"
    fi
else
    echo "⚠️  jq not installed - install with: sudo apt-get install jq" | tee -a "$REPORT_FILE"
fi

BRIDGE_HEALTH=$(curl -s http://localhost:8080/health 2>/dev/null | grep -o "ok\|healthy" | head -1)
if [ -n "$BRIDGE_HEALTH" ]; then
    echo "✅ TaxBit bridge service is responding" | tee -a "$REPORT_FILE"
else
    echo "❌ TaxBit bridge service not responding" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "Please share this file for further analysis." | tee -a "$REPORT_FILE"

echo ""
echo "================================="
echo "ANALYSIS COMPLETE!"
echo "Report saved to: $REPORT_FILE"
echo "================================="
echo ""
echo "To share this report:"
echo "cat $REPORT_FILE"
echo ""
echo "Or copy the file to view elsewhere:"
echo "cp $REPORT_FILE ~/cintara_analysis_$(date +%Y%m%d_%H%M%S).txt"