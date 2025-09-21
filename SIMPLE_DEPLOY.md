# 🚀 Cintara Node - Simple Deployment

## 🔐 **Admin Setup (Run Once - Requires sudo)**

```bash
# Create required directories with proper permissions
sudo mkdir -p /data /home/cintara/data
sudo chmod 755 /data /home/cintara/data

# Add current user to docker group (optional - to run without sudo)
sudo usermod -aG docker $USER
# After this command, logout and login again
```

## 🐳 **User Steps (No sudo required after admin setup)**

### **Step 1: Pull the Image**
```bash
docker pull public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest
```

### **Step 2: First-Time Interactive Setup**
```bash
# Run interactively for initial setup
docker run -it \
  --name cintara-node \
  -p 26657:26657 \
  -p 26656:26656 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=my-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# When prompted:
# 1. "Enter the Name for the node:" → Press Enter (uses MONIKER)
# 2. "Overwrite existing configuration? [y/n]" → Type: y

# Wait for setup to complete (shows "started node")
# Then press Ctrl+C to stop the interactive session
```

### **Step 3: Run in Background**
```bash
# After initial setup, run in detached mode
docker start cintara-node

# Or remove and run detached
docker rm cintara-node
docker run -d \
  --name cintara-node \
  --restart unless-stopped \
  -p 26657:26657 \
  -p 26656:26656 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=my-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest
```

### **Step 4: Verify Node is Running**
```bash
# Check container status
docker ps | grep cintara-node

# Watch logs (exit with Ctrl+C)
docker logs -f cintara-node

# Test node (wait 2-3 minutes after startup)
curl http://localhost:26657/status
```

## 🎯 **Available Services**

Your node provides these endpoints:
- **RPC**: http://localhost:26657
- **API**: http://localhost:1317
- **gRPC**: localhost:9090
- **P2P**: localhost:26656

## 🔧 **Node Management**

```bash
# Stop node
docker stop cintara-node

# Start node
docker start cintara-node

# Remove node (careful - deletes container)
docker rm -f cintara-node

# Run cintarad commands
docker exec cintara-node cintarad status
docker exec cintara-node cintarad query bank balances [address]

# Get shell access
docker exec -it cintara-node bash
```

## 📊 **Check Node Status**

```bash
# Sync progress
curl -s http://localhost:26657/status | jq .result.sync_info.catching_up

# Current height
curl -s http://localhost:26657/status | jq .result.sync_info.latest_block_height

# Node info
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info
```

---

**🎉 Your Cintara node is now running! The node will automatically sync with the network.**