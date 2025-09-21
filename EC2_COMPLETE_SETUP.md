# 🚀 Complete EC2 Setup Guide - Cintara Node + LLM + AI Bridge

**Complete setup for running Cintara blockchain node, LLM server, and AI bridge on a single EC2 instance**

## 📋 Prerequisites

- **EC2 Instance**: t3.large or larger (4 vCPU, 8GB RAM minimum)
- **Storage**: 50GB+ EBS storage
- **SSM Access**: AWS Systems Manager Session Manager configured
- **Security Group**: Ports 22, 26656, 26657, 1317, 8000, 8080 open

---

## 🔧 **Step 1: Initial EC2 Setup**

### **1.1 Connect via SSM and switch to root**
```bash
# Connect via AWS SSM Session Manager
# In your SSM session, switch to root
sudo su -
cd /root
```

### **1.2 Update system and install Docker**
```bash
# Update system packages
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### **1.3 Create required directories**
```bash
# Create data directories with proper permissions
mkdir -p /data /home/cintara/data
chmod 755 /data /home/cintara/data
```

---

## 📂 **Step 2: Clone and Configure Project**

### **2.1 Clone the repository**
```bash
# Clone project
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Switch to the latest branch with all updates
git checkout feat/github-wf
```

### **2.2 Configure environment**
```bash
# Create .env file from example
cp .env.example .env

# Optional: Edit configuration
nano .env
# Adjust MONIKER, LLM_THREADS, CTX_SIZE as needed
```

---

## 🔗 **Step 3: Deploy Cintara Node (Interactive Setup)**

### **3.1 Run Cintara node interactively for first-time setup**
```bash
# Pull the latest Cintara node image
docker pull public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# Run interactively for initial setup
docker run -it \
  --name cintara-blockchain-node \
  -p 26657:26657 \
  -p 26656:26656 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=ec2-cintara-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest
```

### **3.2 Interactive setup responses**
```bash
# When prompted, respond as follows:
# 1. "Enter the Name for the node:" → Press Enter (uses MONIKER)
# 2. "Overwrite existing configuration? [y/n]" → Type: y

# Wait for messages like:
# ✅ "cintarad installed or updated successfully!"
# ✅ "started node"

# Once you see the node running, press Ctrl+C to stop
```

### **3.3 Restart in background mode**
```bash
# Remove the interactive container
docker rm cintara-blockchain-node

# Run in detached mode
docker run -d \
  --name cintara-blockchain-node \
  --restart unless-stopped \
  -p 26657:26657 \
  -p 26656:26656 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=ec2-cintara-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# Verify node is running
docker logs -f cintara-blockchain-node
```

---

## 🤖 **Step 4: Deploy LLM Server and AI Bridge**

### **4.1 Start LLM and AI Bridge services**
```bash
# Start remaining services using docker-compose
docker-compose up -d

# Monitor startup
docker-compose logs -f model-downloader  # Watch model download (2-3 minutes)
docker-compose logs -f llama             # Watch LLM server startup
docker-compose logs -f bridge            # Watch AI bridge startup
```

### **4.2 Verify all services**
```bash
# Check all containers are running
docker ps

# Should see:
# - cintara-blockchain-node
# - cintara-llm
# - cintara-ai-bridge
# - cintara-model-downloader (completed)
```

---

## ✅ **Step 5: Verification and Testing**

### **5.1 Test individual services**
```bash
# Test Cintara node
curl -s http://localhost:26657/status | jq .result.sync_info

# Test LLM server
curl -s http://localhost:8000/health

# Test AI bridge
curl -s http://localhost:8080/health
```

### **5.2 Test AI functionality**
```bash
# Test AI chat functionality
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, what is the current block height?"}'

# Test blockchain analysis
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "network status"}'
```

### **5.3 Check sync status**
```bash
# Monitor blockchain sync progress
watch -n 5 'curl -s http://localhost:26657/status | jq .result.sync_info'

# Look for:
# - "catching_up": true (syncing)
# - "latest_block_height": increasing numbers
```

---

## 📊 **Step 6: Monitoring and Management**

### **6.1 View logs**
```bash
# Cintara node logs
docker logs -f cintara-blockchain-node

# All service logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f llama
docker-compose logs -f bridge
```

### **6.2 Service management**
```bash
# Stop all services
docker stop cintara-blockchain-node
docker-compose down

# Start all services
docker start cintara-blockchain-node
docker-compose up -d

# Restart specific service
docker restart cintara-blockchain-node
docker-compose restart llama
```

### **6.3 Resource monitoring**
```bash
# Check Docker resource usage
docker stats

# Check system resources
htop
df -h
```

---

## 🌐 **Step 7: External Access (Optional)**

### **7.1 Configure security group**
If you want external access, ensure your EC2 security group allows:
- **26657**: Cintara RPC
- **1317**: Cintara API
- **8000**: LLM Server
- **8080**: AI Bridge

### **7.2 Test external access**
```bash
# Get your EC2 public IP
curl -s http://checkip.amazonaws.com

# Test from external machine
curl http://YOUR-EC2-IP:26657/status
curl http://YOUR-EC2-IP:8080/health
```

---

## 🎯 **Available Endpoints**

Once fully deployed, your EC2 instance provides:

| Service | Endpoint | Description |
|---------|----------|-------------|
| **Cintara RPC** | `http://localhost:26657` | Blockchain RPC interface |
| **Cintara API** | `http://localhost:1317` | REST API interface |
| **LLM Server** | `http://localhost:8000` | AI model inference |
| **AI Bridge** | `http://localhost:8080` | AI-powered blockchain analysis |

---

## 🚨 **Troubleshooting**

### **Common Issues:**

**Node won't start:**
```bash
# Check logs
docker logs cintara-blockchain-node

# Clean and restart
docker stop cintara-blockchain-node && docker rm cintara-blockchain-node
rm -rf /data/.tmp-cintarad
# Then repeat Step 3
```

**LLM model download fails:**
```bash
# Check internet connectivity
curl -I https://huggingface.co

# Restart model downloader
docker-compose restart model-downloader
```

**Services can't connect:**
```bash
# Check Docker networks
docker network ls
docker network inspect cintara-node-llm-bridge_cintara-network

# Restart all services
docker-compose down && docker-compose up -d
```

---

## 🎉 **Success Indicators**

You know everything is working when:
- ✅ All containers show "Up" status: `docker ps`
- ✅ Cintara node is syncing: `curl localhost:26657/status | jq .result.sync_info.catching_up` returns `true`
- ✅ LLM responds: `curl localhost:8000/health` returns success
- ✅ AI bridge responds: `curl localhost:8080/health` returns success
- ✅ Block height increases over time

**🎯 Your complete Cintara ecosystem is now running on EC2!**