# 🚀 Manual Cintara Node Setup

This guide shows how to run the Cintara blockchain node manually with full sudo privileges, bypassing Docker Compose permission issues.

## 📋 **Prerequisites**

```bash
# Ensure you're running as root
sudo su -

# Create required directories
mkdir -p /data
mkdir -p /home/cintara/data
chmod 777 /data
chmod 777 /home/cintara/data
```

## 🐳 **Method 1: Run with Full Privileges (Recommended)**

```bash
# Pull the latest Cintara node image
docker pull public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# Run with full privileges and host networking
docker run -d \
  --name cintara-blockchain-node \
  --restart unless-stopped \
  --privileged \
  --user 0:0 \
  --network host \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=ec2-cintara-node \
  -e KEYRING_BACKEND=test \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# Monitor logs
docker logs -f cintara-blockchain-node
```

## 🔧 **Method 2: Interactive Setup (For Troubleshooting)**

```bash
# Run interactively to debug setup issues
docker run -it --rm \
  --privileged \
  --user 0:0 \
  --network host \
  -v /data:/data \
  -v /home/cintara/data:/home/cintara/data \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=ec2-cintara-node \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest bash

# Inside the container, run setup manually:
cd /home/cintara/cintara-testnet-script
./cintara_ubuntu_node.sh

# After setup, start the node:
cintarad start --home /home/cintara/data/.tmp-cintarad \
  --rpc.laddr tcp://0.0.0.0:26657 \
  --grpc.address 0.0.0.0:9090 \
  --api.address tcp://0.0.0.0:1317 \
  --api.enable true
```

## 🌐 **Method 3: Host Network Mode (Maximum Compatibility)**

```bash
# Run with host networking to avoid port mapping issues
docker run -d \
  --name cintara-blockchain-node \
  --restart unless-stopped \
  --privileged \
  --network host \
  -v /data:/data:rw \
  -v /home/cintara/data:/home/cintara/data:rw \
  -e CHAIN_ID=cintara_11001-1 \
  -e MONIKER=ec2-cintara-node \
  -e KEYRING_BACKEND=test \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-node:latest

# Check if ports are accessible
curl http://localhost:26657/status
curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info
```

## 📊 **Verify Node is Running**

```bash
# Check container status
docker ps | grep cintara

# Check logs
docker logs cintara-blockchain-node

# Test RPC endpoint
curl -s http://localhost:26657/status | jq .result.sync_info

# Test API endpoint
curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info | jq .default_node_info

# Check if node is syncing
curl -s http://localhost:26657/status | jq .result.sync_info.catching_up
```

## 🔄 **Managing the Node**

```bash
# Stop the node
docker stop cintara-blockchain-node

# Start the node
docker start cintara-blockchain-node

# Restart the node
docker restart cintara-blockchain-node

# Remove the node (careful - this deletes the container)
docker rm -f cintara-blockchain-node

# View real-time logs
docker logs -f cintara-blockchain-node

# Execute commands inside running container
docker exec -it cintara-blockchain-node bash
```

## 🐛 **Troubleshooting**

### **Permission Denied Errors**
```bash
# Ensure directories have correct permissions
sudo chmod -R 777 /data
sudo chmod -R 777 /home/cintara/data

# Run container with even more privileges
docker run --privileged --cap-add=ALL --security-opt apparmor=unconfined ...
```

### **Port Already in Use**
```bash
# Check what's using the ports
sudo netstat -tulpn | grep :26657
sudo netstat -tulpn | grep :1317

# Kill existing processes if needed
sudo pkill -f cintarad
```

### **Node Won't Sync**
```bash
# Check node status
docker exec cintara-blockchain-node cintarad status

# Reset node data (careful - this deletes blockchain data)
docker stop cintara-blockchain-node
sudo rm -rf /home/cintara/data/.tmp-cintarad
docker start cintara-blockchain-node
```

## 🎯 **Integration with Other Services**

After the Cintara node is running manually, start the other services:

```bash
# Start LLM and AI Bridge services
cd /root/cintara-node-llm-bridge
docker-compose up -d

# The bridge will connect to the manually run node via host.docker.internal:26657
```

## ✅ **Success Indicators**

You know the node is working when:
- ✅ `curl http://localhost:26657/status` returns JSON
- ✅ `docker logs cintara-blockchain-node` shows "started node"
- ✅ Sync info shows the node is catching up: `"catching_up": true`
- ✅ Block height is increasing over time

## 🔗 **Endpoints**

Once running, these endpoints will be available:
- **RPC**: http://localhost:26657
- **API**: http://localhost:1317
- **gRPC**: localhost:9090
- **P2P**: localhost:26656 (for other nodes to connect)

---

This manual approach gives you full control over the Cintara node and bypasses all Docker Compose permission issues!