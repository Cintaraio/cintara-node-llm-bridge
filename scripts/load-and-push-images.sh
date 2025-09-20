#!/bin/bash

set -e

echo "🚀 Loading and Pushing Saved Images to Docker Hub"
echo "=============================================="

# Configuration
IMAGE_PREFIX="ramsrulez"
OUTPUT_DIR="./docker-images"

# Check if tar files exist
if [ ! -f "${OUTPUT_DIR}/cintara-node-latest.tar.gz" ] || [ ! -f "${OUTPUT_DIR}/cintara-ai-bridge-latest.tar.gz" ]; then
    echo "❌ Image files not found. Please run ./scripts/build-and-save-images.sh first"
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo "❌ Not logged in to Docker Hub. Please run:"
    echo "   docker login"
    exit 1
fi

echo "✅ Docker Hub login verified"
echo ""

echo "📥 Loading images from saved tar files..."

# Load images
echo "📥 Loading cintara-node image..."
docker load -i ${OUTPUT_DIR}/cintara-node-latest.tar.gz

echo "📥 Loading cintara-ai-bridge image..."
docker load -i ${OUTPUT_DIR}/cintara-ai-bridge-latest.tar.gz

echo ""
echo "🚀 Pushing images to Docker Hub..."

# Push images
echo "📤 Pushing cintara-node..."
docker push ${IMAGE_PREFIX}/cintara-node:latest

echo "📤 Pushing cintara-ai-bridge..."
docker push ${IMAGE_PREFIX}/cintara-ai-bridge:latest

echo ""
echo "✅ SUCCESS! Images uploaded to Docker Hub:"
echo "   - docker.io/${IMAGE_PREFIX}/cintara-node:latest"
echo "   - docker.io/${IMAGE_PREFIX}/cintara-ai-bridge:latest"
echo ""
echo "🎯 Images are now publicly available!"
echo "   Test: docker pull ${IMAGE_PREFIX}/cintara-node:latest"
echo "   Test: docker pull ${IMAGE_PREFIX}/cintara-ai-bridge:latest"