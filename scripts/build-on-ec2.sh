#!/bin/bash

set -e

echo "🏗️  Building Cintara Unified Image on EC2"
echo "=========================================="

# Check if running on EC2
if ! curl -s http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    echo "⚠️  Warning: This script is designed for EC2 instances"
    echo "   It may not work correctly on other systems"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo "❌ Cannot detect operating system"
    exit 1
fi

echo "✅ Detected OS: $OS"

# Function to install Docker
install_docker() {
    if [[ "$OS" == *"Amazon Linux"* ]]; then
        echo "📦 Installing Docker on Amazon Linux..."
        yum update -y
        amazon-linux-extras install docker -y
        service docker start
        chkconfig docker on

        # Install Docker Compose
        curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    elif [[ "$OS" == *"Ubuntu"* ]]; then
        echo "📦 Installing Docker on Ubuntu..."
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg lsb-release

        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Set up repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl start docker
        systemctl enable docker

    else
        echo "❌ Unsupported OS: $OS"
        exit 1
    fi
}

# Function to install AWS CLI
install_aws_cli() {
    echo "📦 Installing AWS CLI..."
    if [[ "$OS" == *"Amazon Linux"* ]]; then
        yum install -y awscli
    elif [[ "$OS" == *"Ubuntu"* ]]; then
        apt-get install -y awscli
    fi

    # Verify AWS CLI
    aws --version
}

# Function to install Git
install_git() {
    echo "📦 Installing Git..."
    if [[ "$OS" == *"Amazon Linux"* ]]; then
        yum install -y git
    elif [[ "$OS" == *"Ubuntu"* ]]; then
        apt-get install -y git
    fi
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "🔧 Docker not found, installing..."
    install_docker
else
    echo "✅ Docker already installed"
    docker --version
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "🔧 AWS CLI not found, installing..."
    install_aws_cli
else
    echo "✅ AWS CLI already installed"
    aws --version
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "🔧 Git not found, installing..."
    install_git
else
    echo "✅ Git already installed"
    git --version
fi

# Add current user to docker group
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "root" ]; then
    usermod -a -G docker $CURRENT_USER
    echo "✅ Added $CURRENT_USER to docker group"
    echo "⚠️  You may need to logout and login again for group changes to take effect"
fi

# Set up working directory
WORK_DIR="/home/${CURRENT_USER}/cintara-build"
if [ "$CURRENT_USER" = "root" ]; then
    WORK_DIR="/root/cintara-build"
fi

mkdir -p $WORK_DIR
cd $WORK_DIR

# Clone repository if not exists
if [ ! -d "cintara-node-llm-bridge" ]; then
    echo "📥 Cloning Cintara repository..."
    git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
fi

cd cintara-node-llm-bridge

# Switch to the correct branch
echo "🔄 Switching to feat/unified-automated-setup branch..."
git fetch origin
git checkout feat/unified-automated-setup
git pull origin feat/unified-automated-setup

# Set up AWS credentials check
echo "🔍 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured!"
    echo "Please configure AWS credentials using one of these methods:"
    echo "1. aws configure"
    echo "2. Export environment variables:"
    echo "   export AWS_ACCESS_KEY_ID=your_access_key"
    echo "   export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo "3. Use IAM role (recommended for EC2)"
    exit 1
fi

echo "✅ AWS credentials verified"
aws sts get-caller-identity

# Login to ECR
echo "🔐 Logging in to ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Set build variables
GIT_COMMIT=$(git rev-parse --short HEAD)
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IMAGE_NAME="public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified"

echo "🏗️  Building Docker image..."
echo "   Git commit: $GIT_COMMIT"
echo "   Build time: $BUILD_TIMESTAMP"
echo "   Image name: $IMAGE_NAME"

# Build the unified image for AMD64 (SecretVM compatible)
echo "📦 Building unified Cintara image (AMD64 only for SecretVM)..."
docker build \
    --platform linux/amd64 \
    --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    -f Dockerfile.unified \
    -t "$IMAGE_NAME:latest" \
    -t "$IMAGE_NAME:$GIT_COMMIT" \
    .

echo "✅ Build completed successfully!"

# Push to ECR
echo "🚀 Pushing image to ECR..."
docker push "$IMAGE_NAME:latest"
docker push "$IMAGE_NAME:$GIT_COMMIT"

echo "✅ Image pushed successfully!"

# Also build SecretVM-specific image
echo "📦 Building SecretVM-specific image..."
docker build \
    --platform linux/amd64 \
    --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    -f Dockerfile.secretvm \
    -t "$IMAGE_NAME:secretvm-latest" \
    -t "$IMAGE_NAME:secretvm-$GIT_COMMIT" \
    .

echo "🚀 Pushing SecretVM image to ECR..."
docker push "$IMAGE_NAME:secretvm-latest"
docker push "$IMAGE_NAME:secretvm-$GIT_COMMIT"

echo ""
echo "🎉 Build and push completed successfully!"
echo ""
echo "📋 Available images:"
echo "   - $IMAGE_NAME:latest"
echo "   - $IMAGE_NAME:$GIT_COMMIT"
echo "   - $IMAGE_NAME:secretvm-latest"
echo "   - $IMAGE_NAME:secretvm-$GIT_COMMIT"
echo ""
echo "🔗 You can now use these images in your docker-compose.yml:"
echo "   image: $IMAGE_NAME:latest"
echo ""
echo "🧪 To test the images:"
echo "   docker run --rm -p 8080:8080 $IMAGE_NAME:latest"
echo ""
echo "💾 Clean up local images (optional):"
echo "   docker rmi $IMAGE_NAME:latest $IMAGE_NAME:$GIT_COMMIT $IMAGE_NAME:secretvm-latest $IMAGE_NAME:secretvm-$GIT_COMMIT"