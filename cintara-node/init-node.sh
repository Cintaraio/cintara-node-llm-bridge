#!/bin/bash

set -e

echo "🚀 Starting Cintara Node Initialization (Official Script Method)"
echo "================================================================"

# Set environment variables
export HOME="/home/cintara"
export CHAIN_ID=${CHAIN_ID:-"cintara_11001-1"}
export MONIKER=${MONIKER:-"cintara-docker-node"}
export DATA_DIR="/home/cintara/data"

echo "Chain ID: $CHAIN_ID"
echo "Moniker: $MONIKER"
echo "Data Directory: $DATA_DIR"
echo "User: $(whoami)"
echo ""

# Change to the testnet script directory
cd /home/cintara/cintara-testnet-script

# Check if the node is already initialized
if [ ! -f "$DATA_DIR/.tmp-cintarad/config/genesis.json" ]; then
    echo "📦 Running official Cintara node setup script..."
    echo "⚠️  This will run the official cintara_ubuntu_node.sh script"
    echo ""

    # Create a non-interactive setup by providing default responses
    # The script expects user input, so we'll provide automated responses
    echo "🔧 Setting up automated responses for the setup script..."

    # Run the official setup script with automated inputs
    echo -e "$MONIKER\npassword123\ny\n" | ./cintara_ubuntu_node.sh || {
        echo "❌ Official setup script failed. Trying alternative approach..."

        # Alternative: Try to run setup manually step by step
        echo "🔄 Attempting manual setup based on official script..."

        # Make sure we have the required permissions
        chmod +x cintara_ubuntu_node.sh

        # Create data directory structure
        mkdir -p "$DATA_DIR/.tmp-cintarad"

        echo "✅ Basic directory structure created"
        echo "⚠️  Manual initialization required - container will stay running"
        echo ""
        echo "To complete setup, run:"
        echo "  docker exec -it cintara-blockchain-node bash"
        echo "  cd /home/cintara/cintara-testnet-script"
        echo "  ./cintara_ubuntu_node.sh"
        echo ""
    }
else
    echo "♻️ Node already initialized, skipping setup..."
fi

# Check if cintarad binary is available
if command -v cintarad &> /dev/null; then
    echo "✅ cintarad binary found"

    # Start the node if it's properly initialized
    if [ -f "$DATA_DIR/.tmp-cintarad/config/genesis.json" ]; then
        echo "🎯 Starting Cintara node..."
        echo "RPC endpoint will be available at: http://localhost:26657"
        echo "API endpoint will be available at: http://localhost:1317"
        echo ""

        # Start the node (this will run in foreground)
        exec cintarad start --home "$DATA_DIR/.tmp-cintarad" \
            --rpc.laddr tcp://0.0.0.0:26657 \
            --grpc.address 0.0.0.0:9090 \
            --api.address tcp://0.0.0.0:1317 \
            --api.enable true
    else
        echo "⚠️  Node not fully initialized. Starting interactive shell..."
        echo "To complete setup manually:"
        echo "  cd /home/cintara/cintara-testnet-script"
        echo "  ./cintara_ubuntu_node.sh"
        echo "  Then start with: cintarad start --home $DATA_DIR/.tmp-cintarad"
        echo ""

        # Keep container running with bash shell
        exec /bin/bash
    fi
else
    echo "⚠️  cintarad binary not found. Running setup first..."
    echo "Starting interactive shell for manual setup."
    echo ""
    echo "To setup manually:"
    echo "  cd /home/cintara/cintara-testnet-script"
    echo "  ./cintara_ubuntu_node.sh"
    echo ""

    # Keep container running
    exec /bin/bash
fi