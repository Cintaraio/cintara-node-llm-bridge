#!/bin/sh
set -e

CONF="$1"; PUBIP="$2"; RPC="$3"; P2P="$4"

echo "[patcher] Patching config file: $CONF"
echo "[patcher] Public IP: $PUBIP, RPC: $RPC, P2P: $P2P"

# Check if config file exists
if [ ! -f "$CONF" ]; then
    echo "[patcher] ERROR: Config file does not exist: $CONF"
    echo "[patcher] Make sure the init step completed successfully"
    exit 1
fi

# Backup original config
cp "$CONF" "$CONF.backup"

# Update RPC listen address
sed -i 's#^laddr = "tcp://127\.0\.0\.1:26657"#laddr = "tcp://0.0.0.0:'$RPC'"#g' "$CONF"

# Update P2P listen address  
sed -i 's#^laddr = "tcp://0\.0\.0\.0:26656"#laddr = "tcp://0.0.0.0:'$P2P'"#g' "$CONF"

# Update external address
if grep -q "^external_address" "$CONF"; then
    sed -i 's#^external_address = ""#external_address = "tcp://'$PUBIP':'$P2P'"#g' "$CONF"
else
    # Find the [p2p] section and add external_address after it
    sed -i '/^\[p2p\]/a external_address = "tcp://'$PUBIP':'$P2P'"' "$CONF"
fi

# Add persistent peers from official Cintara testnet script
echo "[patcher] Adding persistent peers from official testnet configuration..."
PERSISTENT_PEERS="556fb5330315d3f2b6169fe810a87d26376a42e7@35.155.113.160:26656,d827e98de74dc26aada3b0bb4f7e78fbf3de75dd@35.82.72.170:26656,19675c9f2711234238d10233b10cacbe5576be27@52.32.249.156:26656"

# Update persistent_peers setting
if grep -q "^persistent_peers" "$CONF"; then
    sed -i 's#^persistent_peers = ""#persistent_peers = "'$PERSISTENT_PEERS'"#g' "$CONF"
    sed -i 's#^persistent_peers = ".*"#persistent_peers = "'$PERSISTENT_PEERS'"#g' "$CONF"
else
    # Find the [p2p] section and add persistent_peers after external_address
    sed -i '/^external_address/a persistent_peers = "'$PERSISTENT_PEERS'"' "$CONF"
fi

echo "[patcher] Configuration patched successfully with persistent peers"