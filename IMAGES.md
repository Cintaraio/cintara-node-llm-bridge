# 🐳 Pre-built Docker Images

This document outlines the pre-built Docker image strategy for the Cintara AI Bridge project.

## 📦 Available Images

### **Cintara Node Image**
- **Registry**: `ghcr.io/cintaraio/cintara-node`
- **Description**: Complete Cintara blockchain node with P2P networking
- **Base**: Ubuntu 22.04 with Go 1.21.6
- **Features**: Auto-initialization, testnet connection, validator capabilities

### **AI Bridge Image**
- **Registry**: `ghcr.io/cintaraio/cintara-ai-bridge`
- **Description**: FastAPI bridge connecting LLM to Cintara node
- **Base**: Python 3.11-slim
- **Features**: REST API, AI analysis, health monitoring

## 🏷️ Image Tags

| Tag | Description | Usage |
|-----|-------------|-------|
| `latest` | Latest stable release | Production deployments |
| `main` | Latest development build | Testing latest features |
| `v1.0.0` | Specific version | Production (version pinning) |
| `pr-123` | Pull request builds | Feature testing |

## 🏗️ Building Images

### **Manual Local Build**
```bash
# Build both images locally
./scripts/build-local.sh

# Build with custom registry
REGISTRY=myregistry ./scripts/build-local.sh
```

### **Production Build & Push**
```bash
# Build and push to GitHub Container Registry
./scripts/build-images.sh

# Build specific version
VERSION=v1.0.0 ./scripts/build-images.sh

# Build for multiple platforms
PLATFORMS=linux/amd64,linux/arm64 ./scripts/build-images.sh
```

## 🚀 Automated CI/CD

### **GitHub Actions Workflows**

1. **`.github/workflows/build-images.yml`**
   - **Triggers**: Push to main/develop, PRs, weekly schedule
   - **Actions**: Build and push images for both architectures
   - **Platforms**: linux/amd64, linux/arm64
   - **Registry**: GitHub Container Registry (GHCR)

2. **`.github/workflows/release.yml`**
   - **Triggers**: GitHub releases
   - **Actions**: Build release images with proper versioning
   - **Features**: Automatic release notes with image info

### **Build Process**
1. Code pushed to GitHub
2. GitHub Actions triggered
3. Multi-platform images built
4. Images pushed to GHCR
5. Docker Compose files updated (main branch)

## 🌐 Registry Options

### **Recommended: GitHub Container Registry (GHCR)**
- **URL**: `ghcr.io/cintaraio/`
- **Benefits**:
  - ✅ Free for public repositories
  - ✅ Integrated with GitHub Actions
  - ✅ Excellent performance
  - ✅ Multi-platform support
  - ✅ Fine-grained permissions

### **Alternative Options**

#### **Docker Hub**
- **URL**: `docker.io/cintaraio/` or `cintaraio/`
- **Benefits**: Most popular, great discoverability
- **Limitations**: Pull rate limits for anonymous users
- **Cost**: Free tier available

#### **AWS ECR Public**
- **URL**: `public.ecr.aws/cintaraio/`
- **Benefits**: High performance, AWS integration
- **Good for**: Production AWS deployments

#### **Quay.io**
- **URL**: `quay.io/cintaraio/`
- **Benefits**: Security scanning, good UI
- **Features**: Vulnerability analysis

## 📋 Usage Examples

### **Default Setup (GHCR)**
```bash
# Uses pre-built images from GHCR
docker compose up -d
```

### **Specific Version**
```bash
# Set specific versions in .env
echo "CINTARA_NODE_IMAGE=ghcr.io/cintaraio/cintara-node:v1.0.0" >> .env
echo "BRIDGE_IMAGE=ghcr.io/cintaraio/cintara-ai-bridge:v1.0.0" >> .env
docker compose up -d
```

### **Docker Hub Alternative**
```bash
# Use Docker Hub images
echo "CINTARA_NODE_IMAGE=cintaraio/cintara-node:latest" >> .env
echo "BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest" >> .env
docker compose up -d
```

### **Local Development**
```bash
# Build and use local images
./scripts/build-local.sh
echo "CINTARA_NODE_IMAGE=cintaraio/cintara-node:latest" >> .env
echo "BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest" >> .env
docker compose up -d
```

## 🔒 Security & Maintenance

### **Image Security**
- **Base Images**: Official Ubuntu and Python images
- **Updates**: Weekly automated rebuilds for security patches
- **Scanning**: Automatic vulnerability scanning in CI
- **Signing**: Images signed with GitHub's Sigstore

### **Maintenance Schedule**
- **Weekly**: Automated security rebuilds
- **Monthly**: Dependency updates
- **On Release**: Tagged stable versions
- **On Demand**: Hotfix builds when needed

## 🎯 Benefits of Pre-built Images

✅ **Fast Deployment** - No build time, instant pulls
✅ **Consistent Environment** - Same images across all deployments
✅ **Multi-Architecture** - ARM64 and AMD64 support
✅ **Security Updates** - Automated weekly rebuilds
✅ **Version Control** - Specific version pinning available
✅ **Easy Distribution** - Simple docker compose setup
✅ **CI/CD Ready** - Automated builds and testing
✅ **Production Ready** - Optimized and hardened images

## 🔧 Environment Variables

Configure which images to use via environment variables:

```bash
# GitHub Container Registry (default)
CINTARA_NODE_IMAGE=ghcr.io/cintaraio/cintara-node:latest
BRIDGE_IMAGE=ghcr.io/cintaraio/cintara-ai-bridge:latest

# Docker Hub
CINTARA_NODE_IMAGE=cintaraio/cintara-node:latest
BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest

# AWS ECR Public
CINTARA_NODE_IMAGE=public.ecr.aws/cintaraio/cintara-node:latest
BRIDGE_IMAGE=public.ecr.aws/cintaraio/cintara-ai-bridge:latest

# Quay.io
CINTARA_NODE_IMAGE=quay.io/cintaraio/cintara-node:latest
BRIDGE_IMAGE=quay.io/cintaraio/cintara-ai-bridge:latest
```

This approach eliminates build times and ensures consistent, secure deployments across all environments.