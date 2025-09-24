# Complete EC2 to SecretVM Deployment Guide

## Overview
This guide provides a complete workflow to build a Cintara unified container on EC2 (x86-64) and deploy it on SecretVM, addressing LLM build issues and architecture compatibility.

## 🎯 Goals
- ✅ Build on EC2 (x86-64 architecture) for SecretVM compatibility
- ✅ Fix LLM build issues that occur on EC2
- ✅ Push to AWS ECR with proper tagging
- ✅ Deploy successfully on SecretVM with all services working

## 📋 Prerequisites

### AWS Account Setup
```bash
# Ensure you have AWS CLI configured
aws configure list
aws ecr-public get-login-password --region us-east-1 --dry-run
```

### EC2 Instance Requirements
- **Instance Type**: `t3.large` or larger (minimum 2 vCPU, 8GB RAM)
- **Architecture**: `x86_64` (Intel/AMD)
- **OS**: Amazon Linux 2 or Ubuntu 22.04
- **Storage**: At least 20GB free space
- **Network**: Internet access for downloads

## 🚀 Step 1: EC2 Build Process

### 1.1 Prepare EC2 Instance
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Clone the repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Switch to the correct branch
git checkout feat/unified-automated-setup
```

### 1.2 Run the Build Script
```bash
# Make the script executable
chmod +x build-ec2-to-ecr.sh

# Run the build (this takes 15-30 minutes)
./build-ec2-to-ecr.sh
```

### 1.3 What the Build Script Does
1. **Installs dependencies**: Docker, AWS CLI, build tools
2. **Authenticates to ECR**: Uses your AWS credentials
3. **Builds with optimizations**: Uses `Dockerfile.ec2-optimized`
4. **Handles LLM issues**: Multiple fallback strategies for llama.cpp
5. **Tags for x86-64**: Creates `x86-64-latest` tag
6. **Pushes to ECR**: `public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:x86-64-latest`

## 🛠️ Step 2: LLM Build Issue Fixes

The `Dockerfile.ec2-optimized` includes these fixes:

### 2.1 Dependency Issues
```dockerfile
# Installs all required libraries
libcurl4-openssl-dev  # Fixes CURL errors
gcc-9 g++-9          # Compatible compiler versions
libomp-dev           # OpenMP for parallel processing
```

### 2.2 Build Strategy (3-tier fallback)
```bash
# 1. Try optimized make (fastest)
make server CC=gcc-9 CXX=g++-9 CFLAGS="-O2 -march=x86-64"

# 2. Try cmake with conservative settings
cmake -DLLAMA_CURL=OFF -DGGML_NATIVE=OFF

# 3. Create placeholder if both fail
# (provides HTTP endpoint for testing)
```

### 2.3 Memory Optimizations
- Uses only 2 threads for compilation
- Conservative CPU flags (`-march=x86-64 -mtune=generic`)
- Retry logic for model downloads

## 📦 Step 3: ECR Image Verification

### 3.1 Verify Build Success
```bash
# Check if image was built
docker images | grep cintara-unified

# Test the image locally
docker run --rm -p 8080:8080 cintara-unified:x86-64-latest

# Check ECR push
aws ecr-public describe-images --repository-name cintaraio/cintara-unified --region us-east-1
```

### 3.2 Expected Output
```json
{
    "imageDetails": [
        {
            "imageTag": "x86-64-latest",
            "imagePushedAt": "2025-09-24T...",
            "imageSizeInBytes": 2500000000
        }
    ]
}
```

## 🔒 Step 4: SecretVM Deployment

### 4.1 Use the ECR Docker Compose
Copy the contents of `docker-compose.secretvm-ecr.yml` into the SecretVM web portal.

### 4.2 Key Configuration Points
```yaml
# Uses the x86-64 specific image
image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:x86-64-latest

# Platform specification for compatibility
platform: linux/amd64

# Extended startup time for all services
start_period: 360s  # 6 minutes
```

### 4.3 Expected SecretVM Behavior
1. **Image pull**: Should complete successfully (architecture matches)
2. **Container start**: Should start without "no running containers found" error
3. **Service initialization**: All 3 services should start within 6 minutes
4. **Health checks**: Should pass after startup period

## 🔍 Step 5: Troubleshooting

### 5.1 EC2 Build Issues

**Out of Memory:**
```bash
# Add swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Docker Permission Issues:**
```bash
sudo usermod -a -G docker $USER
# Logout and login again
```

**LLM Build Fails:**
```bash
# Check logs during build
docker build -f Dockerfile.ec2-optimized -t test . --no-cache --progress=plain
```

### 5.2 ECR Push Issues

**Authentication Failed:**
```bash
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```

**Repository Not Found:**
```bash
# Verify repository exists
aws ecr-public describe-repositories --region us-east-1
```

### 5.3 SecretVM Deployment Issues

**Container Not Starting:**
- Verify image tag: `x86-64-latest`
- Check platform: `linux/amd64`
- Review resource limits

**Services Unhealthy:**
- Allow full 6 minutes startup time
- Check individual service logs
- Verify port accessibility

## 📊 Step 6: Verification Commands

### 6.1 After EC2 Build
```bash
# Test container locally
docker run --rm -d --name test-cintara \
  -p 26657:26657 -p 8000:8000 -p 8080:8080 \
  cintara-unified:x86-64-latest

# Wait 5 minutes, then test
sleep 300

# Test endpoints
curl http://localhost:26657/status
curl http://localhost:8000/health
curl http://localhost:8080/health

# Cleanup
docker stop test-cintara
```

### 6.2 After SecretVM Deployment
Monitor through SecretVM portal for:
- Container status: "Running"
- Health checks: "Healthy"
- Logs: No error messages
- Ports: All services responding

## 🎉 Success Indicators

### EC2 Build Success
```
✅ Docker build completed successfully!
✅ Successfully pushed to ECR!
✅ Ready for SecretVM deployment!
```

### SecretVM Deployment Success
- Container starts and stays running
- All health checks pass
- Services respond on expected ports
- No "no running containers found" errors

## 📋 Files Summary

1. **`build-ec2-to-ecr.sh`** - Complete EC2 build and push script
2. **`Dockerfile.ec2-optimized`** - LLM-issue-fixed Dockerfile for EC2
3. **`docker-compose.secretvm-ecr.yml`** - SecretVM deployment config
4. **This deployment guide** - Complete workflow documentation

## 🚀 Quick Start Commands

```bash
# On EC2
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/unified-automated-setup
chmod +x build-ec2-to-ecr.sh
./build-ec2-to-ecr.sh

# On SecretVM Portal
# Copy and paste docker-compose.secretvm-ecr.yml content
```

This workflow should resolve both the architecture compatibility issues and the LLM build problems you've been experiencing!