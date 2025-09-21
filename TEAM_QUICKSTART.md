# 🚀 Team Quick Start - Cintara Node Setup

**For team members setting up Cintara node + LLM + AI agent**

## 📋 **What You Need**
- EC2 instance (t3.large or larger, 8GB+ RAM)
- AWS SSM access to the EC2
- 30 minutes setup time

## ⚡ **Quick Setup (4 Steps)**

### **Step 1: Get the Code**
```bash
# Connect to EC2 via SSM, then:
sudo su -
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/github-wf
```

### **Step 2: Install Docker**
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com | sh
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directories
mkdir -p /data /home/cintara/data
chmod 755 /data /home/cintara/data
```

### **Step 3: Setup Cintara Node (Interactive)**
```bash
# Pull and run Cintara node
docker pull public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

docker run -it \
  --name cintara-blockchain-node \
  -p 26657:26657 -p 26656:26656 -p 1317:1317 -p 9090:9090 \
  -v /data:/data -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 -e MONIKER=team-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# When prompted:
# 1. Node name: Press Enter
# 2. Overwrite config: Type 'y'
# 3. Wait for "started node", then Ctrl+C

# Restart in background
docker rm cintara-blockchain-node
docker run -d --name cintara-blockchain-node --restart unless-stopped \
  -p 26657:26657 -p 26656:26656 -p 1317:1317 -p 9090:9090 \
  -v /data:/data -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 -e MONIKER=team-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest
```

### **Step 4: Start LLM and AI Agent**
```bash
# Start remaining services
docker-compose up -d

# Wait 3-5 minutes for model download and startup
```

## ✅ **Verify Everything Works**
```bash
# Test all services (wait 5 minutes after step 4)
curl http://localhost:26657/status    # Cintara node
curl http://localhost:8000/health     # LLM server
curl http://localhost:8080/health     # AI agent

# All should return JSON responses
```

## 🔍 **Check Logs**
```bash
# If something doesn't work, check logs:
docker logs cintara-blockchain-node   # Cintara node
docker-compose logs llama             # LLM server
docker-compose logs bridge            # AI agent
```

## 🆘 **Get Help**
- **Detailed guide**: Read `EC2_COMPLETE_SETUP.md`
- **Issues**: Check `MANUAL_CINTARA_NODE.md`
- **Questions**: Ask the team lead

---
**🎉 That's it! Your Cintara ecosystem should be running.**