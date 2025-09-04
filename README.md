# 🚀 Smart Cintara Node with AI Integration

A hybrid setup that combines a Cintara blockchain node with AI-powered analysis capabilities using LLM integration.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cintara Node  │    │   LLM Server     │    │   AI Bridge     │
│   (Manual)      │◄───┤   (Docker)       │◄───┤   (Docker)      │
│   Port: 26657   │    │   Port: 8000     │    │   Port: 8080    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🎯 What You'll Get

- **Cintara Blockchain Node** - Native testnet validator for maximum reliability
- **AI/LLM Integration** - CPU-based Mistral 7B model for intelligent analysis
- **Smart Bridge API** - AI-powered blockchain monitoring and diagnostics
- **Hybrid Architecture** - Best of both manual setup and containerization

## 📋 Prerequisites

- **Ubuntu 22.04** (EC2 instance recommended)
- **Docker and Docker Compose** installed
- **8GB+ RAM, 50GB+ storage**
- **Internet connection** for model download

---

## 🚀 Quick Start

### Step 1: Setup Cintara Node (Manual)

```bash
# Run automated setup script
./scripts/setup-cintara-node.sh
```

**Follow the prompts:**
- Enter your node name (e.g., "my-smart-node")
- Set a secure keyring password (8+ characters)
- **Save the mnemonic phrase securely!**

### Step 2: Configure Environment

```bash
# Copy and edit environment file
cp .env.example .env
nano .env
```

**Required settings in `.env`:**
```bash
# Model configuration
MODEL_FILE=mistral-7b-instruct.Q4_K_M.gguf
LLM_THREADS=8
CTX_SIZE=2048

# Security: Generate a secure keyring password
KEYRING_PASSWORD=your-secure-password-here
```

**🔐 Generate a secure password:**
```bash
./scripts/generate-secure-password.sh
```

### Step 3: Download AI Model

```bash
mkdir -p models
cd models

# Download Mistral 7B model (~4GB) - this may take 5-10 minutes
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf

cd ..
```

### Step 4: Start Smart Node System

```bash
# Use unified startup script (recommended)
./scripts/start-smart-node.sh

# Or start manually
docker compose up -d
```

---

## ✅ Verification & Testing

### Health Checks
```bash
# Test all components
curl http://localhost:26657/status     # Cintara node
curl http://localhost:8000/health      # LLM server  
curl http://localhost:8080/health      # AI bridge
```

### AI Features
```bash
# Get AI-powered node diagnostics
curl -X POST http://localhost:8080/node/diagnose | jq .

# Analyze transactions with AI
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"transaction":{"hash":"0xabc","amount":"123","from":"addr1","to":"addr2"}}' | jq .

# Get intelligent log analysis
curl http://localhost:8080/node/logs | jq .
```

---

## 🎛️ Available Services

| Service | Port | Description |
|---------|------|-------------|
| **Cintara Node** | 26657 | Blockchain RPC API |
| **P2P Network** | 26656 | Blockchain peer connections |
| **Smart Bridge** | 8080 | AI-enhanced blockchain API |
| **LLM Server** | 8000 | Internal AI model server |

## 🧠 Smart Features

The AI integration provides:

- **🔍 Node Diagnostics** - AI analyzes node health and performance
- **📊 Transaction Analysis** - Smart risk assessment and insights
- **📝 Log Analysis** - AI-powered error detection and recommendations
- **⚡ Real-time Monitoring** - Intelligent blockchain monitoring

---

## 🛠️ Management

### View Logs
```bash
# All Docker services
docker compose logs -f

# Specific service
docker compose logs -f llama
docker compose logs -f bridge
```

### Restart Services
```bash
# Restart Docker services only (keeps Cintara node running)
docker compose restart

# Stop Docker services
docker compose down
```

### Cintara Node Management
```bash
# Check if running
ps aux | grep cintarad

# Restart if needed (adjust path as needed)
cd ~/cintara-node/cintara-testnet-script
# Follow the original script's restart instructions
```

---

## 🔧 Troubleshooting

### Cintara Node Issues
```bash
# Check if node is responding
curl -s http://localhost:26657/status

# If not responding, check if process is running
ps aux | grep cintarad

# Check node logs (location varies based on setup)
journalctl -u cintarad -f  # if running as service
```

### LLM Server Issues
```bash
# Check Docker logs
docker compose logs llama

# Restart LLM only  
docker compose restart llama

# Check if model file exists
ls -la models/
```

### Bridge Connection Issues
```bash
# Test bridge connectivity to both services
docker compose exec bridge curl -s http://llama:8000/health
docker compose exec bridge curl -s http://host.docker.internal:26657/status

# Restart bridge
docker compose restart bridge
```

### Common Issues
**"Model file not found"**
- Ensure model file name in `.env` matches actual file in `models/` directory

**"Cintara node not responding"**
- Verify node is running: `ps aux | grep cintarad`
- Check node status: `curl http://localhost:26657/status`

**"Bridge can't connect to node"**
- Ensure Cintara node is running on port 26657
- Check firewall/network settings

---

## 📁 Repository Structure

```
cintara-node-llm-bridge/
├── README.md                 # This file
├── docker-compose.yml        # LLM + Bridge services
├── .env.example             # Environment template
├── bridge/                  # AI Bridge FastAPI application
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── scripts/                 # Management scripts
│   ├── setup-cintara-node.sh    # Manual node setup
│   ├── start-smart-node.sh      # Unified startup
│   └── generate-secure-password.sh
├── models/                  # LLM model files (.gguf)
└── data/                   # (Created at runtime for any data)
```

## 🎯 Benefits of Hybrid Approach

✅ **Reliable Cintara Node** - Uses official script, guaranteed compatibility  
✅ **Simplified Docker** - Only AI components, easier to debug  
✅ **Better Performance** - Node runs natively on host system  
✅ **Easy Updates** - Update blockchain and AI components independently  
✅ **Clear Separation** - Blockchain vs AI concerns properly separated  
✅ **Production Ready** - Manual node setup for mission-critical blockchain operations

---

## 🎉 Success!

You now have a **Smart Cintara Node** that combines:
- Native Cintara blockchain validation
- AI-powered analysis and monitoring  
- RESTful API for intelligent blockchain insights

The hybrid architecture provides the reliability of manual blockchain setup with the convenience of containerized AI services.

**🔗 Important URLs:**
- **Cintara Node RPC**: http://localhost:26657
- **LLM Server**: http://localhost:8000  
- **AI Bridge API**: http://localhost:8080

For support and updates, refer to the official [Cintara documentation](https://github.com/Cintaraio/cintara-testnet-script).