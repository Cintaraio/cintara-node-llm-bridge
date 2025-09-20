#!/bin/bash

set -e

# Set environment variables
export PATH="/root/go/bin:/usr/local/go/bin:${PATH}"
CHAIN_ID=${CHAIN_ID:-"cintara_11001-1"}
MONIKER=${MONIKER:-"cintara-docker-node"}
KEYRING_BACKEND=${KEYRING_BACKEND:-"test"}
NODE_HOME="/root/.cintarad"

echo "🚀 Starting Cintara node initialization..."
echo "Chain ID: $CHAIN_ID"
echo "Moniker: $MONIKER"
echo "Node Home: $NODE_HOME"

# Check if node is already initialized
if [ ! -f "$NODE_HOME/config/genesis.json" ]; then
    echo "📦 Initializing new Cintara node..."

    # Initialize the node
    cintarad init "$MONIKER" --chain-id "$CHAIN_ID" --home "$NODE_HOME"

    # Download genesis file
    echo "⬇️ Downloading genesis file..."
    curl -s https://raw.githubusercontent.com/Cintaraio/cintara-testnet-script/main/genesis.json > "$NODE_HOME/config/genesis.json"

    # Set up persistent peers
    echo "🌐 Configuring peers..."
    PERSISTENT_PEERS="d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:26656,8542cd7e6bf9d260fef543bc49e59be5a3fa9074@seed.publicnode.com:26656"
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PERSISTENT_PEERS\"/" "$NODE_HOME/config/config.toml"

    # Configure API and RPC
    sed -i.bak -e "s/^enable *=.*/enable = true/" "$NODE_HOME/config/app.toml"
    sed -i.bak -e "s/^address *= .*/address = \"tcp:\/\/0.0.0.0:1317\"/" "$NODE_HOME/config/app.toml"
    sed -i.bak -e "s/^laddr *= .*/laddr = \"tcp:\/\/0.0.0.0:26657\"/" "$NODE_HOME/config/config.toml"

    # Set minimum gas price
    sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0cint\"/" "$NODE_HOME/config/app.toml"

    # Configure pruning (optional, for disk space)
    sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" "$NODE_HOME/config/app.toml"
    sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" "$NODE_HOME/config/app.toml"
    sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" "$NODE_HOME/config/app.toml"

    # Create a validator key (for testing)
    if [ ! -f "$NODE_HOME/config/priv_validator_key.json" ]; then
        echo "🔑 Creating validator key..."
        cintarad keys add validator --keyring-backend "$KEYRING_BACKEND" --home "$NODE_HOME" --output json > /tmp/validator_key.json 2>&1 || true

        # Show the mnemonic for backup
        if [ -f /tmp/validator_key.json ]; then
            echo "🔐 IMPORTANT: Save this mnemonic phrase for your validator:"
            echo "=============================================="
            cat /tmp/validator_key.json | jq -r '.mnemonic // empty'
            echo "=============================================="
            rm -f /tmp/validator_key.json
        fi
    fi

    echo "✅ Node initialization completed!"
else
    echo "♻️ Node already initialized, skipping initialization..."
fi

# Start the node
echo "🎯 Starting Cintara node..."
echo "RPC endpoint will be available at: http://localhost:26657"
echo "API endpoint will be available at: http://localhost:1317"

exec cintarad start --home "$NODE_HOME" \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --grpc.address 0.0.0.0:9090 \
    --api.address tcp://0.0.0.0:1317 \
    --api.enable true