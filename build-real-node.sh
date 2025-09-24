#!/bin/bash
# Build Real Cintara Node Image
set -e

echo "🔨 Building Real Cintara Node Docker Image"
echo "=========================================="

# Set image details
IMAGE_NAME="cintara-real-node"
IMAGE_TAG="latest"
BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "📋 Build Configuration:"
echo "  Image: $IMAGE_NAME:$IMAGE_TAG"
echo "  Timestamp: $BUILD_TIMESTAMP"
echo "  Architecture: x86_64"
echo ""

# Clean up memory before build
if [ -f "./ec2-memory-cleanup.sh" ]; then
    echo "🧹 Running memory cleanup..."
    ./ec2-memory-cleanup.sh
else
    echo "⚠️  Memory cleanup script not found, continuing..."
fi

# Set Docker build environment
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Build the image
echo "🚀 Starting Docker build..."
echo "This may take 15-30 minutes for Go compilation and node setup..."

if docker build \
    -f Dockerfile.real-node-fixed \
    -t $IMAGE_NAME:$IMAGE_TAG \
    -t $IMAGE_NAME:$BUILD_TIMESTAMP \
    --build-arg BUILD_TIMESTAMP=$BUILD_TIMESTAMP \
    --build-arg TARGET_ARCH=x86_64 \
    --build-arg NODE_PASSWORD=RealNodePassword123! \
    --platform linux/amd64 \
    . ; then

    echo ""
    echo "✅ Docker build completed successfully!"
    echo ""

    # Show image details
    echo "📊 Image Information:"
    docker images | grep $IMAGE_NAME | head -3

    # Test the image quickly
    echo ""
    echo "🔍 Quick Image Test:"
    echo "Testing if cintarad binary was built..."

    if docker run --rm $IMAGE_NAME:$IMAGE_TAG bash -c 'command -v cintarad && cintarad version' 2>/dev/null; then
        echo "✅ cintarad binary is working in the image"
    else
        echo "⚠️  cintarad binary test failed - check build logs"
    fi

    echo ""
    echo "🎯 Image Build Complete!"
    echo "======================="
    echo ""
    echo "📋 Next Steps:"
    echo "1. Test locally: docker-compose -f docker-compose.real-node-prebuilt.yml up -d"
    echo "2. Push to ECR: ./push-real-node-to-ecr.sh"
    echo "3. Deploy on SecretVM with pre-built image"
    echo ""
    echo "🏷️  Available Tags:"
    echo "   - $IMAGE_NAME:latest"
    echo "   - $IMAGE_NAME:$BUILD_TIMESTAMP"

else
    echo ""
    echo "❌ Docker build failed!"
    echo ""
    echo "🔍 Common issues:"
    echo "1. Insufficient memory - run ./ec2-memory-cleanup.sh"
    echo "2. Network issues - check internet connectivity"
    echo "3. Go compilation errors - check Dockerfile.real-node"
    echo "4. Node setup failures - check cintara-testnet-script"
    echo ""
    exit 1
fi