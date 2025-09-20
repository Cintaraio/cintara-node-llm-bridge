#!/bin/bash

set -e

echo "🏗️ Building and Pushing Cintara Images to GHCR"
echo "================================================"

# Configuration
REGISTRY="ghcr.io/cintaraio"
VERSION=${VERSION:-"latest"}

echo "Registry: $REGISTRY"
echo "Version: $VERSION"
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Check if logged into GHCR
if ! docker info | grep -q "ghcr.io"; then
    echo "❌ Not logged into GHCR. Please run first:"
    echo "   gh auth token | docker login ghcr.io -u \$(gh api user --jq .login) --password-stdin"
    echo ""
    echo "Or use personal access token:"
    echo "   echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
    exit 1
fi

echo "✅ GHCR authentication verified"
echo ""

# Build Cintara Node Image
echo "📦 Building Cintara Node Image..."
docker build \
    --tag="$REGISTRY/cintara-node:$VERSION" \
    --tag="$REGISTRY/cintara-node:latest" \
    --platform=linux/amd64 \
    ./cintara-node/

echo "🚀 Pushing Cintara Node Image..."
docker push "$REGISTRY/cintara-node:$VERSION"
docker push "$REGISTRY/cintara-node:latest"

echo "✅ Cintara Node image pushed successfully"
echo ""

# Build AI Bridge Image
echo "📦 Building AI Bridge Image..."
docker build \
    --tag="$REGISTRY/cintara-ai-bridge:$VERSION" \
    --tag="$REGISTRY/cintara-ai-bridge:latest" \
    --platform=linux/amd64 \
    ./bridge/

echo "🚀 Pushing AI Bridge Image..."
docker push "$REGISTRY/cintara-ai-bridge:$VERSION"
docker push "$REGISTRY/cintara-ai-bridge:latest"

echo "✅ AI Bridge image pushed successfully"
echo ""

echo "🎉 All images built and pushed successfully!"
echo ""
echo "Images available at:"
echo "  - $REGISTRY/cintara-node:$VERSION"
echo "  - $REGISTRY/cintara-ai-bridge:$VERSION"
echo ""
echo "To verify images:"
echo "  docker pull $REGISTRY/cintara-node:$VERSION"
echo "  docker pull $REGISTRY/cintara-ai-bridge:$VERSION"
echo ""
echo "Next steps:"
echo "  1. Update docker-compose.yml to use these images"
echo "  2. Test deployment with: docker compose up -d"