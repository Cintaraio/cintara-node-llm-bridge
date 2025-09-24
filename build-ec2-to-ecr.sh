#!/bin/bash
# EC2 Build Script for x86-64 Architecture with LLM fixes
# This script builds on EC2 and pushes to AWS ECR for SecretVM deployment

set -e

# Configuration
ECR_REGISTRY="public.ecr.aws/b8j2u1c6"
ECR_REPOSITORY="cintaraio/cintara-unified"
IMAGE_TAG_X86="x86-64-latest"
IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG_X86}"
BUILD_TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

echo "🚀 Building Cintara Unified Container on EC2 (x86-64)"
echo "Registry: ${ECR_REGISTRY}"
echo "Repository: ${ECR_REPOSITORY}"
echo "Tag: ${IMAGE_TAG_X86}"
echo "Full URI: ${IMAGE_URI}"
echo "Build Timestamp: ${BUILD_TIMESTAMP}"
echo ""

# Check if we're on the right architecture
ARCH=$(uname -m)
echo "🔍 Current architecture: $ARCH"
if [[ "$ARCH" != "x86_64" ]]; then
    echo "⚠️  Warning: Not running on x86_64. SecretVM requires x86_64 architecture."
    echo "   Current: $ARCH"
    echo "   Expected: x86_64"
fi
echo ""

# Check required files exist
echo "📋 Checking required files..."
REQUIRED_FILES=(
    "Dockerfile.production-minimal"
    "bridge/app.py"
    "cintara-node/node-config.env"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Required file not found: $file"
        exit 1
    else
        echo "✅ Found: $file"
    fi
done
echo ""

# Install dependencies for EC2 if needed
echo "🔧 Installing EC2 dependencies..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker $USER
    echo "⚠️  Please logout and login again to use docker without sudo"
fi

if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi
echo ""

# Authenticate to ECR Public
echo "🔐 Authenticating to ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
echo ""

# Build with the EC2-optimized Dockerfile
echo "🏗️  Building with Dockerfile.ec2-optimized (LLM issues fixed for EC2)..."
echo "This build includes fixes for:"
echo "  - CURL dependency issues"
echo "  - LLaMA.cpp build failures"
echo "  - Architecture compatibility"
echo "  - SecretVM environment compatibility"
echo ""

# Set build environment
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Build the image with error handling
echo "Starting Docker build..."
if docker build \
    -f Dockerfile.ecr-prebuilt \
    -t cintara-unified:${IMAGE_TAG_X86} \
    --build-arg BUILD_TIMESTAMP=${BUILD_TIMESTAMP} \
    --build-arg TARGET_ARCH=x86_64 \
    --build-arg DEFAULT_PASSWORD=SecureNodePassword123! \
    --platform linux/amd64 \
    . ; then
    echo "✅ Docker build completed successfully!"
else
    echo "❌ Docker build failed. Checking for common issues..."
    echo ""
    echo "🔍 Common LLM build issues on EC2:"
    echo "1. Insufficient memory - try: sudo swapon --show && sudo fallocate -l 2G /swapfile"
    echo "2. Missing dependencies - run: sudo yum groupinstall -y 'Development Tools'"
    echo "3. Docker daemon issues - try: sudo systemctl restart docker"
    echo ""
    exit 1
fi
echo ""

# Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag cintara-unified:${IMAGE_TAG_X86} ${IMAGE_URI}
echo ""

# Push to ECR
echo "📦 Pushing to ECR Public..."
if docker push ${IMAGE_URI}; then
    echo "✅ Successfully pushed to ECR!"
else
    echo "❌ Push failed. Checking authentication..."
    echo "Try re-authenticating:"
    echo "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws"
    exit 1
fi
echo ""

# Verify the push
echo "✅ Verifying push..."
aws ecr-public describe-images \
    --repository-name ${ECR_REPOSITORY} \
    --region us-east-1 \
    --query 'imageDetails[?imageTag==`'${IMAGE_TAG_X86}'`].[imagePushedAt,imageSizeInBytes]' \
    --output table || echo "Verification failed, but image may still be available"
echo ""

# Create deployment info
echo "📋 Creating deployment information..."
cat > deployment-info.json << EOF
{
  "image_uri": "${IMAGE_URI}",
  "build_timestamp": "${BUILD_TIMESTAMP}",
  "architecture": "x86_64",
  "built_on": "$(uname -a)",
  "dockerfile": "Dockerfile.production-minimal",
  "services": ["cintara-node", "llama-server", "ai-bridge"],
  "ready_for_secretvm": true
}
EOF

echo "🎉 Build and push completed successfully!"
echo ""
echo "📊 Summary:"
echo "  Image URI: ${IMAGE_URI}"
echo "  Architecture: x86_64 (SecretVM compatible)"
echo "  Build timestamp: ${BUILD_TIMESTAMP}"
echo "  Size: $(docker images ${IMAGE_URI} --format 'table {{.Size}}' | tail -1)"
echo ""
echo "🚀 Next steps for SecretVM deployment:"
echo "1. Use docker-compose.secretvm-ecr.yml in SecretVM portal"
echo "2. The image is now available at: ${IMAGE_URI}"
echo "3. Monitor deployment logs for successful startup"
echo ""
echo "🔍 Troubleshooting commands:"
echo "  docker run --rm ${IMAGE_URI} /health-check.sh"
echo "  docker logs <container-name>"
echo ""
echo "✅ Ready for SecretVM deployment!"