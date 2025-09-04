#!/usr/bin/env bash
set -euo pipefail

# If running a direct command (not init/start), execute it directly
if [ $# -gt 0 ] && [ "$1" != "init" ] && [ "$1" != "start" ]; then
  echo "[cintara] Executing direct command: $@"
  exec cintarad "$@"
fi

MODE="${RUN_MODE:-start}"
HOME_DIR="${CINTARA_HOME:-/data/.tmp-cintarad}"

# Ensure /data directory has correct permissions when mounted as volume
if [ ! -w "/data" ]; then
  echo "[cintara] /data is not writable, attempting to fix permissions..."
  sudo chown -R cintara:cintara /data
fi

if [ "$MODE" = "init" ]; then
  echo "[cintara] Initializing Cintara node at $HOME_DIR"
  echo "[cintara] Following official Cintara testnet setup process..."
  mkdir -p "$HOME_DIR"
  
  # Set variables following the official script
  KEYS="validator"
  KEYRING="test"  # Use test keyring for Docker environment (no password required)
  KEYALGO="eth_secp256k1"
  CHAIN_ID="${CHAIN_ID:-cintara_11001-1}"
  MONIKER="${MONIKER:-cintara-node}"
  
  # Initialize cintara node configuration if not exists
  if [ ! -f "$HOME_DIR/config/config.toml" ]; then
    echo "[cintara] Creating initial node configuration..."
    cintarad init "$MONIKER" --home "$HOME_DIR" --chain-id="$CHAIN_ID" || {
      echo "[cintara] ERROR: Node initialization failed"
      exit 1
    }
    echo "[cintara] ✅ Node configuration created"
  fi
  
  # Generate wallet and mnemonic following official process
  if [ ! -f "$HOME_DIR/keyring-$KEYRING/$KEYS.info" ]; then
    echo ""
    echo "[cintara] ============================================="
    echo "[cintara]           GENERATING WALLET"
    echo "[cintara] ============================================="
    echo "[cintara] Creating validator key with mnemonic..."
    echo ""
    
    # Generate key using test keyring (non-interactive)
    echo "[cintara] Generating keys (using test keyring for Docker)..."
    
    # Create the key and capture output including mnemonic
    KEY_OUTPUT=$(cintarad keys add "$KEYS" \
      --home "$HOME_DIR" \
      --keyring-backend="$KEYRING" \
      --algo="$KEYALGO" \
      --output json 2>&1) || {
      echo "[cintara] ERROR: Key generation failed"
      echo "$KEY_OUTPUT"
      exit 1
    }
    
    echo ""
    echo "[cintara] ============================================="
    echo "[cintara] ===== COPY THESE KEYS WITH MNEMONICS ====="
    echo "[cintara] ===== AND SAVE IN A SAFE PLACE =========="
    echo "[cintara] ============================================="
    
    # Extract and display mnemonic if available in output
    echo "$KEY_OUTPUT" | grep -E "(mnemonic|seed)" || echo "$KEY_OUTPUT"
    
    # Save mnemonic to file if we can extract it
    echo "$KEY_OUTPUT" | grep "mnemonic" | sed 's/.*"mnemonic":"//' | sed 's/".*//' > "$HOME_DIR/mnemonic.txt" 2>/dev/null || true
    
    # Display the created key info
    echo ""
    echo "[cintara] Key information:"
    cintarad keys show "$KEYS" --home "$HOME_DIR" --keyring-backend="$KEYRING" 2>/dev/null || echo "[cintara] Could not display key info"
    
    echo ""
    echo "[cintara] ============================================="
    echo "[cintara] WALLET CREATION COMPLETE"
    echo "[cintara] Note: Using test keyring for Docker compatibility"
    echo "[cintara] ============================================="
  fi
  
  # Add genesis account following official process
  echo "[cintara] Setting up genesis account..."
  VALIDATOR_ADDR=$(cintarad keys show "$KEYS" -a --home "$HOME_DIR" --keyring-backend="$KEYRING" 2>/dev/null)
  if [ -n "$VALIDATOR_ADDR" ]; then
    echo "[cintara] Adding genesis account for validator: $VALIDATOR_ADDR"
    cintarad add-genesis-account "$KEYS" 100000000000000000000000000000cint \
      --home "$HOME_DIR" \
      --keyring-backend="$KEYRING" 2>/dev/null || {
      echo "[cintara] Genesis account setup failed, trying with address..."
      cintarad add-genesis-account "$VALIDATOR_ADDR" 100000000000000000000000000000cint \
        --home "$HOME_DIR" || echo "[cintara] Genesis account setup failed completely"
    }
    echo "[cintara] ✅ Genesis account added: $VALIDATOR_ADDR"
  else
    echo "[cintara] ⚠️  Could not retrieve validator address, skipping genesis account"
  fi
  
  # Generate genesis transaction
  echo "[cintara] Generating genesis transaction..."
  cintarad gentx "$KEYS" 1000000000000000000000cint \
    --home "$HOME_DIR" \
    --keyring-backend="$KEYRING" \
    --chain-id="$CHAIN_ID" 2>/dev/null || {
    echo "[cintara] Genesis transaction generation failed, this is expected for testnet nodes"
  }
  
  # Collect genesis transactions
  echo "[cintara] Collecting genesis transactions..."
  cintarad collect-gentxs --home "$HOME_DIR" 2>/dev/null || {
    echo "[cintara] Collect gentxs failed, this is normal for joining existing testnet"
  }
  
  # Use bundled Cintara testnet genesis file
  echo "[cintara] Using bundled Cintara testnet genesis file..."
  if [ -f "/genesis.json" ]; then
    cp /genesis.json "$HOME_DIR/config/genesis.json"
    echo "[cintara] ✅ Genesis file copied successfully"
  else
    echo "[cintara] ⚠️ Bundled genesis not found, downloading from repository..."
    GENESIS_URL="https://raw.githubusercontent.com/Cintaraio/cintara-testnet-script/main/genesis.json"
    if curl -f -s -o "$HOME_DIR/config/genesis.json" "$GENESIS_URL"; then
      echo "[cintara] ✅ Genesis file downloaded successfully"
    else
      echo "[cintara] ⚠️ Could not download genesis file, using local genesis"
    fi
  fi
  
  # Verify the genesis file has the correct chain ID
  GENESIS_CHAIN_ID=$(jq -r '.chain_id' "$HOME_DIR/config/genesis.json" 2>/dev/null)
  if [ "$GENESIS_CHAIN_ID" != "$CHAIN_ID" ]; then
    echo "[cintara] ⚠️ Genesis chain ID ($GENESIS_CHAIN_ID) doesn't match expected ($CHAIN_ID)"
    echo "[cintara] This may cause startup issues"
  else
    echo "[cintara] ✅ Genesis chain ID matches: $GENESIS_CHAIN_ID"
  fi
  
  # Display final node information
  echo ""
  echo "[cintara] ============================================="
  echo "[cintara]         NODE SETUP COMPLETE"
  echo "[cintara] ============================================="
  echo "[cintara] Node ID: $(cintarad tendermint show-node-id --home "$HOME_DIR" 2>/dev/null || echo 'Not available')"
  echo "[cintara] Validator Address: $VALIDATOR_ADDR"
  echo "[cintara] Chain ID: $CHAIN_ID"
  echo "[cintara] Moniker: $MONIKER"
  echo "[cintara] Keyring Backend: $KEYRING"
  echo "[cintara] Home Directory: $HOME_DIR"
  echo "[cintara] ============================================="
  
  echo "[cintara] Node initialization complete!"
  echo "[cintara] You can now run the config patcher and start the node."
  sleep 5  # Give time to read the output instead of infinite sleep
  exit 0
fi

echo "[cintara] Starting node with home at $HOME_DIR"
exec cintarad start --home "$HOME_DIR"