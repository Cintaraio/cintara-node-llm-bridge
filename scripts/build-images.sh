#!/bin/bash

set -e

# Configuration
REGISTRY=${REGISTRY:-"ghcr.io/cintaraio"}
VERSION=${VERSION:-"latest"}
PLATFORMS=${PLATFORMS:-"linux/amd64,linux/arm64"}

echo "🏗️ Building Cintara AI Bridge Images"
echo "Registry: $REGISTRY"
echo "Version: $VERSION"
echo "Platforms: $PLATFORMS"

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Build Cintara Node Image
echo "📦 Building Cintara Node Image..."
docker buildx build \
    --platform="$PLATFORMS" \
    --tag="$REGISTRY/cintara-node:$VERSION" \
    --tag="$REGISTRY/cintara-node:latest" \
    --push \
    ./cintara-node/

echo "✅ Cintara Node image built and pushed"

# Build AI Bridge Image
echo "📦 Building AI Bridge Image..."
docker buildx build \
    --platform="$PLATFORMS" \
    --tag="$REGISTRY/cintara-ai-bridge:$VERSION" \
    --tag="$REGISTRY/cintara-ai-bridge:latest" \
    --push \
    ./bridge/

echo "✅ AI Bridge image built and pushed"

echo "🎉 All images built successfully!"
echo ""
echo "Images available at:"
echo "  - $REGISTRY/cintara-node:$VERSION"
echo "  - $REGISTRY/cintara-ai-bridge:$VERSION"
echo ""
echo "To use these images, update your .env file:"
echo "  CINTARA_NODE_IMAGE=$REGISTRY/cintara-node:$VERSION"
echo "  BRIDGE_IMAGE=$REGISTRY/cintara-ai-bridge:$VERSION"