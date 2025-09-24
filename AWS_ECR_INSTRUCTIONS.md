# AWS ECR Deployment Instructions for Cintara Unified Container

## Overview
This guide provides step-by-step instructions to build and push the Cintara unified container (with Node + AI Bridge + LLM) to AWS ECR for Secret Network deployment.

## Prerequisites
- AWS CLI installed and configured
- Docker installed
- AWS account with ECR permissions

## Step 1: Setup AWS ECR Public Repository

### Repository Information
- **Registry**: `public.ecr.aws/b8j2u1c6`
- **Repository**: `cintaraio/cintara-unified`
- **Full Image Path**: `public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest`

### Authenticate to ECR Public
```bash
# Set your AWS region (public ECR is in us-east-1)
export AWS_REGION=us-east-1

# Authenticate Docker to ECR Public
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```

## Step 2: Build and Push Container

### Set Environment Variables
```bash
# ECR Public Registry Configuration
export AWS_REGION=us-east-1
export ECR_REGISTRY=public.ecr.aws/b8j2u1c6
export ECR_REPOSITORY=cintaraio/cintara-unified
export IMAGE_TAG=latest

export IMAGE_URI=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
echo "Image URI: ${IMAGE_URI}"
```

### Build Production Image
```bash
# Navigate to project directory
cd /path/to/cintara-node-llm-bridge

# Build the production image (this will take 15-30 minutes)
docker build -f Dockerfile.production -t cintara-unified:${IMAGE_TAG} .

# Tag for ECR
docker tag cintara-unified:${IMAGE_TAG} ${IMAGE_URI}
```

### Push to ECR Public
```bash
# Push the image to ECR Public
docker push ${IMAGE_URI}

# Verify the push
aws ecr-public describe-images --repository-name ${ECR_REPOSITORY} --region us-east-1
```

## Step 3: Update Docker Compose File

### ECR Image Reference (Already Configured)
The `docker-compose.ecr.yml` file is already configured with your ECR Public registry:

```yaml
services:
  cintara-unified-ecr:
    # Production image from AWS ECR Public Registry
    image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest
```

## Step 4: Deploy on Secret Network Infrastructure

### Prepare Secret Network Server
```bash
# SSH into your Secret Network deployment server
ssh ubuntu@your-secret-network-server

# Install Docker and Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose-v2

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### Setup Persistent Directories
```bash
# Create directories for persistent data
sudo mkdir -p /opt/cintara/{node-data,home-data,models,logs}
sudo chown -R $USER:$USER /opt/cintara/
```

### Deploy with Docker Compose
```bash
# Copy docker-compose.ecr.yml to your server
scp docker-compose.ecr.yml ubuntu@your-secret-network-server:~/

# SSH into server and authenticate with ECR Public
ssh ubuntu@your-secret-network-server

# Authenticate Docker to ECR Public on the server (if needed for private pulls)
# Note: ECR Public images can often be pulled without authentication
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Deploy the container
docker-compose -f docker-compose.ecr.yml up -d

# Monitor logs
docker-compose -f docker-compose.ecr.yml logs -f
```

## Step 5: Verify Deployment

### Check Container Health
```bash
# Check container status
docker-compose -f docker-compose.ecr.yml ps

# Check service health
curl http://localhost:26657/status    # Cintara node RPC
curl http://localhost:8000/health     # LLM server
curl http://localhost:8080/health     # AI bridge

# Check container logs for all services
docker-compose -f docker-compose.ecr.yml logs cintara-unified-ecr
```

### Test Each Service
```bash
# Test Cintara Node (JSON-RPC)
curl -s http://localhost:26657/status | jq .

# Test LLM Server
curl -X POST http://localhost:8000/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello", "max_tokens": 10}'

# Test AI Bridge
curl http://localhost:8080/health
curl http://localhost:8080/api/status
```

## Step 6: Secret Network Configuration (Optional)

### Configure for Secret Network Mainnet
To deploy on Secret Network mainnet, update the environment variables in `docker-compose.ecr.yml`:

```yaml
environment:
  # Secret Network Mainnet Configuration
  - CHAIN_ID=secret-4
  - MONIKER=your-secret-node-name
  - GENESIS_URL=https://github.com/scrtlabs/SecretNetwork/releases/latest/download/genesis.json
  - PERSISTENT_PEERS=bee0edb320d50c1bcb6bd59b4e04456d459bd70e@secret-4.node.enigma.co:26656,4ca26a20aaa042d0073ad4b685ef5b4c3e4a0e6d@secret-4.node.enigma.co:26656
```

Then restart the container:
```bash
docker-compose -f docker-compose.ecr.yml down
docker-compose -f docker-compose.ecr.yml up -d
```

## Troubleshooting

### Container Build Issues
```bash
# If build fails, check Docker resources
docker system df
docker system prune -f

# Build with more verbose output
docker build -f Dockerfile.production -t cintara-unified:latest . --progress=plain
```

### Container Runtime Issues
```bash
# Check container logs
docker-compose -f docker-compose.ecr.yml logs cintara-unified-ecr

# Check individual service logs inside container
docker exec -it cintara-unified-production bash
supervisorctl status
tail -f /var/log/supervisor/*.log
```

### Network Issues
```bash
# Check port accessibility
netstat -tlnp | grep -E "(26657|8000|8080)"

# Test internal service communication
docker exec -it cintara-unified-production curl localhost:8000/health
docker exec -it cintara-unified-production curl localhost:26657/status
```

## Production Considerations

### Security
- Use AWS IAM roles with minimal ECR permissions
- Configure firewall rules to restrict access to necessary ports
- Regular security updates and image rebuilds

### Monitoring
- Set up CloudWatch logging for ECR and container metrics
- Configure health check alerts
- Monitor blockchain synchronization status

### Scaling
- Consider using AWS ECS or EKS for production deployments
- Implement load balancing for AI bridge service
- Use AWS RDS or managed storage for blockchain data

## Files Summary
- `Dockerfile.production`: Production-ready container with all services preconfigured
- `docker-compose.ecr.yml`: Docker Compose configuration for ECR deployment
- This guide: Complete deployment instructions

The container includes:
1. **Cintara Node**: Fully configured and ready to sync
2. **LLaMA.cpp Server**: TinyLlama model for AI inference
3. **AI Bridge**: FastAPI service connecting blockchain and AI
4. **Supervisor**: Process management for all services
5. **Health Checks**: Comprehensive service monitoring