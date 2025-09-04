# 🔧 Smart Cintara Node: Complete Setup and Verification Guide

This guide provides step-by-step instructions for setting up and verifying the Smart Cintara Node with AI/LLM integration, including comprehensive health checks and functionality testing.

## 🎯 Overview

The Smart Cintara Node combines:
- **Cintara Blockchain Node** (Manual setup) - Port 26657
- **LLM Server** (Docker) - Port 8000  
- **AI Bridge** (Docker) - Port 8080

The AI Bridge analyzes Cintara node logs, provides intelligent diagnostics, and offers blockchain insights through LLM-powered analysis.

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Ubuntu 22.04** (recommended) or macOS
- [ ] **8GB+ RAM, 50GB+ storage**
- [ ] **Docker and Docker Compose installed**
- [ ] **Internet connection** (for model download ~4GB)
- [ ] **Basic Linux/terminal knowledge**

### Install Docker (if not already installed)

**Ubuntu:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**macOS:**
```bash
brew install --cask docker
# Or download Docker Desktop from docker.com
```

---

## 🚀 Complete Setup Process

### Step 1: Setup Cintara Node (Manual)

```bash
# Run the automated setup script
./scripts/setup-cintara-node.sh
```

**During setup, you'll be prompted for:**
1. Node name (e.g., "my-smart-node")
2. Keyring password (minimum 8 characters)
3. **Important:** Save the mnemonic phrase securely!

**Verify Cintara node is running:**
```bash
curl -s http://localhost:26657/status | jq .sync_info
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Required settings in `.env`:**
```bash
# Model configuration
MODEL_FILE=mistral-7b-instruct.Q4_K_M.gguf
LLM_THREADS=8
CTX_SIZE=2048

# Cintara node connection
CINTARA_NODE_URL=http://localhost:26657
```

### Step 3: Download LLM Model

```bash
# Create models directory
mkdir -p models
cd models

# Download Mistral 7B model (~4GB - may take 5-10 minutes)
echo "📥 Downloading LLM model (this may take several minutes)..."
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf

# Verify download
ls -lh mistral-7b-instruct.Q4_K_M.gguf
cd ..
```

### Step 4: Start LLM and AI Bridge Services

```bash
# Start Docker services
docker compose up -d

# Check service status
docker compose ps
```

**Expected output:**
```
NAME                           COMMAND                  SERVICE             STATUS
cintara-node-llm-bridge-llama-1   "/llama-server --mod…"   llama               running
cintara-node-llm-bridge-bridge-1  "python app.py"         bridge              running
```

---

## ✅ Comprehensive Verification Process

### Quick Health Check

Run the automated test suite:
```bash
./scripts/test-llm-functionality.sh
```

### Manual Step-by-Step Verification

#### 1. Verify Cintara Node

```bash
# Basic health check
curl -s http://localhost:26657/health | jq .

# Detailed node status
curl -s http://localhost:26657/status | jq .sync_info

# Check if syncing is complete
curl -s http://localhost:26657/status | jq .sync_info.catching_up
# Should return: false (when fully synced)
```

#### 2. Verify LLM Server

```bash
# Health check
curl -s http://localhost:8000/health

# List available models
curl -s http://localhost:8000/v1/models | jq .

# Test text completion
curl -s -X POST http://localhost:8000/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt":"The blockchain is","max_tokens":20}' | jq .
```

#### 3. Verify AI Bridge

```bash
# Health check
curl -s http://localhost:8080/health | jq .

# Test connection to Cintara node through bridge
curl -s http://localhost:8080/node/status | jq .
```

---

## 🧠 AI-Powered Cintara Node Analysis

### 1. Intelligent Node Diagnostics

Get AI-powered analysis of your node's health:

```bash
curl -s -X POST http://localhost:8080/node/diagnose | jq .
```

**Example response:**
```json
{
  "diagnosis": "Node is healthy and fully synchronized. Peer connectivity is optimal with 15 connected peers. Block production is consistent with network average.",
  "recommendations": ["Consider monitoring peer diversity", "Set up alerting for sync status changes"],
  "health_score": 95,
  "timestamp": "2024-09-04T14:30:00Z"
}
```

### 2. Transaction Analysis with AI

Analyze transactions using LLM insights:

```bash
curl -s -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "hash": "0xabc123...",
      "amount": "1000",
      "from": "cintara1abc...",
      "to": "cintara1def...",
      "gas": "21000"
    }
  }' | jq .
```

### 3. Intelligent Log Analysis

Get AI-powered analysis of Cintara node logs:

```bash
# Get recent logs with AI analysis
curl -s http://localhost:8080/node/logs | jq .

# Get specific log analysis
curl -s -X POST http://localhost:8080/node/logs/analyze \
  -H "Content-Type: application/json" \
  -d '{"lines": 100, "level": "error"}' | jq .
```

### 4. Interactive AI Chat

Ask the AI about your node:

```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the current status of my Cintara node?"}' | jq .
```

**Example questions to ask:**
- "What is the current status of my Cintara node?"
- "Are there any issues I should be concerned about?"
- "How is my node's performance compared to the network?"
- "What maintenance should I perform?"

---

## 📊 Monitoring and Maintenance

### Real-time Monitoring

Monitor your Smart Cintara Node:

```bash
# Watch Docker logs in real-time
docker compose logs -f

# Monitor specific services
docker compose logs -f llama    # LLM server logs
docker compose logs -f bridge   # AI bridge logs

# Monitor Cintara node (location varies by setup)
journalctl -u cintarad -f  # if running as systemd service
```

### Performance Metrics

Check system resource usage:

```bash
# Docker container stats
docker stats

# System resources
htop  # or top

# Disk usage
df -h
du -sh models/  # Check model file size
```

### Health Monitoring Script

Create a monitoring script:

```bash
#!/bin/bash
# save as monitor.sh

echo "🔍 Smart Cintara Node Health Check"
echo "================================="

# Cintara Node
if curl -s http://localhost:26657/status > /dev/null; then
    echo "✅ Cintara Node: Healthy"
    SYNC=$(curl -s http://localhost:26657/status | jq -r .sync_info.catching_up)
    echo "   Sync Status: $([ "$SYNC" = "false" ] && echo "✅ Synced" || echo "⏳ Syncing")"
else
    echo "❌ Cintara Node: Down"
fi

# LLM Server
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ LLM Server: Healthy"
else
    echo "❌ LLM Server: Down"
fi

# AI Bridge
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ AI Bridge: Healthy"
else
    echo "❌ AI Bridge: Down"
fi
```

---

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: "Cintara node not responding"

```bash
# Check if cintarad process is running
ps aux | grep cintarad

# If not running, start it
cd ~/cintara-node/cintara-testnet-script
# Follow the restart instructions from the official script

# Check node logs for errors
journalctl -u cintarad -n 50
```

#### Issue: "LLM server not starting"

```bash
# Check Docker logs
docker compose logs llama

# Common causes:
# 1. Model file missing or wrong name in .env
ls -la models/
grep MODEL_FILE .env

# 2. Insufficient memory
free -h  # Should have 8GB+ available

# 3. Port conflict
sudo netstat -tlnp | grep :8000

# Restart LLM service
docker compose restart llama
```

#### Issue: "AI Bridge connection errors"

```bash
# Check bridge logs
docker compose logs bridge

# Test bridge connectivity to services
docker compose exec bridge curl -s http://llama:8000/health
docker compose exec bridge curl -s http://host.docker.internal:26657/status

# Restart bridge
docker compose restart bridge
```

#### Issue: "Model download interrupted"

```bash
# Resume or retry download
cd models
rm -f mistral-7b-instruct.Q4_K_M.gguf  # Remove partial file
wget -c https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf
```

### Service Recovery

Complete restart procedure:

```bash
# Stop all Docker services
docker compose down

# Restart Cintara node (if needed)
cd ~/cintara-node/cintara-testnet-script
# Follow official restart procedure

# Start Docker services
cd /path/to/cintara-node-llm-bridge
docker compose up -d

# Verify all services
./scripts/test-llm-functionality.sh
```

---

## 🎉 Success Verification Checklist

Your Smart Cintara Node is fully operational when:

- [ ] Cintara node responds on port 26657
- [ ] Node is fully synced (catching_up: false)
- [ ] LLM server responds on port 8000
- [ ] AI Bridge responds on port 8080
- [ ] All automated tests pass
- [ ] AI can analyze node logs and provide diagnostics
- [ ] Transaction analysis works through AI Bridge
- [ ] Interactive AI chat responds with node insights

**Final verification command:**
```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Give me a complete health report of my Cintara node"}' | jq .
```

If this returns intelligent analysis of your node, congratulations! Your Smart Cintara Node with AI integration is fully operational.

---

## 📞 Support Resources

- **Cintara Documentation**: [Official Cintara Testnet Guide](https://github.com/Cintaraio/cintara-testnet-script)
- **Docker Documentation**: [Docker Compose Reference](https://docs.docker.com/compose/)
- **Troubleshooting**: Check logs with `docker compose logs -f`
- **Model Issues**: [Hugging Face Model Repository](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF)

Remember: This setup combines blockchain reliability with AI intelligence - the Cintara node runs natively for maximum stability while AI services run in containers for easy management.