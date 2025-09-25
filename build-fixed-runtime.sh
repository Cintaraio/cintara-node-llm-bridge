#!/bin/bash
# Build Fixed Runtime Cintara Node (Creates Proper Validator)
set -e

echo "🔨 Building Fixed Cintara Node (Creates Validator)"
echo "================================================="

# Set build timestamp
export BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "📋 Build Configuration:"
echo "  Mode: Fixed Runtime (Creates Validator Genesis Transaction)"
echo "  Timestamp: $BUILD_TIMESTAMP"
echo "  Architecture: x86_64"
echo "  Key Fix: Uses expect for proper interactive setup"
echo ""

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f docker-compose.fixed-runtime.yml down -v 2>/dev/null || echo "No existing containers to clean"

# Build the image
echo "🚀 Building with docker-compose..."
if docker-compose -f docker-compose.fixed-runtime.yml build; then
    echo ""
    echo "✅ Build completed successfully!"
    echo ""

    echo "🏷️  Available images:"
    docker images | grep cintara-node-fixed || echo "No images found"
    echo ""

    echo "🎯 Ready to test the fixed version!"
    echo "=================================="
    echo ""
    echo "📋 Next steps:"
    echo "1. Start: docker-compose -f docker-compose.fixed-runtime.yml up -d"
    echo "2. Watch: docker-compose -f docker-compose.fixed-runtime.yml logs -f"
    echo "3. Test:  curl -s http://localhost:26657/status | jq"
    echo ""
    echo "🔍 Key improvements:"
    echo "  ✅ Uses expect for proper interactive setup"
    echo "  ✅ Creates genesis validator transaction (like interactive mode)"
    echo "  ✅ Verifies validator count in genesis before starting"
    echo "  ✅ Should resolve 'validator set is empty' error"
    echo ""

else
    echo ""
    echo "❌ Build failed!"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "1. Check if expect package is available in container"
    echo "2. Verify script syntax in build logs above"
    echo "3. Check if cintara-testnet-scripts folder exists"
    exit 1
fi