#!/bin/bash

set -e

echo "🐳 Building and Pushing Cintara Images to AWS ECR"
echo "=============================================="

# Configuration - Update these variables
AWS_REGION="us-east-1"  # Change to your preferred region
AWS_PROFILE="cintaraio"  # AWS profile to use
AWS_ACCOUNT_ID=""       # Will be auto-detected
ECR_REGISTRY=""         # Will be auto-detected

# Auto-detect AWS account ID using specified profile
echo "🔍 Detecting AWS account ID using profile: $AWS_PROFILE..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Failed to detect AWS account ID. Make sure AWS profile '$AWS_PROFILE' is configured:"
    echo "   aws configure --profile $AWS_PROFILE"
    exit 1
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
echo "✅ ECR Registry: $ECR_REGISTRY"
echo "✅ Region: $AWS_REGION"
echo ""

# Repository names
CINTARA_NODE_REPO="cintara-node"
BRIDGE_REPO="cintara-ai-bridge"

echo "📦 Creating ECR repositories (if they don't exist)..."

# Create repositories
aws ecr create-repository --repository-name $CINTARA_NODE_REPO --region $AWS_REGION --profile $AWS_PROFILE 2>/dev/null || echo "Repository $CINTARA_NODE_REPO already exists"
aws ecr create-repository --repository-name $BRIDGE_REPO --region $AWS_REGION --profile $AWS_PROFILE 2>/dev/null || echo "Repository $BRIDGE_REPO already exists"

echo ""
echo "🔐 Logging in to ECR..."

# Login to ECR
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_REGISTRY

echo ""
echo "🏗️  Building Docker images..."

# Build images
echo "📦 Building Cintara Node image..."
docker build -t $CINTARA_NODE_REPO:latest ./cintara-node/

echo "📦 Building AI Bridge image..."
docker build -t $BRIDGE_REPO:latest ./bridge/

echo ""
echo "🏷️  Tagging images for ECR..."

# Tag images for ECR
docker tag $CINTARA_NODE_REPO:latest $ECR_REGISTRY/$CINTARA_NODE_REPO:latest
docker tag $BRIDGE_REPO:latest $ECR_REGISTRY/$BRIDGE_REPO:latest

echo ""
echo "🚀 Pushing images to ECR..."

# Push images
echo "📤 Pushing cintara-node..."
docker push $ECR_REGISTRY/$CINTARA_NODE_REPO:latest

echo "📤 Pushing cintara-ai-bridge..."
docker push $ECR_REGISTRY/$BRIDGE_REPO:latest

echo ""
echo "✅ SUCCESS! Images pushed to AWS ECR:"
echo "   - $ECR_REGISTRY/$CINTARA_NODE_REPO:latest"
echo "   - $ECR_REGISTRY/$BRIDGE_REPO:latest"
echo ""
echo "🎯 To use these images, update your .env file:"
echo "   CINTARA_NODE_IMAGE=$ECR_REGISTRY/$CINTARA_NODE_REPO:latest"
echo "   BRIDGE_IMAGE=$ECR_REGISTRY/$BRIDGE_REPO:latest"
echo ""
echo "🔧 Make repositories public (optional):"
echo "   aws ecr set-repository-policy --repository-name $CINTARA_NODE_REPO --policy-text file://ecr-public-policy.json --region $AWS_REGION --profile $AWS_PROFILE"
echo "   aws ecr set-repository-policy --repository-name $BRIDGE_REPO --policy-text file://ecr-public-policy.json --region $AWS_REGION --profile $AWS_PROFILE"