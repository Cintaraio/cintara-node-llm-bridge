#!/bin/bash

set -e

echo "🐳 Building and Pushing Cintara Images to Docker Hub"
echo "=================================================="

# Configuration
DOCKERHUB_USERNAME="ramsrulez"
DOCKER_REGISTRY="docker.io"

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo "❌ Not logged in to Docker Hub. Please run:"
    echo "   docker login"
    exit 1
fi

echo "✅ Docker Hub login verified"
echo ""

# Build Cintara Node Image
echo "🏗️  Building Cintara Node image..."
docker build -t ${DOCKERHUB_USERNAME}/cintara-node:latest ./cintara-node/

# Build AI Bridge Image
echo "🏗️  Building AI Bridge image..."
docker build -t ${DOCKERHUB_USERNAME}/cintara-ai-bridge:latest ./bridge/

echo ""
echo "🚀 Pushing images to Docker Hub..."

# Push Cintara Node Image
echo "📤 Pushing cintara-node..."
docker push ${DOCKERHUB_USERNAME}/cintara-node:latest

# Push AI Bridge Image
echo "📤 Pushing cintara-ai-bridge..."
docker push ${DOCKERHUB_USERNAME}/cintara-ai-bridge:latest

echo ""
echo "✅ SUCCESS! Images pushed to Docker Hub:"
echo "   - ${DOCKER_REGISTRY}/${DOCKERHUB_USERNAME}/cintara-node:latest"
echo "   - ${DOCKER_REGISTRY}/${DOCKERHUB_USERNAME}/cintara-ai-bridge:latest"
echo ""
echo "🎯 To use these images:"
echo "   docker pull ${DOCKERHUB_USERNAME}/cintara-node:latest"
echo "   docker pull ${DOCKERHUB_USERNAME}/cintara-ai-bridge:latest"
echo ""
echo "   Or simply run: docker compose up -d"