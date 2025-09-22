#!/bin/bash

set -e

echo "🚀 Starting Automated Cintara Node Setup"
echo "========================================"

# Pre-configured values (can be overridden by environment variables)
export MONIKER=${MONIKER:-"cintara-automated-node"}
export CHAIN_ID=${CHAIN_ID:-"cintara_11001-1"}
export OVERWRITE_CONFIG=${OVERWRITE_CONFIG:-"y"}
export AUTO_START=${AUTO_START:-"true"}

echo "Configuration:"
echo "  Moniker: $MONIKER"
echo "  Chain ID: $CHAIN_ID"
echo "  Overwrite existing config: $OVERWRITE_CONFIG"
echo "  Auto start: $AUTO_START"
echo ""

# Ensure proper directory permissions
sudo mkdir -p /data
sudo chown cintara:cintara /data
sudo chmod 755 /data

mkdir -p /home/cintara/data
chown -R cintara:cintara /home/cintara/data

# Change to the testnet script directory
cd /home/cintara/cintara-testnet-script

# Download the official setup script if not exists
if [ ! -f "cintara_ubuntu_node.sh" ]; then
    echo "📥 Downloading setup script..."
    git pull origin main || echo "Using existing repository"
fi

# Make script executable
chmod +x cintara_ubuntu_node.sh

echo "🔧 Running automated setup..."

# Create expect script for automation
cat > /tmp/automated_setup.exp << 'EOF'
#!/usr/bin/expect -f

set timeout 600
set moniker [lindex $argv 0]
set overwrite [lindex $argv 1]

spawn ./cintara_ubuntu_node.sh

# Wait for moniker prompt
expect {
    "Enter the Name for the node:" {
        send "$moniker\r"
        exp_continue
    }
    "Overwrite the existing configuration and start a new local node? \[y/n\]" {
        send "$overwrite\r"
        exp_continue
    }
    eof {
        puts "Setup completed"
    }
    timeout {
        puts "Setup timed out"
        exit 1
    }
}

wait
EOF

chmod +x /tmp/automated_setup.exp

# Alternative: Use printf piping method (more reliable than expect)
echo "📦 Attempting automated setup using input redirection..."

# Method 1: Use printf to provide all inputs
printf "%s\n%s\n" "$MONIKER" "$OVERWRITE_CONFIG" | timeout 600 ./cintara_ubuntu_node.sh || {
    echo "⚠️  Method 1 failed, trying alternative approaches..."

    # Method 2: Use expect if available
    if command -v expect >/dev/null 2>&1; then
        echo "🔧 Using expect for automated input..."
        expect /tmp/automated_setup.exp "$MONIKER" "$OVERWRITE_CONFIG" || echo "Expect method failed"
    fi

    # Method 3: Use heredoc
    timeout 600 ./cintara_ubuntu_node.sh << EOF || echo "Heredoc method failed"
$MONIKER
$OVERWRITE_CONFIG
EOF
}

# Verify setup success
if [ -f "/data/.tmp-cintarad/config/genesis.json" ] && command -v cintarad >/dev/null 2>&1; then
    echo "✅ Automated setup completed successfully!"

    # Verify the binary works
    cintarad version

    echo "🎯 Node is ready to start"
    echo "Configuration located at: /data/.tmp-cintarad"

    if [ "$AUTO_START" = "true" ]; then
        echo "🚀 Starting Cintara node..."
        exec cintarad start --home /data/.tmp-cintarad \
            --rpc.laddr tcp://0.0.0.0:26657 \
            --grpc.address 0.0.0.0:9090 \
            --api.address tcp://0.0.0.0:1317 \
            --api.enable true \
            --log_level info
    else
        echo "ℹ️  Auto-start disabled. To start manually:"
        echo "   cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657"
    fi
else
    echo "❌ Automated setup failed!"
    echo "📋 Available files:"
    ls -la /data/ || echo "No /data directory"
    ls -la /data/.tmp-cintarad/ || echo "No cintara config directory"

    echo ""
    echo "🔧 Manual setup required. Run:"
    echo "   cd /home/cintara/cintara-testnet-script"
    echo "   ./cintara_ubuntu_node.sh"
    echo ""
    echo "   When prompted:"
    echo "   1. Node name: $MONIKER"
    echo "   2. Overwrite config: $OVERWRITE_CONFIG"

    # Keep container running for manual intervention
    echo "🐚 Starting interactive shell for troubleshooting..."
    exec /bin/bash
fi