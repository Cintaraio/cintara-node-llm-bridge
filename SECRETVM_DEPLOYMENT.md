# SecretVM Deployment Guide

## Overview

This guide shows how to deploy the Cintara node on Secret Network using pre-built ECR images.

## Architecture

```
EC2 (Build) → AWS ECR Public Registry (Store) → SecretVM (Deploy)
```

## Why Public ECR?

- ✅ **No authentication required** on SecretVM
- ✅ **Faster deployment** - no ECR login needed
- ✅ **Easier sharing** - anyone can access the images
- ✅ **Cost effective** - public repositories are free
- ✅ **Perfect for open source projects** like Cintara

## Step 1: Build and Push to ECR (Done on EC2)

```bash
# On your EC2 instance
cd cintara-node-llm-bridge
git pull origin feat/unified-automated-setup

# Build the runtime image
./build-runtime-setup.sh

# Push to public ECR (default)
./push-runtime-to-ecr.sh

# Or push to private ECR (if needed)
USE_PUBLIC_ECR=false ./push-runtime-to-ecr.sh
```

This will:
- Build the Docker image with runtime setup
- Push to your AWS ECR repository
- Provide deployment instructions

## Step 2: Deploy on SecretVM

### Option A: Quick Deploy with Environment Variables

```bash
# On SecretVM, set your configuration (using public ECR - no auth needed!)
export MONIKER="my-secretvm-node"
export NODE_PASSWORD="MySecurePassword123!"

# Deploy (uses public ECR by default)
docker-compose -f docker-compose.secretvm-runtime.yml up -d
```

### Option B: Using .env File (Recommended)

```bash
# On SecretVM, create .env file (using public ECR)
cat > .env << 'EOF'
# Public ECR - no authentication required
ECR_REGISTRY=public.ecr.aws/b8j2u1c6/cintaraio/cintara-node-runtime
IMAGE_TAG=latest
MONIKER=my-secretvm-node
NODE_PASSWORD=MySecurePassword123!
CHAIN_ID=cintara_11001-1
OVERWRITE_CONFIG=y
AUTO_START=true
EOF

# Deploy
docker-compose -f docker-compose.secretvm-runtime.yml up -d
```

## Step 3: Monitor Deployment

```bash
# Watch the setup process
docker-compose -f docker-compose.secretvm-runtime.yml logs -f cintara-node-runtime

# Check node status
curl http://localhost:26657/status

# Check if node appears in testnet
curl -s https://testnet.cintara.io/nodes | jq
```

## Key Benefits

1. **No Build Required on SecretVM**: Uses pre-built ECR images
2. **Automated Setup**: Runs `cintara_ubuntu_node.sh` automatically at startup
3. **Proper Configuration**: Uses working genesis.json and proper chain ID
4. **Environment Variables**: Easy configuration without rebuilding
5. **Multi-Service**: Includes blockchain node + AI bridge + LLM server

## Files Overview

- `docker-compose.secretvm-runtime.yml`: ECR-based deployment for SecretVM
- `docker-compose.runtime-setup.yml`: Local build version for development
- `push-runtime-to-ecr.sh`: Script to build and push to ECR
- `Dockerfile.runtime-setup`: Runtime setup approach (follows PDF guide)

## Troubleshooting

### ECR Authentication Issues
```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### Node Setup Issues
```bash
# Check setup logs
docker-compose -f docker-compose.secretvm-runtime.yml logs cintara-node-runtime

# Enter container to debug
docker-compose -f docker-compose.secretvm-runtime.yml exec cintara-node-runtime bash
```

### Chain ID Issues
Ensure your `.env` has:
```
CHAIN_ID=cintara_11001-1
```

This matches the working genesis file included in the image.