# 🚀 Deployment Guide - Pre-built Images

This guide covers deploying the Cintara AI Bridge using pre-built Docker images from GitHub Container Registry (GHCR).

## 🎯 **Current Workflow**

### **For Developers/Maintainers:**
1. **Code Changes** → Push to GitHub
2. **GitHub Actions** → Automatically builds & pushes images to GHCR
3. **Images Available** → `ghcr.io/cintaraio/cintara-node:latest` & `ghcr.io/cintaraio/cintara-ai-bridge:latest`

### **For Users:**
1. **Clone Repository** → Get latest docker-compose.yml
2. **Run `docker compose up -d`** → Uses pre-built images (no build time!)
3. **Enjoy** → Complete Cintara ecosystem running in minutes

---

## 📦 **Step 1: Initial Setup (For Maintainers)**

### **Manual Build & Push to GHCR**

```bash
# 1. Authenticate with GitHub Container Registry
gh auth token | docker login ghcr.io -u $(gh api user --jq .login) --password-stdin

# 2. Build and push images manually (first time)
./scripts/manual-build-ghcr.sh

# 3. Verify images are available
docker pull ghcr.io/cintaraio/cintara-node:latest
docker pull ghcr.io/cintaraio/cintara-ai-bridge:latest
```

### **Automated Builds (GitHub Actions)**

Once the GitHub repository is set up, images will be automatically built and pushed on:
- ✅ **Push to main branch**
- ✅ **Pull requests**
- ✅ **Tagged releases**
- ✅ **Manual workflow dispatch**

---

## 🏃‍♂️ **Step 2: User Deployment**

### **Quick Start (End Users)**

```bash
# 1. Clone repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# 2. Optional: Configure environment
cp .env.example .env
# Edit .env if needed (node name, etc.)

# 3. Start all services (uses pre-built images)
docker compose up -d

# 4. Monitor startup
docker compose logs -f cintara-node      # Watch blockchain sync
docker compose logs -f model-downloader  # Watch model download

# 5. Verify deployment
curl http://localhost:26657/status | jq .result.sync_info  # Cintara Node
curl http://localhost:8000/health                          # LLM Server
curl http://localhost:8080/health                          # AI Bridge
```

**🎯 Result**: Complete Cintara ecosystem running with zero build time!

---

## 🏷️ **Image Versioning**

### **Available Tags**

| Tag | Description | Use Case |
|-----|-------------|----------|
| `latest` | Latest stable from main branch | Production |
| `main` | Latest development build | Testing |
| `v1.0.0` | Specific release version | Production (pinned) |
| `pr-123` | Pull request build | Feature testing |

### **Version Pinning (Recommended for Production)**

```bash
# Pin to specific versions in .env
echo "CINTARA_NODE_IMAGE=ghcr.io/cintaraio/cintara-node:v1.0.0" >> .env
echo "BRIDGE_IMAGE=ghcr.io/cintaraio/cintara-ai-bridge:v1.0.0" >> .env

# Deploy with pinned versions
docker compose up -d
```

---

## 🔄 **CI/CD Pipeline Details**

### **GitHub Actions Workflow**

**File**: `.github/workflows/build-and-push.yml`

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Release tags (`v*`)
- Manual workflow dispatch

**Features**:
- ✅ **Multi-platform builds** (linux/amd64, linux/arm64)
- ✅ **Automatic image tagging** (branch, PR, semver)
- ✅ **Security scanning** with Trivy
- ✅ **Cache optimization** for faster builds
- ✅ **Auto-update** docker-compose.yml with latest tags

**Build Matrix**:
```yaml
matrix:
  image:
    - name: cintara-node
      context: ./cintara-node
    - name: cintara-ai-bridge
      context: ./bridge
```

### **Automatic Updates**

When code is pushed to `main`:
1. Images are built and pushed to GHCR
2. `docker-compose.yml` is automatically updated with new image references
3. Users get latest images on next `docker compose pull`

---

## 🌐 **Image Registry Options**

### **Primary: GitHub Container Registry (GHCR)**
```yaml
# Default configuration
CINTARA_NODE_IMAGE: ghcr.io/cintaraio/cintara-node:latest
BRIDGE_IMAGE: ghcr.io/cintaraio/cintara-ai-bridge:latest
```

**Benefits**:
- ✅ Free for public repositories
- ✅ Integrated with GitHub Actions
- ✅ Multi-platform support
- ✅ Excellent performance

### **Alternative: Docker Hub**
```yaml
# If you prefer Docker Hub
CINTARA_NODE_IMAGE: cintaraio/cintara-node:latest
BRIDGE_IMAGE: cintaraio/cintara-ai-bridge:latest
```

**To push to Docker Hub**:
```bash
# Login to Docker Hub
docker login

# Build and push
REGISTRY=cintaraio ./scripts/build-images.sh
```

---

## 🔒 **Security & Compliance**

### **Image Security**
- ✅ **Base Images**: Official Ubuntu 22.04 & Python 3.11-slim
- ✅ **Vulnerability Scanning**: Trivy scans in CI/CD
- ✅ **Weekly Rebuilds**: Automatic security updates
- ✅ **Minimal Attack Surface**: Only necessary packages installed

### **Access Control**
- ✅ **Public Images**: No authentication required for pulling
- ✅ **Push Access**: Restricted to repository maintainers
- ✅ **GitHub Token**: Automatic authentication in workflows

---

## 🚀 **Production Deployment**

### **Recommended Production Setup**

```yaml
# production.env
CINTARA_NODE_IMAGE=ghcr.io/cintaraio/cintara-node:v1.0.0
BRIDGE_IMAGE=ghcr.io/cintaraio/cintara-ai-bridge:v1.0.0
MONIKER=prod-validator-01
CHAIN_ID=cintara_11001-1
LLM_THREADS=8
CTX_SIZE=4096
```

```bash
# Deploy with production config
docker compose --env-file production.env up -d

# Monitor
docker compose ps
docker compose logs -f
```

### **Health Monitoring**

```bash
# Automated health checks
#!/bin/bash
curl -f http://localhost:26657/status || exit 1  # Cintara Node
curl -f http://localhost:8000/health || exit 1   # LLM Server
curl -f http://localhost:8080/health || exit 1   # AI Bridge
echo "All services healthy"
```

---

## 🔧 **Troubleshooting**

### **Image Pull Issues**

```bash
# Check if images exist
docker pull ghcr.io/cintaraio/cintara-node:latest
docker pull ghcr.io/cintaraio/cintara-ai-bridge:latest

# Fall back to local build if needed
./scripts/build-local.sh
echo "CINTARA_NODE_IMAGE=cintaraio/cintara-node:latest" >> .env
echo "BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest" >> .env
```

### **Version Mismatch**

```bash
# Check current image versions
docker images | grep cintara

# Update to latest
docker compose pull
docker compose up -d
```

### **Build from Source (Fallback)**

```bash
# If pre-built images are unavailable
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Build locally
./scripts/build-local.sh

# Use local images
echo "CINTARA_NODE_IMAGE=cintaraio/cintara-node:latest" > .env
echo "BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest" >> .env

# Deploy
docker compose up -d
```

---

## 📊 **Performance Benefits**

### **Deployment Speed Comparison**

| Method | Build Time | Download Time | Total Time |
|--------|------------|---------------|------------|
| **Local Build** | 15-30 min | 0 | 15-30 min |
| **Pre-built Images** | 0 | 2-5 min | 2-5 min |

### **Resource Usage**

| Resource | Local Build | Pre-built Images |
|----------|-------------|------------------|
| **CPU** | High (compilation) | Low (download only) |
| **Memory** | 4-8GB | 1-2GB |
| **Network** | Moderate | High (image download) |
| **Storage** | Build cache + images | Images only |

---

## ✅ **Success Checklist**

### **For Maintainers**
- [ ] Images built and pushed to GHCR
- [ ] GitHub Actions workflow working
- [ ] Security scanning enabled
- [ ] Documentation updated

### **For Users**
- [ ] Repository cloned
- [ ] Pre-built images pulled successfully
- [ ] All services start without build time
- [ ] Health checks pass
- [ ] AI functionality working

---

This deployment strategy provides the best user experience with instant deployment while maintaining full control over the build process through automated CI/CD.