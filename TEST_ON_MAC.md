# 🖥️ Testing Cintara SecretVM Setup on Mac

**Limited testing capabilities on Mac due to hardware constraints**

## ⚠️ **Important Limitations**

### **What WILL Work on Mac:**
- ✅ Docker container builds
- ✅ Basic service startup
- ✅ Health check endpoints
- ✅ LLM server functionality
- ✅ AI bridge API
- ✅ Container orchestration

### **What WON'T Work on Mac:**
- ❌ TEE attestation (requires Intel SGX/TDX/AMD SEV)
- ❌ SecretVM-specific security features
- ❌ Hardware-based confidential computing
- ❌ True SecretVM environment simulation

---

## 🚀 **Mac Testing Steps**

### **Step 1: Prepare Environment**
```bash
# Ensure Docker Desktop is running
open -a Docker

# Navigate to your repository
cd /Users/ram/Documents/claude-code/cintarav2/cintara-node-llm-bridge

# Check if you're on the right branch
git branch --show-current  # Should show: feat/unified-automated-setup
```

### **Step 2: Start Services**
```bash
# Build and start all services
docker-compose -f docker-compose.secretvm.yml up -d

# Check container status
docker-compose -f docker-compose.secretvm.yml ps
```

### **Step 3: Wait for Initialization**
```bash
# Services need time to start (especially first run)
echo "⏳ Waiting for services to initialize..."
sleep 300  # Wait 5 minutes

# Monitor logs during startup
docker-compose -f docker-compose.secretvm.yml logs -f
```

### **Step 4: Test Service Endpoints**
```bash
# Test Cintara blockchain node
echo "Testing Cintara node..."
curl -s http://localhost:26657/status | jq .

# Test LLM server
echo "Testing LLM server..."
curl -s http://localhost:8000/health

# Test AI bridge
echo "Testing AI bridge..."
curl -s http://localhost:8080/health

# Test attestation endpoint (will fail on Mac - expected)
echo "Testing attestation endpoint (expected to fail on Mac)..."
curl -s http://localhost:9999/attestation || echo "❌ Failed (expected on Mac)"
```

### **Step 5: Functional Testing**
```bash
# Check supervisor status
docker exec cintara-secretvm-unified supervisorctl status

# View individual service logs
docker exec cintara-secretvm-unified tail -20 /var/log/supervisor/cintara-node.out.log
docker exec cintara-secretvm-unified tail -20 /var/log/supervisor/llama-server.out.log
docker exec cintara-secretvm-unified tail -20 /var/log/supervisor/ai-bridge.out.log

# Check resource usage
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

---

## 🧪 **Automated Mac Testing Script**

Create and run this script for automated testing:

```bash
# Create testing script
cat > test-mac-setup.sh << 'EOF'
#!/bin/bash

echo "🖥️ Testing Cintara SecretVM Setup on Mac"
echo "========================================"

# Start services
echo "🚀 Starting services..."
docker-compose -f docker-compose.secretvm.yml up -d

# Wait for initialization
echo "⏳ Waiting 5 minutes for services to initialize..."
sleep 300

# Test endpoints
echo "🔍 Testing service endpoints..."

tests_passed=0
total_tests=0

# Test Cintara node
echo -n "Cintara node (26657): "
((total_tests++))
if curl -sf http://localhost:26657/status >/dev/null 2>&1; then
    echo "✅ OK"
    ((tests_passed++))
else
    echo "❌ Failed"
fi

# Test LLM server
echo -n "LLM server (8000): "
((total_tests++))
if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ OK"
    ((tests_passed++))
else
    echo "❌ Failed"
fi

# Test AI bridge
echo -n "AI bridge (8080): "
((total_tests++))
if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ OK"
    ((tests_passed++))
else
    echo "❌ Failed"
fi

# Test attestation (expected to fail)
echo -n "Attestation (9999): "
if curl -sf http://localhost:9999/attestation >/dev/null 2>&1; then
    echo "⚠️  Unexpected success (should fail on Mac)"
else
    echo "❌ Failed (expected on Mac)"
fi

echo ""
echo "📊 Test Results: $tests_passed/$total_tests tests passed"

if [ $tests_passed -eq $total_tests ]; then
    echo "✅ All core services are working!"
else
    echo "⚠️  Some services failed - check logs for details"
fi

echo ""
echo "📋 Container Status:"
docker-compose -f docker-compose.secretvm.yml ps

echo ""
echo "💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "🔧 To debug issues:"
echo "  View logs: docker-compose -f docker-compose.secretvm.yml logs"
echo "  Check supervisor: docker exec cintara-secretvm-unified supervisorctl status"
echo "  Stop services: docker-compose -f docker-compose.secretvm.yml down"
EOF

chmod +x test-mac-setup.sh

# Run the test
./test-mac-setup.sh
```

---

## 🔍 **Troubleshooting on Mac**

### **Common Issues:**

1. **Docker Out of Memory**
   ```bash
   # Increase Docker Desktop memory allocation
   # Docker Desktop > Settings > Resources > Memory
   # Recommended: 6GB+ for this setup
   ```

2. **Services Starting Slowly**
   ```bash
   # Mac may be slower than Linux - wait longer
   # Check if containers are actually starting:
   docker-compose -f docker-compose.secretvm.yml logs -f
   ```

3. **Port Conflicts**
   ```bash
   # Check if ports are already in use
   lsof -i :26657
   lsof -i :8000
   lsof -i :8080

   # Stop conflicting services or change ports in docker-compose
   ```

4. **Build Failures**
   ```bash
   # Clean Docker cache and rebuild
   docker system prune -f
   docker-compose -f docker-compose.secretvm.yml build --no-cache
   ```

### **Mac-Specific Limitations:**

- **No TEE Support**: Mac cannot simulate TEE environment
- **Performance**: Mac virtualization adds overhead
- **Architecture**: Running x86_64 containers on ARM (if M1/M2 Mac)

---

## ✅ **What This Mac Testing Validates**

### **✅ Confirmed Working:**
- Docker container orchestration
- Service startup and health checks
- Basic blockchain node functionality
- LLM server operation
- AI bridge API responses
- Container networking
- Resource allocation

### **⚠️ Cannot Validate on Mac:**
- TEE attestation functionality
- SecretVM security features
- Hardware-specific optimizations
- Production-like performance

---

## 📋 **Pre-EC2 Testing Checklist**

Use this checklist before moving to EC2:

- [ ] All containers start without errors
- [ ] Health check endpoints respond
- [ ] No critical errors in supervisor logs
- [ ] Resource usage is reasonable
- [ ] Containers can communicate with each other
- [ ] Docker-compose configuration is valid
- [ ] Build process completes successfully

Once these pass on Mac, proceed to EC2 testing for full validation.

---

## 🚀 **Next Steps After Mac Testing**

1. **If Mac tests pass**: Proceed with EC2 testing
2. **If Mac tests fail**: Debug and fix issues locally first
3. **After EC2 validation**: Ready to share with Secret Network team

Remember: Mac testing is preliminary validation only. Full SecretVM compatibility requires testing in a TEE-enabled environment.