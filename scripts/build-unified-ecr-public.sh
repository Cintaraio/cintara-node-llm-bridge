#!/bin/bash

set -e

echo "🐳 Building and Pushing Unified Cintara Image to AWS ECR Public"
echo "============================================================="

# Configuration
AWS_PROFILE="cintaraio"  # AWS profile to use
ECR_PUBLIC_REGISTRY="public.ecr.aws"
REGISTRY_ALIAS="b8j2u1c6"  # Your ECR Public registry alias
NAMESPACE="cintaraio"  # Your public namespace

# Repository name for unified image
UNIFIED_REPO="cintara-unified"

# Get version from git tag or use latest
VERSION=${1:-latest}
if [ "$VERSION" = "latest" ]; then
    # Try to get git tag or commit hash
    if git describe --tags --exact-match 2>/dev/null; then
        VERSION=$(git describe --tags --exact-match)
    else
        VERSION="latest-$(git rev-parse --short HEAD)"
    fi
fi

echo "✅ Using AWS Profile: $AWS_PROFILE"
echo "✅ ECR Public Registry: $ECR_PUBLIC_REGISTRY"
echo "✅ Registry Alias: $REGISTRY_ALIAS"
echo "✅ Namespace: $NAMESPACE"
echo "✅ Repository: $UNIFIED_REPO"
echo "✅ Version/Tag: $VERSION"
echo ""

# Verify AWS profile works
echo "🔍 Verifying AWS credentials..."
aws sts get-caller-identity --profile $AWS_PROFILE > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Failed to verify AWS credentials for profile '$AWS_PROFILE'"
    echo "   Make sure the profile is configured: aws configure --profile $AWS_PROFILE"
    exit 1
fi

echo "✅ AWS credentials verified"
echo ""

echo "📦 Creating ECR Public repository (if it doesn't exist)..."
echo "⚠️  Note: If repository doesn't exist, you may need to create it via AWS Console:"
echo "   Go to: https://console.aws.amazon.com/ecr/repositories?region=us-east-1"
echo "   1. Click 'Create repository' under 'Public registry'"
echo "   2. Repository name: $UNIFIED_REPO"
echo "   3. Namespace: $NAMESPACE"
echo ""

# Check if repository exists (this will fail silently if it doesn't exist)
aws ecr-public describe-repositories --repository-names $UNIFIED_REPO --region us-east-1 --profile $AWS_PROFILE > /dev/null 2>&1 || {
    echo "⚠️  Repository $UNIFIED_REPO may not exist. Creating it..."
    aws ecr-public create-repository --repository-name $UNIFIED_REPO --region us-east-1 --profile $AWS_PROFILE > /dev/null 2>&1 || {
        echo "⚠️  Could not create repository automatically. Please create it manually in AWS Console."
        echo "   Repository name: $UNIFIED_REPO"
    }
}

# Login to ECR Public (note: always use us-east-1 for public)
echo "🔐 Logging in to ECR Public..."
aws ecr-public get-login-password --region us-east-1 --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_PUBLIC_REGISTRY

echo ""
echo "🏗️  Building Docker image..."

# Full image names
FULL_IMAGE_NAME="$ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$UNIFIED_REPO"
IMAGE_TAG_LATEST="$FULL_IMAGE_NAME:latest"
IMAGE_TAG_VERSION="$FULL_IMAGE_NAME:$VERSION"

echo "📦 Building Unified Cintara image for AMD64 and ARM64..."
echo "   Image: $FULL_IMAGE_NAME"
echo "   Tags: latest, $VERSION"

# Create buildx builder if it doesn't exist
docker buildx create --use --name multiplatform-unified || docker buildx use multiplatform-unified

# Build and push for multiple platforms
echo "🚀 Building and pushing multi-platform image..."
docker buildx build --platform linux/amd64,linux/arm64 \
  -t $IMAGE_TAG_LATEST \
  -t $IMAGE_TAG_VERSION \
  -f Dockerfile.unified \
  --push .

echo ""
echo "✅ SUCCESS! Unified image built and pushed to AWS ECR Public:"
echo "   - $IMAGE_TAG_LATEST"
echo "   - $IMAGE_TAG_VERSION"
echo ""
echo "🌐 This image is now PUBLICLY accessible!"
echo "   Anyone can pull it without authentication:"
echo "   docker pull $IMAGE_TAG_LATEST"
echo "   docker pull $IMAGE_TAG_VERSION"
echo ""
echo "🎯 To use this unified image, you can now run:"
echo "   docker run -d --name cintara-unified \\"
echo "     -p 26657:26657 -p 26656:26656 -p 1317:1317 -p 9090:9090 \\"
echo "     -p 8000:8000 -p 8080:8080 \\"
echo "     -v cintara_data:/data -v cintara_home:/home/cintara/data \\"
echo "     $IMAGE_TAG_LATEST"
echo ""
echo "🐳 Or update your docker-compose.yml to use the pre-built image:"
echo "   services:"
echo "     cintara-unified:"
echo "       image: $IMAGE_TAG_LATEST"
echo "       # Remove the 'build' section"
echo ""
echo "📝 Image details:"
echo "   - Contains: Cintara Node + LLM Server + AI Bridge"
echo "   - Fully automated setup (no manual intervention)"
echo "   - Multi-architecture support (AMD64 + ARM64)"
echo "   - Size: ~2-3 GB (includes model)"
echo "   - Startup time: ~5-10 minutes (first run)"