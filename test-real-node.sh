#!/bin/bash
# Test Real Cintara Node Build and Deployment
set -e

echo "🚀 Testing Real Cintara Node Build"
echo "=================================="

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f docker-compose.real-node-test.yml down --volumes --remove-orphans 2>/dev/null || true

# Build and start
echo "🔨 Building and starting real node..."
docker-compose -f docker-compose.real-node-test.yml up -d --build

# Wait for services to start
echo "⏳ Waiting for services to initialize (60 seconds)..."
sleep 60

# Check container status
echo "📊 Container Status:"
docker-compose -f docker-compose.real-node-test.yml ps

# Check logs
echo "📝 Recent Logs:"
docker-compose -f docker-compose.real-node-test.yml logs --tail=30

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
docker-compose -f docker-compose.real-node-test.yml exec -T cintara-real-node ps aux | grep -E "(cintarad|nc)" || echo "Process check failed"

# Check for cintarad binary
echo -e "\n🔍 Checking for cintarad binary:"
docker-compose -f docker-compose.real-node-test.yml exec -T cintara-real-node which cintarad 2>/dev/null && echo "✅ cintarad found" || echo "❌ cintarad not found"

echo ""
echo "🎯 Test Complete!"
echo "If you see real blockchain responses (with sync_info, peers, etc.), the node is working!"
echo "If you see simple JSON responses, it's still running placeholders."