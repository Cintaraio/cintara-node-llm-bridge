# SecretVM Final Deployment Guide

## 🎯 **Recommended Deployment**

### **Option 1: Docker Run (Simplest)**
```bash
# Single command - no files needed
docker run -d --name cintara-secretvm-node \
  -p 26657:26657 -p 26656:26656 -p 8080:8080 \
  --restart unless-stopped \
  -v cintara_data:/data \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-secretvm-ready:latest

# Monitor startup
docker logs cintara-secretvm-node -f
```

### **Option 2: Docker Compose (Professional)**
```bash
# 1. Get the compose file
wget https://raw.githubusercontent.com/Cintaraio/cintara-node-llm-bridge/feat/unified-automated-setup/docker-compose.secretvm-final.yml

# 2. Deploy
docker-compose -f docker-compose.secretvm-final.yml up -d

# 3. Monitor
docker-compose -f docker-compose.secretvm-final.yml logs -f
```

## ✅ **Verification Steps**

After deployment (wait ~2 minutes):

```bash
# 1. Check container status
docker ps | grep cintara

# 2. Test node API
curl -s http://localhost:26657/status | jq '.result.node_info.moniker'
# Should return: "cintara-preconfigured-node"

# 3. Check network connection
curl -s http://localhost:26657/net_info | jq '.result.n_peers'
# Should show: number > 0 (connected to peers)

# 4. Check if node appears in testnet
curl -s https://testnet.cintara.io/nodes | jq
```

## 🌟 **Key Features**

- ✅ **Zero configuration** - everything pre-configured
- ✅ **No interaction needed** - starts automatically
- ✅ **Includes validator** - should appear in testnet.cintara.io/nodes
- ✅ **Multi-service** - blockchain + AI bridge + LLM server
- ✅ **Auto-restart** - resilient to crashes
- ✅ **Persistent data** - survives container restarts

## 🛠️ **Management Commands**

```bash
# View logs
docker logs cintara-secretvm-node

# Restart node
docker restart cintara-secretvm-node

# Stop node
docker stop cintara-secretvm-node

# Remove node (data persists in volume)
docker rm cintara-secretvm-node

# Complete cleanup (removes data!)
docker rm -f cintara-secretvm-node
docker volume rm cintara_data
```

## 🔧 **Troubleshooting**

If node doesn't appear in testnet.cintara.io/nodes:

1. **Check sync status**: `curl http://localhost:26657/status | jq '.result.sync_info.catching_up'`
2. **Check peer connections**: `curl http://localhost:26657/net_info | jq '.result.n_peers'`
3. **Wait for sync**: Node needs to sync before appearing in network list

## 📊 **Success Indicators**

- Container status: `Up` and healthy
- Node moniker: `cintara-preconfigured-node`
- Chain ID: `cintara_11001-1`
- Peers: `> 0`
- API responding: HTTP 200 on port 26657
- **Appears in**: https://testnet.cintara.io/nodes

## 🎯 **This Should Work!**

The pre-configured image includes everything needed:
- ✅ Working genesis.json with validator
- ✅ Proper validator state files
- ✅ Pre-built cintarad binary
- ✅ No setup or interaction required

Perfect for SecretNetwork deployment! 🚀