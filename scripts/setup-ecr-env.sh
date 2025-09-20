#!/bin/bash

set -e

echo "🔧 Setting up .env file for AWS ECR images"
echo "========================================="

# Configuration
AWS_REGION="us-east-1"  # Change if needed
AWS_PROFILE="cintaraio"  # AWS profile to use

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
echo ""

# Create .env file
echo "📝 Creating .env file with ECR image references..."

cat > .env << EOF
# AWS ECR Configuration
CINTARA_NODE_IMAGE=${ECR_REGISTRY}/cintara-node:latest
BRIDGE_IMAGE=${ECR_REGISTRY}/cintara-ai-bridge:latest

# Cintara Node Configuration
CHAIN_ID=cintara_11001-1
MONIKER=ec2-cintara-node

# LLM Configuration
MODEL_FILE=tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
CTX_SIZE=2048
LLM_THREADS=4

# AWS Region (for ECR access)
AWS_DEFAULT_REGION=${AWS_REGION}
EOF

echo "✅ .env file created with ECR image references"
echo ""
echo "📋 Contents of .env file:"
cat .env
echo ""
echo "🎯 You can now run: docker compose up -d"