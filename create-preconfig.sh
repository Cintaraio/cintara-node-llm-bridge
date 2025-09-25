#!/bin/bash
# Create Pre-configured Node Setup for SecretNetwork
set -e

echo "🔧 Creating Pre-configured Node Setup for SecretNetwork"
echo "======================================================"

# Create temporary container to generate configuration
echo "📦 Creating temporary container for configuration generation..."

TEMP_CONTAINER="temp-cintara-config"

# Remove existing temp container if it exists
docker rm -f $TEMP_CONTAINER 2>/dev/null || true

# Run container interactively to generate configuration
echo "🚀 Running interactive setup to generate validator configuration..."

# Use a simple ubuntu image with our local setup scripts
docker run -d --name $TEMP_CONTAINER \
    -v cintara_preconfig_data:/data \
    -v $(pwd)/cintara-testnet-scripts:/home/cintara/cintara-testnet-script \
    ubuntu:22.04 \
    tail -f /dev/null

echo "📋 Container created. Now generating configuration with expect automation..."

# Run the setup inside the container using expect
docker exec -it $TEMP_CONTAINER bash -c '
cd /home/cintara/cintara-testnet-script

# Install dependencies inside container
apt-get update && apt-get install -y expect wget curl jq build-essential

# Run setup with expect - handle all prompts
/usr/bin/expect << "EOF"
set timeout 600
spawn ./cintara_ubuntu_node.sh

expect {
    "Enter the Name for the node:" {
        send "cintara-preconfigured-node\r"
        exp_continue
    }
    "Overwrite the existing configuration and start a new local node? \[y/n\]" {
        send "y\r"
        exp_continue
    }
    "Enter keyring passphrase" {
        send "PreConfigPassword123!\r"
        exp_continue
    }
    "Re-enter keyring passphrase" {
        send "PreConfigPassword123!\r"
        exp_continue
    }
    -re ".*password.*:" {
        send "PreConfigPassword123!\r"
        exp_continue
    }
    "File at" {
        puts "Genesis file created successfully"
        exp_continue
    }
    eof {
        puts "Setup completed successfully"
    }
    timeout {
        puts "Setup timed out - but may have partially completed"
    }
}
EOF

echo "Configuration generated successfully!"
'

# Check if configuration was actually created
echo "🔍 Checking if configuration was created..."
if docker exec $TEMP_CONTAINER [ -f "/data/.tmp-cintarad/config/genesis.json" ]; then
    echo "✅ Configuration files found"
else
    echo "❌ Configuration files not found - setup may have failed"
    echo "📋 Container logs:"
    docker logs $TEMP_CONTAINER --tail 20
    exit 1
fi

# Extract the generated configuration files
echo "📂 Extracting generated configuration files..."

mkdir -p preconfig/
docker cp $TEMP_CONTAINER:/data/.tmp-cintarad/config/ preconfig/

# Try to copy data directory (may not exist if setup incomplete)
if docker exec $TEMP_CONTAINER [ -d "/data/.tmp-cintarad/data" ]; then
    echo "📂 Copying data directory..."
    docker cp $TEMP_CONTAINER:/data/.tmp-cintarad/data/ preconfig/
else
    echo "⚠️ Data directory not found, creating minimal data setup..."
    mkdir -p preconfig/data
    echo '{"height":"0","round":0,"step":0}' > preconfig/data/priv_validator_state.json
fi

echo "🔍 Verifying generated configuration..."

# Check if genesis has validator
VALIDATOR_COUNT=$(cat preconfig/config/genesis.json | jq '.app_state.genutil.gen_txs | length')
echo "✅ Genesis file has $VALIDATOR_COUNT validator(s)"

if [ "$VALIDATOR_COUNT" -gt 0 ]; then
    echo "✅ Pre-configuration successful!"
    echo ""
    echo "📋 Generated files:"
    ls -la preconfig/config/
    echo ""
    echo "🎯 Next steps:"
    echo "1. These files will be included in the ECR image"
    echo "2. SecretNetwork will use pre-configured setup (no interaction needed)"
    echo "3. Node should start immediately with validator"
else
    echo "❌ Pre-configuration failed - no validators in genesis"
    exit 1
fi

# Clean up temp container
echo "🧹 Cleaning up temporary container..."
docker rm -f $TEMP_CONTAINER

echo ""
echo "✅ Pre-configuration complete!"
echo "Configuration saved in: ./preconfig/config/"