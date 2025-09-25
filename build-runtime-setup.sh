#!/bin/bash
# Build and Test Runtime Setup Cintara Node
set -e

echo "🔨 Building Cintara Node (Runtime Setup Mode)"
echo "============================================="

# Set build timestamp
export BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "📋 Build Configuration:"
echo "  Mode: Runtime Setup (follows PDF guide pattern)"
echo "  Timestamp: $BUILD_TIMESTAMP"
echo "  Architecture: x86_64"
echo ""

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f docker-compose.runtime-setup.yml down -v 2>/dev/null || echo "No existing containers to clean"

# Build the image
echo "🚀 Building with docker-compose..."
if docker-compose -f docker-compose.runtime-setup.yml build; then
    echo ""
    echo "✅ Build completed successfully!"
    echo ""

    echo "🏷️  Available images:"
    docker images | grep cintara-node-runtime || echo "No images found"
    echo ""

    echo "🎯 Ready to deploy!"
    echo "=================="
    echo ""
    echo "📋 Next steps:"
    echo "1. Start the node: docker-compose -f docker-compose.runtime-setup.yml up -d"
    echo "2. Watch logs: docker-compose -f docker-compose.runtime-setup.yml logs -f"
    echo "3. Check status: docker-compose -f docker-compose.runtime-setup.yml exec cintara-node-runtime bash"
    echo ""
    echo "🔍 The container will:"
    echo "  - Automatically run cintara_ubuntu_node.sh at startup"
    echo "  - Build the cintarad binary inside the running container"
    echo "  - Start the blockchain node once setup completes"
    echo "  - Run AI bridge and LLM server in parallel"
    echo ""

else
    echo ""
    echo "❌ Build failed!"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "1. Check if local cintara-testnet-scripts folder exists"
    echo "2. Verify Docker has enough memory (4GB+ recommended)"
    echo "3. Check build logs above for specific errors"
    exit 1
fi