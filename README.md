# 🚀 Cintara AI Bridge with Full Node

A fully containerized blockchain and AI solution that includes a complete Cintara blockchain node with AI-powered analysis capabilities. This setup runs a local Cintara testnet node alongside LLM integration for intelligent monitoring, diagnostics, and insights. Everything runs in Docker Compose for easy deployment and management.

## 📋 Prerequisites

**Environment Requirements:**
- **Any Linux/macOS/Windows system** with Docker support
- **Minimum 4 vCPU cores** and **8GB RAM** (16GB recommended for full node)
- **50GB+ storage** for blockchain data, Docker images, and AI model
- **Outbound internet access** for blockchain sync, Docker images, and AI model (~640MB)

**Software Dependencies:**
- **Docker Engine** (20.10.0 or later)
- **Docker Compose** (v2.0.0 or later)
- **Git** for repository cloning

**Network Requirements:**
- **Outbound internet access** for blockchain P2P networking and downloading models
- **Ports**: 26656 (P2P), 26657 (RPC), 1317 (API), 8000 (LLM), 8080 (AI Bridge)
- **Optional**: External access to these ports for remote monitoring

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# 2. Configure environment (optional - uses defaults)
cp .env.example .env
# Edit .env if you want to customize node name or other settings

# 3. Run Cintara node manually (recommended for permission stability)
sudo docker run -d --name cintara-blockchain-node --privileged --network host \
  -v /data:/data -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 -e MONIKER=ec2-cintara-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# 4. Start other services (LLM and AI Bridge)
docker compose up -d

# 5. Monitor startup progress (blockchain sync may take 30-60 minutes)
docker compose logs -f model-downloader  # Watch model download (2-3 minutes)
docker logs -f cintara-blockchain-node   # Watch blockchain sync progress

# 6. Verify everything works
  # Test Cintara node
  curl http://localhost:26657/status | jq .result.sync_info

  # Test LLM server
  curl http://localhost:8000/health

  # Test AI bridge
  curl http://localhost:8080/health

  # Test AI functionality
  curl -X POST http://localhost:8080/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"What is the status of my Cintara node?"}'

**🎯 Result**: Complete Cintara ecosystem running on:
- **Cintara Node**: `http://localhost:26657` (RPC) + `http://localhost:1317` (API)
- **LLM Server**: `http://localhost:8000` (TinyLlama 1.1B model)
- **AI Bridge**: `http://localhost:8080` (AI-powered node analysis)

**If all tests return OK responses, your full Cintara node with AI integration is operational.**

```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Cintara Node    │    │   LLM Server     │    │   AI Bridge     │
│ (Docker)        │◄───┤   (Docker)       │◄───┤   (Docker)      │
│ Port: 26657     │    │   Port: 8000     │    │   Port: 8080    │
│ Chain: cintara  │    │   TinyLlama 1B   │    │   FastAPI       │
│ _11001-1        │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                      ▲
        │                      │
        │           ┌──────────────────┐
        │           │ Model Download   │
        │           │ Service (Init)   │
        │           │ Alpine Container │
        │           └──────────────────┘
        │
        ▼
┌─────────────────┐
│ Blockchain P2P  │
│ Network         │
│ (Cintara        │
│ Testnet)        │
└─────────────────┘
```

## 🎯 What You Get

- **Full Cintara Node** - Complete blockchain node with P2P networking and consensus
- **AI/LLM Integration** - CPU-based TinyLlama 1.1B model for intelligent blockchain analysis
- **Smart Bridge API** - AI-powered local node monitoring and diagnostics
- **Fully Containerized** - Everything runs in Docker for easy deployment and scaling
- **Automatic Setup** - Blockchain initialization, model download, and sync handled automatically
- **Production Ready** - Optimized containers and persistent blockchain data

---

## 🧠 AI-Powered Features

### 1. Intelligent Node Diagnostics

Get AI-powered analysis of your local Cintara node:

```bash
curl -s -X POST http://localhost:8080/node/diagnose | jq .
```

**Example response:**
```json
{
  "diagnosis": {
    "health_score": "good",
    "issues": [],
    "recommendations": ["Monitor peer diversity"],
    "summary": "Node is healthy and fully synchronized"
  },
  "timestamp": "2024-09-04T14:30:00Z"
}
```

### 2. Smart Transaction Analysis

Analyze transactions with AI insights:

```bash
curl -s -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "hash": "0xabc123...",
      "amount": "1000",
      "from": "addr1...",
      "to": "addr2..."
    }
  }' | jq .
```

### 3. Interactive AI Chat

Ask the AI about your Cintara node:

```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the current status of my Cintara node?"}' | jq .
```

**Example questions:**
- "What is the current status of my Cintara node?"
- "Are there any sync issues I should be concerned about?"
- "How is my node performing?"
- "What recent blocks have been processed?"

### 4. Peer Connectivity Analysis

Analyze network connectivity with AI:

```bash
curl -s http://localhost:8080/node/peers | jq .
```

### 5. Block Transaction Analysis

Analyze transactions in specific blocks:

```bash
# Analyze latest block transactions
curl -s http://localhost:8080/node/transactions/12345 | jq .
```

---

## 🎛️ Available Services

| Service | Port | Description |
|---------|------|-------------|
| **Cintara Node RPC** | 26657 | Blockchain RPC API endpoint |
| **Cintara Node API** | 1317 | REST API endpoint |
| **Cintara P2P** | 26656 | Peer-to-peer networking |
| **AI Bridge** | 8080 | AI-enhanced node monitoring API |
| **LLM Server** | 8000 | Internal AI model server (TinyLlama 1.1B) |

---

## 🛠️ Management Commands

### View Logs
```bash
# All Docker services
docker compose logs -f

# Specific service
docker compose logs -f cintara-node
docker compose logs -f llama
docker compose logs -f bridge
docker compose logs -f model-downloader
```

### Restart Services
```bash
# Restart all services
docker compose restart

# Stop services
docker compose down

# Full restart
docker compose down && docker compose up -d
```

### Health Monitoring

**Quick health check:**
```bash
# Check all service status
docker compose ps

# Test connectivity
curl http://localhost:26657/status | jq .result.sync_info  # Cintara Node
curl http://localhost:8000/health  # LLM Server
curl http://localhost:8080/health  # AI Bridge
```

---

## 🔧 Configuration

### Environment Variables (.env file)

```bash
# Cintara Node Configuration
CHAIN_ID=cintara_11001-1
MONIKER=cintara-docker-node
CINTARA_NODE_URL=http://cintara-node:26657

# AI Model Configuration
MODEL_FILE=tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
CTX_SIZE=2048
LLM_THREADS=4

# Bridge Container Image
BRIDGE_IMAGE=cintaraio/cintara-ai-bridge:latest
```

### Customization Options

- **Node Customization**: Change `MONIKER` to set your node name, `CHAIN_ID` for different networks
- **Resource Optimization**: Adjust `LLM_THREADS` and `CTX_SIZE` based on your system
- **Model Selection**: Replace `MODEL_FILE` with any compatible GGUF model

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: "Model download failing"
```bash
# Check model downloader logs
docker compose logs model-downloader

# Manually download model
mkdir -p models
cd models
wget -O tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
```

#### Issue: "LLM server not starting"
```bash
# Check Docker logs
docker compose logs llama

# Common solutions:
# 1. Model file missing - wait for download to complete
# 2. Insufficient memory - check: free -h
# 3. Port conflict - check: sudo netstat -tlnp | grep :8000

# Restart LLM service
docker compose restart llama
```

#### Issue: "Cintara node not syncing"
```bash
# Check node status and sync progress
curl http://localhost:26657/status | jq .result.sync_info

# Check node logs for sync issues
docker compose logs cintara-node

# Restart node if stuck
docker compose restart cintara-node
```

#### Issue: "AI Bridge shows node: down"
```bash
# Check if local node is running
curl http://localhost:26657/status

# Check bridge logs
docker compose logs bridge

# Restart services if needed
docker compose restart bridge
```

### Complete Recovery

```bash
# Clean restart procedure
docker compose down
docker system prune -f
docker compose up -d
```

---

## 📁 Repository Structure

```
cintara-node-llm-bridge/         # https://github.com/Cintaraio/cintara-node-llm-bridge
├── README.md                    # This guide
├── docker-compose.yml           # All services configuration
├── .env.example                 # Environment variables template
├── cintara-node/                # Cintara blockchain node
│   ├── Dockerfile               # Node container configuration
│   └── init-node.sh             # Node initialization script
├── bridge/                      # AI Bridge source code
│   ├── app.py                   # Main AI bridge server
│   ├── Dockerfile               # Container configuration
│   └── requirements.txt         # Python dependencies
└── models/                      # AI model files directory (.gguf files)
```

---

## 🎯 Benefits of Containerized Approach

✅ **Complete Solution** - Full blockchain node with AI integration in containers
✅ **Local Node Control** - Your own Cintara testnet validator with full data
✅ **Easy Scaling** - Run multiple instances or on different environments
✅ **Automatic Setup** - Node initialization, sync, and AI model handled automatically
✅ **Cross-Platform** - Works on Linux, macOS, and Windows with Docker
✅ **Persistent Data** - Blockchain data preserved across container restarts
✅ **AI-Enhanced Analysis** - Intelligent insights from your local node data
✅ **Production Ready** - Optimized containers and resource management

---

## 🧪 Testing Your AI Bridge

### Basic Functionality Test
```bash
# Test all endpoints
curl http://localhost:26657/status | jq .result.sync_info  # Cintara Node
curl http://localhost:8000/health    # LLM Server
curl http://localhost:8080/health    # AI Bridge
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}' | jq .response
```

### Interactive Testing

Try these AI features once everything is running:

```bash
# Get comprehensive node analysis
curl -X POST http://localhost:8080/chat \
  -H 'Content-Type: application/json' \
  -d '{"message":"Give me a complete analysis of my Cintara node"}' | jq -r .response

# Analyze recent activity
curl -X POST http://localhost:8080/node/diagnose | jq .diagnosis

# Check peer connectivity
curl -s http://localhost:8080/node/peers | jq .peer_analysis
```

---

## 🎉 Success Verification

Your Cintara AI Bridge with Full Node is fully operational when:

- [ ] Cintara node responds on port 26657 and is syncing
- [ ] LLM server responds on port 8000
- [ ] AI Bridge responds on port 8080
- [ ] All services show healthy status
- [ ] AI can analyze local node data and provide insights
- [ ] Interactive AI chat responds with intelligent answers

**Final test:**
```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the status of my Cintara node?"}' | jq -r .response
```

If this returns intelligent analysis of your local node, congratulations! Your **Cintara AI Bridge with Full Node** is fully operational and participating in the Cintara network.

---

## 📞 Support & Resources

### Official Documentation
- **Cintara Network**: `cintara_11001-1` testnet blockchain
- **Local RPC**: `http://localhost:26657`
- **Local API**: `http://localhost:1317`
- **AI Model**: [TinyLlama 1.1B GGUF Model](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0)

### Diagnostic Tools
```bash
# Generate comprehensive diagnostic report
docker compose ps
docker compose logs --tail=50

# Check resource usage
docker stats

# Test AI integration health
curl -s http://localhost:8080/health | jq .
```

### Important Notes
- **Full Node**: Runs complete Cintara blockchain node with validator capabilities
- **Containerized**: All components run in Docker for easy deployment
- **AI Integration**: TinyLlama 1.1B model for intelligent blockchain analysis
- **Network**: Participates in Cintara testnet (`cintara_11001-1`)
- **Data Persistence**: Blockchain data persists across container restarts

**This setup provides AI-powered blockchain analysis with a complete local Cintara node.**