# 🧪 Testing Guide - Cintara SecretVM Setup

**How to test Cintara SecretVM setup before sharing with Secret Network team**

## 🚨 **Important Platform Limitations**

### **❌ Cannot Test On:**
- **Apple M1/M2 Macs** - No SGX/TDX/SEV support
- **Most consumer Intel Macs** - SGX typically disabled
- **ARM-based systems** - SecretVM requires x86_64

### **✅ Can Test On:**
- **AWS EC2** (recommended): C5, M5, R5 instances
- **Azure VMs**: DCv3 series (with Intel SGX)
- **Google Cloud**: N2 instances
- **Intel PCs** with SGX enabled (rare in consumer hardware)

---

## 🔧 **Option 1: AWS EC2 Testing (Recommended)**

### **Step 1: Launch EC2 Instance**
```bash
# Recommended instance types for testing:
# - t3.large (2 vCPU, 8 GB RAM) - minimum
# - m5.xlarge (4 vCPU, 16 GB RAM) - recommended
# - c5.xlarge (4 vCPU, 8 GB RAM) - balanced

# Use Amazon Linux 2 AMI
# Security group: Allow ports 22, 26656, 26657, 1317, 8000, 8080, 9090, 9999
```

### **Step 2: Connect and Setup**
```bash
# SSH to your instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Run the automated setup script
curl -sSL https://raw.githubusercontent.com/Cintaraio/cintara-node-llm-bridge/feat/unified-automated-setup/scripts/setup-ec2-testing.sh | sudo bash
```

### **Step 3: Test the Setup**
```bash
# After setup completes, test as ec2-user
sudo su - ec2-user
cd /home/ec2-user/cintara-test/cintara-node-llm-bridge

# Start the services
docker-compose -f docker-compose.secretvm.yml up -d

# Wait 5-10 minutes, then test
curl http://localhost:26657/status    # Cintara node
curl http://localhost:8000/health     # LLM server
curl http://localhost:8080/health     # AI bridge
curl http://localhost:9999/attestation # Attestation (may not work in standard EC2)
```

### **Step 4: Monitor Services**
```bash
# Check service status
docker-compose -f docker-compose.secretvm.yml ps

# View logs
docker-compose -f docker-compose.secretvm.yml logs -f

# Check individual service logs
docker exec cintara-secretvm-unified supervisorctl status
docker exec cintara-secretvm-unified tail -f /var/log/supervisor/cintara-node.out.log
```

---

## 🖥️ **Option 2: Mac Local Testing (Limited)**

### **What You CAN Test on Mac:**
- ✅ **Docker build process**
- ✅ **Container startup**
- ✅ **Service health checks**
- ✅ **Basic functionality**

### **What You CANNOT Test on Mac:**
- ❌ **TEE attestation**
- ❌ **SecretVM-specific features**
- ❌ **Hardware security features**

### **Mac Testing Steps:**
```bash
# In your existing repository
cd /Users/ram/Documents/claude-code/cintarav2/cintara-node-llm-bridge

# Start Docker Desktop if not running
open -a Docker

# Wait for Docker to start, then build and test
docker-compose -f docker-compose.secretvm.yml up -d

# Test basic functionality (some features won't work)
curl http://localhost:26657/status    # Should work
curl http://localhost:8000/health     # Should work
curl http://localhost:8080/health     # Should work
curl http://localhost:9999/attestation # Will fail (expected on Mac)
```

---

## 📋 **Testing Checklist Before Sharing**

### **Functional Tests:**
- [ ] All containers start successfully
- [ ] Cintara node syncs blockchain data
- [ ] LLM server responds to health checks
- [ ] AI bridge API is accessible
- [ ] No critical errors in logs

### **Performance Tests:**
- [ ] Resource usage within expected limits
- [ ] Reasonable startup time (5-10 minutes)
- [ ] Stable operation for 1+ hours
- [ ] Memory usage doesn't grow indefinitely

### **Security Tests:**
- [ ] Containers run with non-root users
- [ ] No sensitive data in logs
- [ ] Proper network isolation
- [ ] Health checks respond correctly

### **Documentation Tests:**
- [ ] README instructions work
- [ ] All endpoints documented correctly
- [ ] Environment variables properly explained
- [ ] Troubleshooting guide is accurate

---

## 🚀 **Quick EC2 Setup Script**

Create this script to automate EC2 testing: