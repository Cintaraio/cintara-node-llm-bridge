#!/bin/bash
# Push Runtime Setup Cintara Node to AWS ECR
set -e

# Configuration
ECR_REGION="${ECR_REGION:-us-east-1}"
ECR_REPOSITORY="${ECR_REPOSITORY:-cintara-node-runtime}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "🚀 Pushing Cintara Node Runtime to AWS ECR"
echo "==========================================="
echo ""
echo "📋 Configuration:"
echo "  Region: $ECR_REGION"
echo "  Repository: $ECR_REPOSITORY"
echo "  Tag: $IMAGE_TAG"
echo "  Build Timestamp: $BUILD_TIMESTAMP"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is required but not installed."
    echo "Install it with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured."
    echo "Configure with: aws configure"
    exit 1
fi

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com"

echo "🔐 AWS Account: $ACCOUNT_ID"
echo "📦 ECR Registry: $ECR_REGISTRY"
echo ""

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $ECR_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Create repository if it doesn't exist
echo "📦 Creating ECR repository if needed..."
aws ecr create-repository --repository-name $ECR_REPOSITORY --region $ECR_REGION 2>/dev/null || echo "Repository already exists"

# Build the image if it doesn't exist locally
LOCAL_IMAGE="cintara-node-runtime:latest"
if ! docker image inspect $LOCAL_IMAGE &> /dev/null; then
    echo "🔨 Local image not found, building first..."
    ./build-runtime-setup.sh
fi

# Tag for ECR
ECR_IMAGE="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
ECR_IMAGE_TIMESTAMP="$ECR_REGISTRY/$ECR_REPOSITORY:$BUILD_TIMESTAMP"

echo "🏷️  Tagging images..."
docker tag $LOCAL_IMAGE $ECR_IMAGE
docker tag $LOCAL_IMAGE $ECR_IMAGE_TIMESTAMP

# Push to ECR
echo "📤 Pushing to ECR..."
echo "  Pushing: $ECR_IMAGE"
docker push $ECR_IMAGE

echo "  Pushing: $ECR_IMAGE_TIMESTAMP"
docker push $ECR_IMAGE_TIMESTAMP

echo ""
echo "✅ Successfully pushed to AWS ECR!"
echo ""
echo "📋 Available Images:"
echo "  Latest: $ECR_IMAGE"
echo "  Timestamped: $ECR_IMAGE_TIMESTAMP"
echo ""
echo "🚀 For SecretVM Deployment:"
echo "==========================================="
echo ""
echo "1. Create .env file on SecretVM:"
cat << 'ENV_EXAMPLE'
# SecretVM Configuration
ECR_REGISTRY=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
IMAGE_TAG=latest
MONIKER=my-secretvm-node
NODE_PASSWORD=MySecurePassword123!
CHAIN_ID=cintara_11001-1
OVERWRITE_CONFIG=y
AUTO_START=true
ENV_EXAMPLE
echo ""
echo "2. Deploy on SecretVM:"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml pull"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml up -d"
echo ""
echo "3. Watch setup process:"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml logs -f cintara-node-runtime"
echo ""
echo "🔗 ECR Repository: https://${ECR_REGION}.console.aws.amazon.com/ecr/repositories/private/${ACCOUNT_ID}/${ECR_REPOSITORY}"