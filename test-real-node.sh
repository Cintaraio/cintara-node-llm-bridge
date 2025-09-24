#!/bin/bash
# Test Real Cintara Node with Pre-built Image
set -e

echo "🚀 Testing Real Cintara Node (Pre-built)"
echo "======================================="

# Check if image exists
if ! docker image inspect cintara-real-node:latest >/dev/null 2>&1; then
    echo "❌ Pre-built image 'cintara-real-node:latest' not found!"
    echo "   Please run './build-real-node.sh' first to build the image."
    exit 1
fi

echo "✅ Found pre-built image: cintara-real-node:latest"

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f docker-compose.real-node-prebuilt.yml down --volumes --remove-orphans 2>/dev/null || true

# Start with pre-built image
echo "🚀 Starting real node with pre-built image..."
docker-compose -f docker-compose.real-node-prebuilt.yml up -d

# Wait for services to start
echo "⏳ Waiting for services to initialize (60 seconds)..."
sleep 60

# Check container status
echo "📊 Container Status:"
docker-compose -f docker-compose.real-node-prebuilt.yml ps

# Check logs
echo "📝 Recent Logs:"
docker-compose -f docker-compose.real-node-prebuilt.yml logs --tail=30

# Test endpoints
echo "🔍 Testing Endpoints:"

echo "Testing Cintara Node:"
curl -s http://localhost:26657/status | jq '.' || echo "Node endpoint failed"

echo -e "\nTesting Network Info:"
curl -s http://localhost:26657/net_info | jq '.' || echo "Network info failed"

echo -e "\nTesting LLM Server:"
curl -s http://localhost:8000 || echo "LLM endpoint failed"

echo -e "\nTesting AI Bridge:"
curl -s http://localhost:8080/health || echo "AI Bridge failed"

# Check if real cintarad is running
echo -e "\n🔍 Checking if real blockchain node is running:"
docker-compose -f docker-compose.real-node-prebuilt.yml exec -T cintara-real-node-prebuilt ps aux | grep -E "(cintarad|nc)" || echo "Process check failed"

# Check for cintarad binary
echo -e "\n🔍 Checking for cintarad binary:"
docker-compose -f docker-compose.real-node-prebuilt.yml exec -T cintara-real-node-prebuilt which cintarad 2>/dev/null && echo "✅ cintarad found" || echo "❌ cintarad not found"

echo ""
echo "🎯 Test Complete!"
echo "If you see real blockchain responses (with sync_info, peers, etc.), the node is working!"
echo "If you see simple JSON responses, it's still running placeholders."