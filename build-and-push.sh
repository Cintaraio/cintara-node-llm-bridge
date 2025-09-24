#!/bin/bash
# Build and Push Script for Cintara Unified Container to AWS ECR Public

set -e

# Configuration
ECR_REGISTRY="public.ecr.aws/b8j2u1c6"
ECR_REPOSITORY="cintaraio/cintara-unified"
IMAGE_TAG="latest"
IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "🚀 Building and pushing Cintara Unified Container to AWS ECR"
echo "Registry: ${ECR_REGISTRY}"
echo "Repository: ${ECR_REPOSITORY}"
echo "Image URI: ${IMAGE_URI}"
echo ""

# Check if required files exist
if [ ! -f "Dockerfile.production" ]; then
    echo "❌ Error: Dockerfile.production not found!"
    exit 1
fi

if [ ! -f "bridge/app.py" ]; then
    echo "❌ Error: bridge/app.py not found!"
    exit 1
fi

if [ ! -f "cintara-node/node-config.env" ]; then
    echo "⚠️  Warning: cintara-node/node-config.env not found!"
    echo "   Container may need manual configuration."
fi

# Authenticate to ECR Public
echo "🔐 Authenticating to ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Build the image
echo "🏗️  Building production image (this may take 15-30 minutes)..."
docker build -f Dockerfile.production -t cintara-unified:${IMAGE_TAG} .

# Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag cintara-unified:${IMAGE_TAG} ${IMAGE_URI}

# Push to ECR
echo "📦 Pushing image to ECR Public..."
docker push ${IMAGE_URI}

# Verify the push
echo "✅ Verifying push..."
aws ecr-public describe-images --repository-name ${ECR_REPOSITORY} --region us-east-1 || echo "Verification failed, but image may still be available"

echo ""
echo "🎉 Build and push completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy using: docker-compose -f docker-compose.ecr.yml up -d"
echo "2. Check health: curl http://localhost:8080/health"
echo "3. Monitor logs: docker-compose -f docker-compose.ecr.yml logs -f"
echo ""
echo "🌐 Image is now available at: ${IMAGE_URI}"