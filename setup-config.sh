#!/bin/bash
# Cintara Node Configuration Setup
set -e

echo "🚀 Cintara Node Configuration Setup"
echo "===================================="
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [[ $overwrite != "y" ]]; then
        echo "Keeping existing .env file."
        echo "You can edit it manually or delete it and run this script again."
        exit 0
    fi
fi

echo "📋 Let's configure your Cintara node:"
echo ""

# Get node name
read -p "Enter your node name (e.g., my-awesome-node): " node_name
if [ -z "$node_name" ]; then
    node_name="cintara-node-$(date +%H%M%S)"
    echo "Using default: $node_name"
fi

# Get password
echo ""
echo "⚠️  IMPORTANT: Choose a strong password for your keyring!"
echo "This password will protect your node's keys and must be remembered."
while true; do
    read -s -p "Enter keyring password (min 8 chars): " password
    echo ""
    if [ ${#password} -lt 8 ]; then
        echo "❌ Password must be at least 8 characters long!"
        continue
    fi

    read -s -p "Confirm password: " password_confirm
    echo ""
    if [ "$password" != "$password_confirm" ]; then
        echo "❌ Passwords don't match! Please try again."
        continue
    fi

    break
done

# Ask about overwriting configs
echo ""
read -p "Overwrite existing configs if they exist? (y/n, default: y): " overwrite_configs
if [ -z "$overwrite_configs" ]; then
    overwrite_configs="y"
fi

# Create .env file
echo ""
echo "📝 Creating .env file..."
cat > .env << EOF
# Cintara Node Configuration
# Generated on $(date)

# Node Identity
MONIKER=$node_name
CHAIN_ID=cintara_11001-1

# Security
NODE_PASSWORD=$password

# Setup Options
OVERWRITE_CONFIG=$overwrite_configs
AUTO_START=true

# Build Options
BUILD_TIMESTAMP=
TARGET_ARCH=x86_64
EOF

echo "✅ Configuration saved to .env file!"
echo ""
echo "📋 Your node configuration:"
echo "  Node Name: $node_name"
echo "  Chain ID: cintara_11001-1"
echo "  Password: [PROTECTED - ${#password} characters]"
echo "  Overwrite Configs: $overwrite_configs"
echo ""
echo "🚀 Next steps:"
echo "1. Build the node: ./build-runtime-setup.sh"
echo "2. Start the node: docker-compose -f docker-compose.runtime-setup.yml up -d"
echo "3. Watch setup: docker-compose -f docker-compose.runtime-setup.yml logs -f"
echo ""
echo "⚠️  IMPORTANT: Save your password safely! You'll need it to access your node's keys."