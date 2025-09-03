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

echo "[patcher] Configuration patched successfully"