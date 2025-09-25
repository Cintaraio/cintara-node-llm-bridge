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

# Use the working public ECR image
docker run -d --name $TEMP_CONTAINER \
    -v cintara_preconfig_data:/data \
    public.ecr.aws/b8j2u1c6/cintaraio/cintara-node-runtime:latest \
    tail -f /dev/null

echo "📋 Container created. Now generating configuration with expect automation..."

# Run the setup inside the container using expect
docker exec -it $TEMP_CONTAINER bash -c '
cd /home/cintara/cintara-testnet-script

# Install expect inside container
apt-get update && apt-get install -y expect

# Run setup with expect
/usr/bin/expect << "EOF"
set timeout 300
spawn ./cintara_ubuntu_node.sh

expect {
    "Enter the Name for the node:" {
        send "cintara-preconfigured-node\r"
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
    eof {
        puts "Setup completed successfully"
    }
    timeout {
        puts "Setup timed out"
        exit 1
    }
}
EOF

echo "Configuration generated successfully!"
'

# Extract the generated configuration files
echo "📂 Extracting generated configuration files..."

mkdir -p preconfig/
docker cp $TEMP_CONTAINER:/data/.tmp-cintarad/config/ preconfig/

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