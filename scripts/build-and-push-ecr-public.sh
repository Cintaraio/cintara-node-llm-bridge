#!/bin/bash

set -e

echo "🐳 Building and Pushing Cintara Images to AWS ECR Public"
echo "======================================================"

# Configuration
AWS_PROFILE="cintaraio"  # AWS profile to use
ECR_PUBLIC_REGISTRY="public.ecr.aws"
REGISTRY_ALIAS="b8j2u1c6"  # Your ECR Public registry alias
NAMESPACE="cintaraio"  # Your public namespace

# Repository names
CINTARA_NODE_REPO="cintara-node"
BRIDGE_REPO="cintara-ai-bridge"

echo "✅ Using AWS Profile: $AWS_PROFILE"
echo "✅ ECR Public Registry: $ECR_PUBLIC_REGISTRY"
echo "✅ Registry Alias: $REGISTRY_ALIAS"
echo "✅ Namespace: $NAMESPACE"
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

echo "📦 Creating ECR Public repositories (if they don't exist)..."
echo "⚠️  Note: ECR Public repositories must be created via AWS Console first"
echo "   Go to: https://console.aws.amazon.com/ecr/repositories?region=us-east-1"
echo "   1. Click 'Get Started' under 'Public registry'"
echo "   2. Create namespace: $NAMESPACE"
echo "   3. Create repositories: $CINTARA_NODE_REPO and $BRIDGE_REPO"
echo ""

# Login to ECR Public (note: always use us-east-1 for public)
echo "🔐 Logging in to ECR Public..."
aws ecr-public get-login-password --region us-east-1 --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_PUBLIC_REGISTRY

echo ""
echo "🏗️  Building Docker images..."

# Build images for multiple platforms
echo "📦 Building Cintara Node image for AMD64 and ARM64..."
docker buildx create --use --name multiplatform || docker buildx use multiplatform

docker buildx build --platform linux/amd64,linux/arm64 \
  -t $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$CINTARA_NODE_REPO:latest \
  --push ./cintara-node/

echo "📦 Building AI Bridge image for AMD64 and ARM64..."
docker buildx build --platform linux/amd64,linux/arm64 \
  -t $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$BRIDGE_REPO:latest \
  --push ./bridge/

echo ""
echo "✅ Multi-platform images built and pushed directly to ECR Public!"

echo ""
echo "✅ SUCCESS! Images pushed to AWS ECR Public:"
echo "   - $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$CINTARA_NODE_REPO:latest"
echo "   - $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$BRIDGE_REPO:latest"
echo ""
echo "🌐 These images are now PUBLICLY accessible!"
echo "   Anyone can pull them without authentication:"
echo "   docker pull $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$CINTARA_NODE_REPO:latest"
echo "   docker pull $ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$BRIDGE_REPO:latest"
echo ""
echo "🎯 To use these images, update your .env file:"
echo "   CINTARA_NODE_IMAGE=$ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$CINTARA_NODE_REPO:latest"
echo "   BRIDGE_IMAGE=$ECR_PUBLIC_REGISTRY/$REGISTRY_ALIAS/$NAMESPACE/$BRIDGE_REPO:latest"