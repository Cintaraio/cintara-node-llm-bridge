#!/bin/bash

# Script to diagnose and fix LLM container issues
# Run this on your EC2 instance when LLM container fails

echo "🔍 Diagnosing LLM Container Issues..."
echo "====================================="

# Check system resources
echo ""
echo "📊 System Resources:"
echo "CPU Count: $(nproc)"
echo "Memory:"
free -h
echo ""
echo "Disk Space:"
df -h

echo ""
echo "🔍 Checking Model File..."
if [ -f "models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" ]; then
    echo "✅ Model file exists"
    ls -lh models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
else
    echo "❌ Model file missing!"
    echo "📥 Downloading model file..."
    mkdir -p models
    cd models
    wget -O tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    cd ..
    echo "✅ Model downloaded"
fi

echo ""
echo "🐳 Docker Container Status:"
sudo docker compose ps

echo ""
echo "📋 LLM Container Logs:"
sudo docker compose logs llama --tail=20

echo ""
echo "🔧 Attempting Fixes..."

# Fix 1: Try with reduced resources
echo "1. Trying with reduced resource limits..."
sudo docker compose -f docker-compose.low-resource.yml down
sudo docker compose -f docker-compose.low-resource.yml up llama -d

# Wait a bit and check
sleep 30
if sudo docker compose -f docker-compose.low-resource.yml ps llama | grep -q "healthy"; then
    echo "✅ LLM working with reduced resources!"
    echo "Starting other services..."
    sudo docker compose -f docker-compose.low-resource.yml up -d
    exit 0
fi

# Fix 2: Try without resource limits
echo "2. Trying without any resource limits..."
cat > docker-compose.override.yml << 'EOF'
services:
  llama:
    deploy:
      resources:
        limits: {}
        reservations: {}
    command: [
      "--model", "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
      "--ctx-size", "512",
      "--threads", "1",
      "--host", "0.0.0.0", 
      "--port", "8000",
      "--n-predict", "64",
      "--verbose"
    ]
EOF

sudo docker compose down
sudo docker compose up llama -d

# Wait and check again
sleep 30
if sudo docker compose ps llama | grep -q "healthy"; then
    echo "✅ LLM working without resource limits!"
    echo "Starting other services..."
    sudo docker compose up -d
    exit 0
fi

echo ""
echo "❌ LLM still failing. Manual steps required:"
echo "1. Check logs: sudo docker compose logs llama"
echo "2. Check if you have at least 2GB free RAM"
echo "3. Try starting with even smaller settings:"
echo "   sudo docker run -it --rm -v ./models:/models ghcr.io/ggerganov/llama.cpp:server --model /models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf --ctx-size 256 --threads 1"