#!/bin/bash

set -e

echo "🐳 Building Cintara Images Locally for Manual Upload"
echo "================================================="

# Configuration
IMAGE_PREFIX="ramsrulez"
OUTPUT_DIR="./docker-images"

# Create output directory
mkdir -p ${OUTPUT_DIR}

echo "🏗️  Building Docker images..."
echo ""

# Build Cintara Node Image
echo "📦 Building Cintara Node image..."
docker build -t ${IMAGE_PREFIX}/cintara-node:latest ./cintara-node/

# Build AI Bridge Image
echo "📦 Building AI Bridge image..."
docker build -t ${IMAGE_PREFIX}/cintara-ai-bridge:latest ./bridge/

echo ""
echo "💾 Saving images as tar files..."

# Save images as tar files
echo "💾 Saving cintara-node image..."
docker save ${IMAGE_PREFIX}/cintara-node:latest -o ${OUTPUT_DIR}/cintara-node-latest.tar

echo "💾 Saving cintara-ai-bridge image..."
docker save ${IMAGE_PREFIX}/cintara-ai-bridge:latest -o ${OUTPUT_DIR}/cintara-ai-bridge-latest.tar

# Compress the tar files to save space
echo "🗜️  Compressing image files..."
gzip ${OUTPUT_DIR}/cintara-node-latest.tar
gzip ${OUTPUT_DIR}/cintara-ai-bridge-latest.tar

echo ""
echo "✅ SUCCESS! Images built and saved:"
echo "   📁 ${OUTPUT_DIR}/cintara-node-latest.tar.gz"
echo "   📁 ${OUTPUT_DIR}/cintara-ai-bridge-latest.tar.gz"
echo ""

# Show file sizes
echo "📊 File sizes:"
ls -lh ${OUTPUT_DIR}/*.tar.gz

echo ""
echo "🚀 To upload to Docker Hub later:"
echo "   1. Login: docker login"
echo "   2. Load: docker load -i ${OUTPUT_DIR}/cintara-node-latest.tar.gz"
echo "   3. Load: docker load -i ${OUTPUT_DIR}/cintara-ai-bridge-latest.tar.gz"
echo "   4. Push: docker push ${IMAGE_PREFIX}/cintara-node:latest"
echo "   5. Push: docker push ${IMAGE_PREFIX}/cintara-ai-bridge:latest"
echo ""
echo "📝 Or use the upload script: ./scripts/load-and-push-images.sh"