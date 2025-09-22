#!/bin/bash

echo "🔍 Searching for Cintara LevelDB databases..."
echo "================================================"

# Function to check if path exists and has data
check_db_path() {
    local path="$1"
    local name="$2"

    if [ -d "$path" ]; then
        local size=$(du -sh "$path" 2>/dev/null | cut -f1)
        local files=$(ls -la "$path" 2>/dev/null | wc -l)
        echo "✅ FOUND: $name"
        echo "   Path: $path"
        echo "   Size: $size"
        echo "   Files: $files"
        echo "   Content: $(ls -la "$path" | head -3 | tail -2)"
        echo ""
        return 0
    else
        echo "❌ NOT FOUND: $name ($path)"
        return 1
    fi
}

# Check common locations
echo "Checking common Cintara database locations:"
echo ""

check_db_path "/data/.tmp-cintarad/data" "Official tmp path"
check_db_path "/home/ubuntu/.cintarad/data" "Home directory"
check_db_path "/var/lib/cintara/data" "System directory"
check_db_path "/opt/cintara/data" "Opt directory"
check_db_path "$(pwd)/data" "Current directory"

# Search for any leveldb-like directories
echo "🔍 Searching entire system for LevelDB files..."
echo "==============================================="

# Find any directories with 'tx_index.db'
echo "Looking for tx_index.db:"
sudo find / -name "tx_index.db" -type d 2>/dev/null | while read path; do
    check_db_path "$path" "tx_index.db"
done

# Find any directories with 'data' and size > 100MB
echo "Looking for large 'data' directories (>100MB):"
sudo find / -name "data" -type d -exec du -sm {} \; 2>/dev/null | awk '$1 > 100' | while read size path; do
    check_db_path "$path" "Large data dir (${size}MB)"
done

# Check if Cintara node is running
echo "🔍 Checking Cintara node status..."
echo "================================="

if pgrep -f cintara >/dev/null; then
    echo "✅ Cintara process is running"
    echo "Process info:"
    ps aux | grep cintara | grep -v grep
    echo ""
else
    echo "❌ No Cintara process found"
fi

# Check node API
echo "Testing node API endpoints:"
if curl -s http://localhost:26657/status >/dev/null; then
    echo "✅ Node API accessible at localhost:26657"
    latest_height=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)
    echo "   Latest block: $latest_height"
else
    echo "❌ Node API not accessible"
fi

echo ""
echo "🎯 Summary:"
echo "=========="
echo "Run this script on your EC2 instance to find the actual LevelDB location."
echo "Then update the docker-compose.yml volumes section accordingly."