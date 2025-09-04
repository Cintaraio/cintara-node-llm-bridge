#!/bin/bash
set -e

echo "🚀 Starting Smart Cintara Node Setup..."

# Set up secure keyring password from environment or generate one
if [ -z "$KEYRING_PASSWORD" ]; then
    echo "⚠️  KEYRING_PASSWORD not set in environment. Generating secure password..."
    export KEYRING_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    echo "🔐 Generated keyring password: $KEYRING_PASSWORD"
    echo "💾 Save this password securely - you'll need it to access your wallet!"
else
    echo "🔐 Using keyring password from environment variable"
fi

# Validate password length (minimum 8 characters)
if [ ${#KEYRING_PASSWORD} -lt 8 ]; then
    echo "❌ Error: KEYRING_PASSWORD must be at least 8 characters long"
    echo "Current length: ${#KEYRING_PASSWORD}"
    exit 1
fi

# Ensure /data directory exists and has proper permissions
echo "📁 Setting up data directory permissions..."
sudo mkdir -p /data
sudo chown -R cintara:cintara /data
sudo chmod -R 755 /data

# Check if already initialized
if [ -f "/data/.tmp-cintarad/config/genesis.json" ]; then
    echo "✅ Node already initialized. Checking chain ID..."
    EXISTING_CHAIN_ID=$(jq -r '.chain_id' /data/.tmp-cintarad/config/genesis.json 2>/dev/null || echo "")
    if [ "$EXISTING_CHAIN_ID" = "${CHAIN_ID}" ]; then
        echo "✅ Node already configured for chain: $EXISTING_CHAIN_ID"
        exit 0
    else
        echo "⚠️  Chain ID mismatch. Reinitializing..."
        rm -rf /data/.tmp-cintarad
    fi
fi

cd /home/cintara/cintara-testnet-script

echo "📦 Making setup script executable..."
chmod +x cintara_ubuntu_node.sh

echo "🔧 Running automated Cintara node setup..."

# Set up environment for automated setup
export DEBIAN_FRONTEND=noninteractive
export HOME=/home/cintara

# Pre-configure timezone to prevent interactive prompts
sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime
echo 'UTC' | sudo tee /etc/timezone > /dev/null

# Create expect script for automated input
cat > /tmp/setup_expect.exp << EOF
#!/usr/bin/expect -f
set timeout 60
set moniker [lindex \$argv 0]
set keyring_password "$KEYRING_PASSWORD"

spawn ./cintara_ubuntu_node.sh

# Handle node name input (flexible pattern matching)
expect {
    "Enter the Name for the node:" {
        send "$moniker\r"
    }
    "Enter your node name:" {
        send "$moniker\r"
    }
    "node name" {
        send "$moniker\r"
    }
    timeout {
        puts "Timeout waiting for node name prompt"
        exit 1
    }
}

# Handle overwrite config prompt (this comes first if config exists)
expect {
    "overwrite" {
        send "y\r"
    }
    "Overwrite the existing configuration" {
        send "y\r"
    }
    "start a new local node?" {
        send "y\r"
    }
    "[y/n]" {
        send "y\r"
    }
    "Enter keyring passphrase:" {
        send "\$keyring_password\r"
        exp_continue
    }
    "Enter keyring passphrase (attempt" {
        send "\$keyring_password\r"
        exp_continue
    }
    timeout {
        puts "Continuing to keyring prompts..."
    }
}

# Handle keyring password (use secure password from environment)
expect {
    "Enter keyring passphrase:" {
        send "\$keyring_password\r"
    }
    "Enter keyring passphrase (attempt" {
        send "\$keyring_password\r"
    }
    "keyring passphrase" {
        send "\$keyring_password\r"
    }
    timeout {
        puts "Timeout waiting for keyring passphrase prompt"
    }
}

expect {
    "Re-enter keyring passphrase:" {
        send "\$keyring_password\r"
    }
    "Re-enter keyring passphrase (attempt" {
        send "\$keyring_password\r"
    }
    "re-enter" {
        send "\$keyring_password\r"
    }
    "Re-enter" {
        send "\$keyring_password\r"
    }
    timeout {
        puts "Timeout waiting for re-enter passphrase prompt"
    }
}

# Wait for completion
expect eof
EOF

# Install expect if not available
if ! command -v expect &> /dev/null; then
    # Pre-configure timezone to prevent prompts
    sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y expect
fi

chmod +x /tmp/setup_expect.exp

echo "🤖 Running automated setup with moniker: ${MONIKER}"

# Debug: Show current user and permissions
echo "🔍 Debug info:"
echo "   Current user: $(whoami)"
echo "   User ID: $(id -u)"
echo "   Group ID: $(id -g)"
echo "   /data permissions: $(ls -la /data 2>/dev/null || echo 'directory does not exist')"

/tmp/setup_expect.exp "${MONIKER}" || {
    echo "⚠️  Automated setup failed, trying manual setup..."
    
    # Fallback: Try environment variable approach
    export NODE_NAME="${MONIKER}"
    export AUTO_CONFIRM="y"
    
    # Fallback: Manual setup with more comprehensive input piping
    # Provides: node name, yes to overwrite, secure password, password confirmation, yes to any other prompts
    echo -e "${MONIKER}\ny\n${KEYRING_PASSWORD}\n${KEYRING_PASSWORD}\ny\ny\n" | timeout 300 ./cintara_ubuntu_node.sh || {
        echo "❌ Setup failed. Please run setup manually."
        echo "🔍 Final debug info:"
        echo "   /data contents: $(ls -la /data 2>/dev/null || echo 'no /data directory')"
        exit 1
    }
}

# Verify setup
if [ -f "/data/.tmp-cintarad/config/genesis.json" ]; then
    CHAIN_ID_CHECK=$(jq -r '.chain_id' /data/.tmp-cintarad/config/genesis.json)
    echo "✅ Setup completed successfully!"
    echo "   Chain ID: $CHAIN_ID_CHECK"
    echo "   Node directory: /data/.tmp-cintarad"
    
    # Display mnemonic if available
    if [ -f "/data/.tmp-cintarad/mnemonic.txt" ]; then
        echo "🔑 IMPORTANT: Save your mnemonic phrase:"
        echo "=============================================="
        cat /data/.tmp-cintarad/mnemonic.txt
        echo "=============================================="
        echo "⚠️  Store this mnemonic safely - you'll need it to restore your wallet!"
    fi
else
    echo "❌ Setup verification failed - genesis.json not found"
    exit 1
fi

echo "🎉 Smart Cintara Node setup complete! The node is ready to start."