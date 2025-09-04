#!/bin/bash

echo "🚀 Starting Smart Cintara Node System"
echo "====================================="

# Check if Cintara node is running
if ! curl -s http://localhost:26657/status > /dev/null; then
    echo "❌ Cintara node not detected on localhost:26657"
    echo ""
    echo "Please ensure the Cintara node is running first:"
    echo "1. Run: ./setup-cintara-node.sh (if not already done)"
    echo "2. Or manually start: cintarad start --home ~/.tmp-cintarad"
    echo ""
    exit 1
fi

echo "✅ Cintara node detected and responding"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp .env.example .env
    echo "📝 Please edit .env file with your configuration before continuing"
    echo "   At minimum, set MODEL_FILE to match your downloaded model"
    exit 1
fi

# Check if models directory exists
if [ ! -d "models" ] || [ -z "$(ls -A models 2>/dev/null)" ]; then
    echo "❌ Models directory is empty"
    echo "Please download an LLM model first:"
    echo "  mkdir -p models"
    echo "  cd models"  
    echo "  wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf"
    echo "  cd .."
    exit 1
fi

echo "✅ Configuration and models ready"

# Start Docker services
echo "🐳 Starting LLM and AI Bridge services..."
docker compose up -d

# Wait a moment for services to start
echo "⏳ Waiting for services to initialize..."
sleep 5

# Check service health
echo "🔍 Checking service health..."

# Check LLM
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ LLM Server healthy on port 8000"
else
    echo "⚠️  LLM Server not responding yet (may still be loading)"
fi

# Check Bridge
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ AI Bridge healthy on port 8080"
else
    echo "⚠️  AI Bridge not responding yet (may still be starting)"
fi

echo ""
echo "🎉 Smart Cintara Node startup complete!"
echo ""
echo "🔗 Service URLs:"
echo "- Cintara Node RPC: http://localhost:26657"
echo "- LLM Server: http://localhost:8000"
echo "- AI Bridge API: http://localhost:8080"
echo ""
echo "🧪 Test commands:"
echo "- Node status: curl http://localhost:26657/status | jq .sync_info"
echo "- LLM health: curl http://localhost:8000/health"  
echo "- Bridge health: curl http://localhost:8080/health"
echo "- AI diagnosis: curl -X POST http://localhost:8080/node/diagnose"
echo ""
echo "📊 View logs:"
echo "- All services: docker compose logs -f"
echo "- LLM only: docker compose logs -f llama"
echo "- Bridge only: docker compose logs -f bridge"