# 🚀 Unified Cintara Node - Single Image Setup

**Complete Cintara ecosystem in one Docker image with ZERO interactive prompts**

## 📋 **What You Get**
- Cintara blockchain node (automatically configured)
- LLM server (TinyLlama)
- AI bridge service
- All in ONE container
- **NO manual setup required**

## ⚡ **Super Simple Setup (2 Steps)**

### **Step 1: Get the Code & Install Docker**
```bash
# Connect to EC2 via SSM, then:
sudo su -
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/github-wf

# Install Docker
curl -fsSL https://get.docker.com | sh
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### **Step 2: Start Everything**

**Default: Fully Automated (Recommended)**
```bash
# Build and start the fully automated container
docker-compose up -d

# Wait 5-10 minutes for complete initialization
# NO manual intervention required!
```

**Alternative: Manual Setup (if needed)**
```bash
# Build and start the manual setup container
docker-compose -f docker-compose.manual.yml up -d

# Wait 5-10 minutes for complete initialization
```

## ✅ **Verify Everything Works**
```bash
# Test all services (wait 10 minutes after step 2)
curl http://localhost:26657/status    # Cintara node
curl http://localhost:8000/health     # LLM server
curl http://localhost:8080/health     # AI bridge

# All should return JSON responses
```

## 🔍 **Check Logs**

**For Default Automated Version:**
```bash
# View all logs
docker-compose logs

# View specific service logs
docker exec cintara-unified-automated supervisorctl status
docker exec cintara-unified-automated tail -f /var/log/supervisor/cintara-node.out.log
docker exec cintara-unified-automated tail -f /var/log/supervisor/llama-server.out.log
docker exec cintara-unified-automated tail -f /var/log/supervisor/ai-bridge.out.log
```

**For Manual Setup Version:**
```bash
# View all logs
docker-compose -f docker-compose.manual.yml logs

# View specific service logs
docker exec cintara-unified-node supervisorctl status
docker exec cintara-unified-node tail -f /var/log/supervisor/cintara-node.out.log
docker exec cintara-unified-node tail -f /var/log/supervisor/llama-server.out.log
docker exec cintara-unified-node tail -f /var/log/supervisor/ai-bridge.out.log
```

## 🛠 **Management Commands**

**For Default Automated Version:**
```bash
# Stop everything
docker-compose down

# Restart everything
docker-compose restart

# Update and rebuild
git pull
docker-compose build --no-cache
docker-compose up -d
```

**For Manual Setup Version:**
```bash
# Stop everything
docker-compose -f docker-compose.manual.yml down

# Restart everything
docker-compose -f docker-compose.manual.yml restart

# Update and rebuild
git pull
docker-compose -f docker-compose.manual.yml build --no-cache
docker-compose -f docker-compose.manual.yml up -d
```

## 📊 **Resource Usage**
- **CPU**: 2-4 cores recommended
- **RAM**: 4-6 GB required
- **Storage**: ~10 GB for blockchain data + models
- **Network**: Ports 26656, 26657, 1317, 9090, 8000, 8080

## 🔄 **Migration from Multi-Container Setup**
If you have the old multi-container setup:
```bash
# Stop old containers
docker stop cintara-blockchain-node
docker-compose down

# Start new unified container
docker-compose up -d
```

---
**🎉 That's it! Your complete Cintara ecosystem is running in one container.**