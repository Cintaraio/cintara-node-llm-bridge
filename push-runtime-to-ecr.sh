#!/bin/bash
# Push Runtime Setup Cintara Node to AWS ECR
set -e

# Configuration
ECR_REGION="${ECR_REGION:-us-east-1}"
ECR_REPOSITORY="${ECR_REPOSITORY:-cintara-node-runtime}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
USE_PUBLIC_ECR="${USE_PUBLIC_ECR:-true}"  # Default to public ECR for SecretNetwork access

echo "🚀 Pushing Cintara Node Runtime to AWS ECR"
echo "==========================================="
echo ""
echo "📋 Configuration:"
echo "  Region: $ECR_REGION"
echo "  Repository: $ECR_REPOSITORY"
echo "  Tag: $IMAGE_TAG"
echo "  Build Timestamp: $BUILD_TIMESTAMP"
echo "  Public ECR: $USE_PUBLIC_ECR"
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

# Configure ECR settings based on public/private
if [ "$USE_PUBLIC_ECR" = "true" ]; then
    # Public ECR configuration
    ECR_REGISTRY="public.ecr.aws"
    REGISTRY_ALIAS="${REGISTRY_ALIAS:-cintara}"  # You'll need to set this
    FULL_REPOSITORY="$ECR_REGISTRY/$REGISTRY_ALIAS/$ECR_REPOSITORY"

    echo "🌐 Using Public ECR"
    echo "📦 Registry: $ECR_REGISTRY"
    echo "🏷️  Alias: $REGISTRY_ALIAS"
    echo "📦 Full Repository: $FULL_REPOSITORY"
    echo ""

    # Login to public ECR
    echo "🔑 Logging into Public ECR..."
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

    # Create public repository if it doesn't exist
    echo "📦 Creating public ECR repository if needed..."
    aws ecr-public create-repository --repository-name $ECR_REPOSITORY --region us-east-1 2>/dev/null || echo "Repository already exists"

else
    # Private ECR configuration (original)
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com"
    FULL_REPOSITORY="$ECR_REGISTRY/$ECR_REPOSITORY"

    echo "🔐 Using Private ECR"
    echo "🔐 AWS Account: $ACCOUNT_ID"
    echo "📦 ECR Registry: $ECR_REGISTRY"
    echo ""

    # Login to private ECR
    echo "🔑 Logging into Private ECR..."
    aws ecr get-login-password --region $ECR_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

    # Create private repository if it doesn't exist
    echo "📦 Creating private ECR repository if needed..."
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $ECR_REGION 2>/dev/null || echo "Repository already exists"
fi

# Build the image if it doesn't exist locally
LOCAL_IMAGE="cintara-node-runtime:latest"
if ! docker image inspect $LOCAL_IMAGE &> /dev/null; then
    echo "🔨 Local image not found, building first..."
    ./build-runtime-setup.sh
fi

# Tag for ECR
ECR_IMAGE="$FULL_REPOSITORY:$IMAGE_TAG"
ECR_IMAGE_TIMESTAMP="$FULL_REPOSITORY:$BUILD_TIMESTAMP"

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
if [ "$USE_PUBLIC_ECR" = "true" ]; then
cat << 'ENV_EXAMPLE'
# SecretVM Configuration (Public ECR)
ECR_REGISTRY=public.ecr.aws/cintara/cintara-node-runtime
IMAGE_TAG=latest
MONIKER=my-secretvm-node
NODE_PASSWORD=MySecurePassword123!
CHAIN_ID=cintara_11001-1
OVERWRITE_CONFIG=y
AUTO_START=true
ENV_EXAMPLE
else
cat << 'ENV_EXAMPLE'
# SecretVM Configuration (Private ECR)
ECR_REGISTRY=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
IMAGE_TAG=latest
MONIKER=my-secretvm-node
NODE_PASSWORD=MySecurePassword123!
CHAIN_ID=cintara_11001-1
OVERWRITE_CONFIG=y
AUTO_START=true
ENV_EXAMPLE
fi
echo ""
echo "2. Deploy on SecretVM:"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml pull"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml up -d"
echo ""
echo "3. Watch setup process:"
echo "   docker-compose -f docker-compose.secretvm-runtime.yml logs -f cintara-node-runtime"
echo ""
echo "🔗 ECR Repository: https://${ECR_REGION}.console.aws.amazon.com/ecr/repositories/private/${ACCOUNT_ID}/${ECR_REPOSITORY}"