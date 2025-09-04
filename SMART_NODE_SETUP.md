# 🚀 Smart Cintara Node Setup Guide

This guide will help you set up a **Smart Cintara Node** with integrated AI capabilities using Docker Compose.

## 🎯 What You'll Get

- **Cintara Blockchain Node** - Full testnet validator
- **AI/LLM Integration** - CPU-based Mistral 7B model  
- **Smart Bridge API** - AI-powered blockchain analysis
- **Automated Setup** - One-command deployment

## 📋 Prerequisites

- Ubuntu 22.04 (or EC2 with Ubuntu)
- Docker and Docker Compose installed
- 8GB+ RAM, 50GB+ storage
- Internet connection for model download

## 🚀 Quick Start

### Step 1: Download Model
```bash
# Create models directory and download AI model
mkdir -p models
cd models

# Download Mistral 7B model (~4GB) - this may take 5-10 minutes
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf

cd ..
```

### Step 2: Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit with your settings
nano .env
```

**Required settings in `.env`:**
```bash
PUBLIC_IP=your.ec2.public.ip
CHAIN_ID=cintara_11001-1
MONIKER=your-smart-node-name
MODEL_FILE=mistral-7b-instruct.Q4_K_M.gguf
LLM_THREADS=8
CTX_SIZE=2048
```

### Step 3: One-Command Setup
```bash
# Initialize and start everything
docker compose -f docker-compose-simple.yml up -d
```

This will:
1. 🔧 **Setup** the Cintara node automatically
2. 🧠 **Start** the AI/LLM server
3. 🌉 **Launch** the smart bridge API
4. 📊 **Monitor** all services

### Step 4: Verify Smart Node
```bash
# Check all services are running
docker compose -f docker-compose-simple.yml ps

# Test the AI-enhanced blockchain API
curl -s http://localhost:8080/health | jq .

# Get AI-powered node diagnostics
curl -s -X POST http://localhost:8080/node/diagnose | jq .

# Analyze transactions with AI
curl -s -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"transaction":{"hash":"0xabc","amount":"123","from":"addr1","to":"addr2"}}' | jq .
```

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

## 📱 API Examples

### Health Check
```bash
curl http://localhost:8080/health
```

### Smart Node Diagnostics  
```bash
curl -X POST http://localhost:8080/node/diagnose
```

### Transaction Analysis
```bash
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"transaction":{"hash":"tx123","amount":"1000","type":"transfer"}}'
```

### Log Analysis
```bash
curl http://localhost:8080/node/logs
```

## 🛠️ Management Commands

```bash
# View logs
docker compose -f docker-compose-simple.yml logs -f

# Restart services  
docker compose -f docker-compose-simple.yml restart

# Stop everything
docker compose -f docker-compose-simple.yml down

# Full reset (removes data)
docker compose -f docker-compose-simple.yml down -v
sudo rm -rf ./data
```

## 🔑 Important Notes

- **Save your mnemonic** - The setup will display your wallet mnemonic phrase
- **Backup data** - Your node data is stored in `./data/` directory  
- **Monitor resources** - The AI model uses significant CPU and RAM
- **Network sync** - Initial blockchain sync may take time

## 🆘 Troubleshooting

**Node won't start:**
```bash
# Check setup logs
docker compose -f docker-compose-simple.yml logs cintara-setup

# Restart setup
docker compose -f docker-compose-simple.yml restart node-setup
```

**AI not responding:**
```bash
# Check LLM server
docker compose -f docker-compose-simple.yml logs llama

# Test model directly
curl http://localhost:8000/health
```

**Need manual setup:**
```bash
# Access node container
docker compose -f docker-compose-simple.yml exec cintara-node bash

# Run manual setup
cd cintara-testnet-script
./cintara_ubuntu_node.sh
```

## 🎉 Success!

You now have a **Smart Cintara Node** with AI capabilities running! 

The node combines blockchain functionality with artificial intelligence to provide intelligent monitoring, analysis, and insights for your Cintara testnet participation.