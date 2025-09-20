#!/bin/bash

set -e

# Configuration for local builds
REGISTRY=${REGISTRY:-"cintaraio"}
VERSION=${VERSION:-"latest"}

echo "🏗️ Building Cintara AI Bridge Images Locally"
echo "Registry: $REGISTRY"
echo "Version: $VERSION"

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Build Cintara Node Image
echo "📦 Building Cintara Node Image locally..."
docker build \
    --tag="$REGISTRY/cintara-node:$VERSION" \
    --tag="$REGISTRY/cintara-node:latest" \
    ./cintara-node/

echo "✅ Cintara Node image built locally"

# Build AI Bridge Image
echo "📦 Building AI Bridge Image locally..."
docker build \
    --tag="$REGISTRY/cintara-ai-bridge:$VERSION" \
    --tag="$REGISTRY/cintara-ai-bridge:latest" \
    ./bridge/

echo "✅ AI Bridge image built locally"

echo "🎉 All images built successfully!"
echo ""
echo "Local images available:"
echo "  - $REGISTRY/cintara-node:$VERSION"
echo "  - $REGISTRY/cintara-ai-bridge:$VERSION"
echo ""
echo "To use these images locally, update your .env file:"
echo "  CINTARA_NODE_IMAGE=$REGISTRY/cintara-node:$VERSION"
echo "  BRIDGE_IMAGE=$REGISTRY/cintara-ai-bridge:$VERSION"