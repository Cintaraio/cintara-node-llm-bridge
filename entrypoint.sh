#!/usr/bin/env bash
set -euo pipefail
MODE="${RUN_MODE:-start}"
HOME_DIR="${CINTARA_HOME:-/data/.tmp-cintarad}"

# Ensure /data directory has correct permissions when mounted as volume
if [ ! -w "/data" ]; then
  echo "[cintara] /data is not writable, attempting to fix permissions..."
  sudo chown -R cintara:cintara /data
fi

if [ "$MODE" = "init" ]; then
  echo "[cintara] Initializing node at $HOME_DIR"
  mkdir -p "$HOME_DIR"
  
  # Initialize cintara node configuration if not exists
  if [ ! -f "$HOME_DIR/config/config.toml" ]; then
    echo "[cintara] Creating initial configuration..."
    cintarad init "${MONIKER:-cintara-node}" --home "$HOME_DIR" --chain-id="${CHAIN_ID:-cintara_11001-1}" || echo "[cintara] Init command failed, continuing..."
  fi
  
  # Generate wallet and mnemonic if not exists
  if [ ! -f "$HOME_DIR/keyring-file/validator.info" ]; then
    echo "[cintara] Generating validator wallet and mnemonic..."
    echo "[cintara] ============================================="
    echo "[cintara]           IMPORTANT - SAVE THIS!"
    echo "[cintara] ============================================="
    
    # Generate new key with mnemonic output
    cintarad keys add validator --home "$HOME_DIR" --keyring-backend=file --output=json 2>/tmp/mnemonic.txt || true
    
    if [ -f /tmp/mnemonic.txt ]; then
      echo "[cintara] MNEMONIC PHRASE (SAVE THIS SECURELY):"
      echo "[cintara] ============================================="
      cat /tmp/mnemonic.txt
      echo ""
      echo "[cintara] ============================================="
      
      # Also save to persistent location
      cp /tmp/mnemonic.txt "$HOME_DIR/mnemonic.txt"
      chmod 600 "$HOME_DIR/mnemonic.txt"
    fi
    
    # Display wallet address
    echo "[cintara] Validator Address:"
    cintarad keys show validator -a --home "$HOME_DIR" --keyring-backend=file 2>/dev/null || echo "[cintara] Address generation failed"
    
    echo "[cintara] ============================================="
    echo "[cintara] WALLET SETUP COMPLETE"
    echo "[cintara] Mnemonic saved to: $HOME_DIR/mnemonic.txt"
    echo "[cintara] ============================================="
  fi
  
  # Display node information
  echo "[cintara] NODE INFORMATION:"
  echo "[cintara] Node ID: $(cintarad tendermint show-node-id --home "$HOME_DIR" 2>/dev/null || echo 'Not available')"
  echo "[cintara] Validator Address: $(cintarad keys show validator -a --home "$HOME_DIR" --keyring-backend=file 2>/dev/null || echo 'Not available')"
  echo "[cintara] Chain ID: ${CHAIN_ID:-cintara_11001-1}"
  echo "[cintara] Moniker: ${MONIKER:-cintara-node}"
  
  echo "[cintara] Init complete. Home at $HOME_DIR"
  sleep infinity
  exit 0
fi

echo "[cintara] Starting node with home at $HOME_DIR"
exec cintarad start --home "$HOME_DIR"