#!/bin/bash

echo "🚀 Manual Blockchain Node Setup Script"
echo "======================================="

# Check if running on Ubuntu
if [[ ! -f /etc/lsb-release ]] || ! grep -q "Ubuntu" /etc/lsb-release; then
    echo "❌ This script requires Ubuntu. Please run on Ubuntu 22.04."
    exit 1
fi

# Create blockchain node directory if it doesn't exist
BLOCKCHAIN_DIR="$HOME/blockchain-node"
if [ ! -d "$BLOCKCHAIN_DIR" ]; then
    echo "📁 Creating blockchain node directory at $BLOCKCHAIN_DIR"
    mkdir -p "$BLOCKCHAIN_DIR"
    cd "$BLOCKCHAIN_DIR"
    
    # Clone the official repository (update URL as needed)
    echo "📥 Cloning official testnet repository..."
    git clone https://github.com/Cintaraio/cintara-testnet-script.git testnet-script
    cd testnet-script
else
    echo "📁 Using existing blockchain node directory at $BLOCKCHAIN_DIR"
    cd "$BLOCKCHAIN_DIR/testnet-script"
    
    # Update to latest version
    echo "🔄 Updating to latest version..."
    git pull origin main
fi

# Make script executable
chmod +x cintara_ubuntu_node.sh

echo ""
echo "🔧 Starting Manual Blockchain Node Setup"
echo "========================================"
echo "Please follow the prompts:"
echo "1. Enter your node name (e.g., 'my-smart-node')"
echo "2. Choose a secure keyring password (8+ characters)"
echo "3. Save the mnemonic phrase securely!"
echo ""
echo "Press Enter to continue..."
read

# Run the official setup script
./cintara_ubuntu_node.sh

echo ""
echo "✅ Manual setup completed!"
echo ""
echo "🔍 Verifying installation..."

# Check if blockchain node binary is installed
if command -v cintarad &> /dev/null; then
    echo "✅ Blockchain node binary installed successfully"
    
    # Check node status
    if pgrep -x "cintarad" > /dev/null; then
        echo "✅ Blockchain node is running"
        
        # Test RPC endpoint
        if curl -s http://localhost:26657/status > /dev/null; then
            echo "✅ RPC endpoint responding on port 26657"
            echo "🎉 Blockchain node setup complete and operational!"
        else
            echo "⚠️  RPC endpoint not responding. Node may still be starting up."
        fi
    else
        echo "⚠️  Blockchain node not running. You may need to start it manually:"
        echo "   cintarad start --home ~/.tmp-cintarad"
    fi
else
    echo "❌ Blockchain node binary not found. Please check the setup logs for errors."
    exit 1
fi

echo ""
echo "📝 Next Steps:"
echo "============="
echo "1. Make sure the blockchain node is running (check above)"
echo "2. Return to the Docker setup directory"
echo "3. Run: docker compose up -d"
echo "4. Test the AI bridge: curl http://localhost:8080/health"
echo ""
echo "🔗 Important URLs:"
echo "- Blockchain Node RPC: http://localhost:26657"
echo "- LLM Server: http://localhost:8000"  
echo "- AI Bridge: http://localhost:8080"