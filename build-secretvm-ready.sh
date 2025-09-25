#!/bin/bash
# Build SecretNetwork-Ready Cintara Node (Complete Workflow)
set -e

echo "🚀 Building SecretNetwork-Ready Cintara Node"
echo "============================================="
echo ""

BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "📋 Workflow Overview:"
echo "1. Generate pre-configured node setup (with validator)"
echo "2. Build Docker image with pre-configuration"
echo "3. Push to ECR for SecretNetwork deployment"
echo ""

# Step 1: Generate pre-configuration
echo "🔧 Step 1: Generating pre-configured node setup..."
echo "=================================================="

if [ ! -d "preconfig" ]; then
    echo "📦 Running pre-configuration generator..."
    ./create-preconfig.sh
else
    echo "✅ Pre-configuration already exists"
    echo "🔍 Verifying existing configuration..."

    if [ -f "preconfig/config/genesis.json" ]; then
        VALIDATOR_COUNT=$(cat preconfig/config/genesis.json | jq '.app_state.genutil.gen_txs | length')
        echo "✅ Found genesis with $VALIDATOR_COUNT validator(s)"

        if [ "$VALIDATOR_COUNT" -eq 0 ]; then
            echo "⚠️  No validators found, regenerating..."
            rm -rf preconfig
            ./create-preconfig.sh
        fi
    else
        echo "⚠️  Genesis file missing, regenerating..."
        rm -rf preconfig
        ./create-preconfig.sh
    fi
fi

echo ""

# Step 2: Build Docker image
echo "🔨 Step 2: Building Docker image with pre-configuration..."
echo "=========================================================="

docker build -f Dockerfile.preconfig \
    --build-arg BUILD_TIMESTAMP=$BUILD_TIMESTAMP \
    --build-arg TARGET_ARCH=x86_64 \
    -t cintara-secretvm-ready:latest \
    -t cintara-secretvm-ready:$BUILD_TIMESTAMP \
    .

echo ""
echo "✅ Docker build completed!"

# Step 3: Test the image locally
echo ""
echo "🧪 Step 3: Testing the image locally..."
echo "======================================="

echo "📦 Starting test container..."

# Stop any existing test container
docker stop cintara-test 2>/dev/null || true
docker rm cintara-test 2>/dev/null || true

# Start test container
docker run -d --name cintara-test \
    -p 26657:26657 -p 26656:26656 -p 8080:8080 \
    cintara-secretvm-ready:latest

echo "⏳ Waiting for node to start (60 seconds)..."
sleep 60

echo "🔍 Testing node status..."
if curl -s -f http://localhost:26657/status >/dev/null; then
    echo "✅ Node is responding!"

    # Get detailed status
    NODE_STATUS=$(curl -s http://localhost:26657/status | jq -r '.result.node_info.moniker')
    CHAIN_ID=$(curl -s http://localhost:26657/status | jq -r '.result.node_info.network')

    echo "📋 Node Details:"
    echo "  Moniker: $NODE_STATUS"
    echo "  Chain ID: $CHAIN_ID"
    echo "  Status: Running ✅"
else
    echo "❌ Node test failed!"
    echo "📋 Container logs:"
    docker logs cintara-test --tail 50
    docker stop cintara-test
    docker rm cintara-test
    exit 1
fi

# Clean up test container
docker stop cintara-test
docker rm cintara-test

echo ""
echo "✅ All tests passed!"
echo ""

# Step 4: Show deployment instructions
echo "🎯 Step 4: SecretNetwork Deployment Ready!"
echo "=========================================="
echo ""
echo "📋 Image Details:"
echo "  Name: cintara-secretvm-ready:latest"
echo "  Timestamp: cintara-secretvm-ready:$BUILD_TIMESTAMP"
echo "  Pre-configured: Yes (includes validator)"
echo "  SecretNetwork Ready: Yes (no interaction needed)"
echo ""
echo "🚀 Deploy to ECR:"
echo "  1. Tag for ECR: docker tag cintara-secretvm-ready:latest public.ecr.aws/b8j2u1c6/cintaraio/cintara-secretvm-ready:latest"
echo "  2. Push to ECR: docker push public.ecr.aws/b8j2u1c6/cintaraio/cintara-secretvm-ready:latest"
echo ""
echo "🎯 Deploy on SecretNetwork:"
echo "  docker run -d -p 26657:26657 -p 26656:26656 public.ecr.aws/b8j2u1c6/cintaraio/cintara-secretvm-ready:latest"
echo ""
echo "🌟 Key Features:"
echo "  ✅ Pre-configured validator (no setup needed)"
echo "  ✅ Downloads cintarad binary automatically"
echo "  ✅ Includes working genesis.json with validator"
echo "  ✅ Starts immediately on SecretNetwork"
echo "  ✅ Should appear in testnet.cintara.io/nodes"
echo ""

echo "🎉 SecretNetwork-ready image completed successfully!"