# 🔒 Cintara Node for SecretVM - Confidential Computing Deployment

**Complete Cintara ecosystem optimized for Secret Network's SecretVM platform**

## 📋 **What You Get**
- **Cintara blockchain node** (automatically configured)
- **LLM server** (TinyLlama in TEE)
- **AI bridge service** (confidential API)
- **TEE attestation support**
- **Reproducible builds**
- **Zero manual intervention**

## ⚠️ **Critical Requirements**

### **Hardware Compatibility**
- ❌ **NO Apple M1/M2 Mac support** - SecretVM requires x86 processors
- ✅ **Intel processors** with SGX 2.0+ or TDX 1.0+
- ✅ **AMD processors** with SEV 1.0+
- ✅ **Cloud instances** with TEE support (Azure DCv3, AWS Nitro Enclaves, etc.)

### **Platform Requirements**
- **Architecture**: linux/amd64 only
- **TEE Support**: Intel SGX, Intel TDX, or AMD SEV
- **RAM**: 6GB+ recommended for TEE environment
- **Storage**: 10GB+ for blockchain data and models

## 🚀 **SecretVM Deployment Options**

### **Option 1: SecretAI Developer Portal (Recommended)**

1. **Access Portal**
   ```bash
   # Visit SecretAI Developer Portal
   open https://secretai.scrtlabs.com/
   ```

2. **Create SecretVM**
   - Navigate to "SecretVMs" section
   - Click "Create New SecretVM"
   - Select VM type (recommended: medium or large)
   - Choose development environment

3. **Upload Configuration**
   - Upload `docker-compose.secretvm.yml`
   - Set environment variables (optional)
   - Configure secret environment variables via portal

4. **Launch**
   - Click "Launch your SecretVM"
   - Monitor provisioning status
   - Access via provided endpoints

### **Option 2: Pre-built Image Deployment**

```bash
# Use the pre-built SecretVM-compatible image
docker run -d --name cintara-secretvm \
  -p 26657:26657 -p 26656:26656 -p 1317:1317 -p 9090:9090 \
  -p 8000:8000 -p 8080:8080 -p 9999:9999 \
  -v cintara_secretvm_data:/data \
  -v cintara_secretvm_home:/home/cintara/data \
  -e MONIKER=my-secretvm-node \
  -e CHAIN_ID=cintara_11001-1 \
  public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified-secretvm:latest
```

### **Option 3: Local Build and Test**

```bash
# Clone and build locally (for development/testing)
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/unified-automated-setup

# Build SecretVM image
./scripts/build-secretvm.sh

# Test locally (non-TEE environment)
docker-compose -f docker-compose.secretvm.yml up -d
```

## 🔍 **Verification and Testing**

### **Service Health Checks**
```bash
# Wait 5-10 minutes after deployment, then test:

# Cintara blockchain node
curl http://localhost:26657/status

# LLM server
curl http://localhost:8000/health

# AI bridge
curl http://localhost:8080/health

# TEE attestation (SecretVM only)
curl http://localhost:9999/attestation
```

### **Expected Responses**
- **Cintara node**: JSON with blockchain status
- **LLM server**: Health check response
- **AI bridge**: Service status
- **Attestation**: TEE attestation report (SecretVM environment only)

## 🛡️ **Security and Attestation**

### **TEE Attestation**
The SecretVM deployment includes attestation support:

```bash
# Get attestation report
curl http://localhost:9999/attestation | jq .

# Expected attestation data:
{
  "timestamp": "2025-01-XX...",
  "image": "cintara-unified-secretvm",
  "git_commit": "abc123...",
  "moniker": "your-node-name",
  "chain_id": "cintara_11001-1",
  "tee_mode": true,
  "services": ["cintara-node", "llm-server", "ai-bridge"]
}
```

### **Reproducible Build Verification**
```bash
# Verify build integrity
docker inspect cintara-unified-secretvm:latest | jq '.[0].Config.Labels'

# Check build metadata
docker run --rm cintara-unified-secretvm:latest cat /attestation/build.log
```

## 📊 **Configuration Options**

### **Environment Variables**
```yaml
# Core node configuration
MONIKER: "your-secretvm-node"
CHAIN_ID: "cintara_11001-1"
LOG_LEVEL: "info"

# SecretVM-specific
SECRETVM_MODE: "true"
CONFIDENTIAL_COMPUTING: "enabled"
TEE_ATTESTATION: "enabled"

# Service URLs (usually keep defaults)
LLAMA_SERVER_URL: "http://localhost:8000"
CINTARA_NODE_URL: "http://localhost:26657"
```

### **Resource Allocation**
```yaml
# Recommended for SecretVM
deploy:
  resources:
    limits:
      cpus: '4.0'
      memory: 6G
    reservations:
      cpus: '2.0'
      memory: 4G
```

## 🔄 **Management Commands**

### **SecretVM Portal Management**
```bash
# Using SecretVM CLI (if available)
secretvm list
secretvm status <vm-id>
secretvm logs <vm-id>
secretvm stop <vm-id>
secretvm start <vm-id>
```

### **Docker Management**
```bash
# View logs
docker-compose -f docker-compose.secretvm.yml logs

# Restart services
docker-compose -f docker-compose.secretvm.yml restart

# Update and rebuild
git pull
docker-compose -f docker-compose.secretvm.yml build --no-cache
docker-compose -f docker-compose.secretvm.yml up -d
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **"TEE not supported" Error**
   ```bash
   # Check CPU capabilities
   grep -E "(sgx|sev|tdx)" /proc/cpuinfo

   # Solution: Use compatible hardware or cloud instance
   ```

2. **Attestation Endpoint Not Responding**
   ```bash
   # In non-TEE environments, this is expected
   # Attestation only works in actual SecretVM deployment
   ```

3. **Services Starting Slowly**
   ```bash
   # TEE environments may have longer startup times
   # Wait up to 10 minutes for full initialization
   ```

4. **Memory Issues**
   ```bash
   # Check available memory
   free -h

   # TEE environments may require more memory
   # Recommended: 6GB+ for optimal performance
   ```

### **Debug Commands**
```bash
# Check container status
docker ps -a

# View detailed logs
docker exec -it cintara-secretvm-unified bash
tail -f /var/log/supervisor/cintara-node.out.log

# Check attestation data
docker exec -it cintara-secretvm-unified cat /attestation/metadata.json
```

## 📈 **Performance Considerations**

### **TEE Overhead**
- **CPU**: ~10-20% overhead in TEE environment
- **Memory**: ~500MB additional for TEE runtime
- **Storage**: Encrypted storage may be slower
- **Network**: Minimal impact on network performance

### **Optimization Tips**
- Use SSD storage for better I/O performance
- Allocate sufficient RAM (6GB+ recommended)
- Monitor resource usage during sync
- Consider using faster instance types for initial sync

## 🔗 **Integration with Secret Network**

### **Connecting to Secret Network**
The deployed node can interact with Secret Network:

```bash
# Install secretcli (if not included)
# Configure connection to your deployed node
secretcli config node http://localhost:26657
secretcli config chain-id cintara_11001-1

# Test connection
secretcli status
```

### **Smart Contract Development**
Use the deployed environment for Secret Contract development:

```bash
# Deploy secret contracts to your node
secretcli tx compute store contract.wasm --from your-key --gas 2000000

# Query your contracts confidentially
secretcli query compute smart $CONTRACT_ADDRESS '{"get_config":{}}'
```

## 📚 **Additional Resources**

- **SecretVM Documentation**: https://docs.scrt.network/secret-network-documentation/secretvm-confidential-virtual-machines/
- **SecretAI Portal**: https://secretai.scrtlabs.com/
- **Secret Network Docs**: https://docs.scrt.network/
- **TEE Best Practices**: https://docs.scrt.network/secret-network-documentation/secretvm-confidential-virtual-machines/best-practices-for-developers

## 🆘 **Support**

- **GitHub Issues**: [Report SecretVM-specific issues](https://github.com/Cintaraio/cintara-node-llm-bridge/issues)
- **Secret Network Discord**: Join for SecretVM support
- **Documentation**: Check README files for detailed setup guides

---

**🔒 Your Cintara ecosystem is now running in a Trusted Execution Environment with verifiable attestation!**