#!/bin/bash

set -e

echo "🔧 Setting up .env file for AWS ECR Public images"
echo "=============================================="

# Configuration
REGISTRY_ALIAS="b8j2u1c6"  # Your ECR Public registry alias
NAMESPACE="cintaraio"  # Your ECR Public namespace
ECR_PUBLIC_REGISTRY="public.ecr.aws"

echo "✅ ECR Public Registry: $ECR_PUBLIC_REGISTRY"
echo "✅ Registry Alias: $REGISTRY_ALIAS"
echo "✅ Namespace: $NAMESPACE"
echo ""

# Create .env file
echo "📝 Creating .env file with ECR Public image references..."

cat > .env << EOF
# AWS ECR Public Configuration
CINTARA_NODE_IMAGE=${ECR_PUBLIC_REGISTRY}/${REGISTRY_ALIAS}/${NAMESPACE}/cintara-node:latest
BRIDGE_IMAGE=${ECR_PUBLIC_REGISTRY}/${REGISTRY_ALIAS}/${NAMESPACE}/cintara-ai-bridge:latest

# Cintara Node Configuration
CHAIN_ID=cintara_11001-1
MONIKER=ec2-cintara-node

# LLM Configuration
MODEL_FILE=tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
CTX_SIZE=2048
LLM_THREADS=4

# Note: ECR Public images don't require authentication for pulling
EOF

echo "✅ .env file created with ECR Public image references"
echo ""
echo "📋 Contents of .env file:"
cat .env
echo ""
echo "🌐 These images are publicly accessible - no authentication needed!"
echo "🎯 You can now run: docker compose up -d"