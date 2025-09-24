#!/bin/bash
# Push Real Cintara Node Image to ECR
set -e

echo "☁️  Pushing Real Cintara Node to AWS ECR"
echo "======================================="

# Configuration
REGION="us-east-1"
ECR_REGISTRY="public.ecr.aws/b8j2u1c6"
REPOSITORY_NAME="cintaraio/cintara-unified"
LOCAL_IMAGE="cintara-real-node:latest"
COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ECR tags
ECR_TAG_LATEST="${ECR_REGISTRY}/${REPOSITORY_NAME}:real-node-latest"
ECR_TAG_COMMIT="${ECR_REGISTRY}/${REPOSITORY_NAME}:real-node-${COMMIT_HASH}"
ECR_TAG_TIMESTAMP="${ECR_REGISTRY}/${REPOSITORY_NAME}:real-node-${BUILD_TIMESTAMP}"

echo "📋 Push Configuration:"
echo "  Local image: $LOCAL_IMAGE"
echo "  ECR registry: $ECR_REGISTRY"
echo "  Repository: $REPOSITORY_NAME"
echo "  Commit: $COMMIT_HASH"
echo "  Timestamp: $BUILD_TIMESTAMP"
echo ""

# Check if local image exists
if ! docker image inspect $LOCAL_IMAGE >/dev/null 2>&1; then
    echo "❌ Local image '$LOCAL_IMAGE' not found!"
    echo "   Please run './build-real-node.sh' first to build the image."
    exit 1
fi

echo "✅ Local image found: $LOCAL_IMAGE"
echo ""

# Authenticate with ECR
echo "🔐 Authenticating with ECR..."
if aws ecr-public get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY; then
    echo "✅ ECR authentication successful"
else
    echo "❌ ECR authentication failed"
    echo "   Please check your AWS credentials and permissions"
    exit 1
fi
echo ""

# Tag the image
echo "🏷️  Tagging image for ECR..."
docker tag $LOCAL_IMAGE $ECR_TAG_LATEST
docker tag $LOCAL_IMAGE $ECR_TAG_COMMIT
docker tag $LOCAL_IMAGE $ECR_TAG_TIMESTAMP

echo "✅ Image tagged with:"
echo "   - $ECR_TAG_LATEST"
echo "   - $ECR_TAG_COMMIT"
echo "   - $ECR_TAG_TIMESTAMP"
echo ""

# Push images
echo "⬆️  Pushing images to ECR..."

echo "Pushing latest tag..."
if docker push $ECR_TAG_LATEST; then
    echo "✅ Latest tag pushed successfully"
else
    echo "❌ Failed to push latest tag"
    exit 1
fi

echo "Pushing commit tag..."
if docker push $ECR_TAG_COMMIT; then
    echo "✅ Commit tag pushed successfully"
else
    echo "❌ Failed to push commit tag"
    exit 1
fi

echo "Pushing timestamp tag..."
if docker push $ECR_TAG_TIMESTAMP; then
    echo "✅ Timestamp tag pushed successfully"
else
    echo "❌ Failed to push timestamp tag"
    exit 1
fi

echo ""
echo "🎉 All images pushed successfully!"
echo ""

# Verify images in ECR
echo "🔍 Verifying images in ECR..."
if aws ecr-public describe-images --region $REGION --repository-name $REPOSITORY_NAME --image-ids imageTag=real-node-latest >/dev/null 2>&1; then
    echo "✅ Image verified in ECR"
else
    echo "⚠️  Image verification failed, but push may have succeeded"
fi

echo ""
echo "🎯 ECR Push Complete!"
echo "===================="
echo ""
echo "📋 Available ECR Images:"
echo "  - $ECR_TAG_LATEST"
echo "  - $ECR_TAG_COMMIT"
echo "  - $ECR_TAG_TIMESTAMP"
echo ""
echo "📋 Next Steps for SecretVM:"
echo "1. Create docker-compose file using: $ECR_TAG_LATEST"
echo "2. Deploy on SecretVM"
echo "3. Check if node appears in testnet.cintara.io/nodes"
echo ""
echo "🔗 Use this in your SecretVM docker-compose:"
echo "   image: $ECR_TAG_LATEST"