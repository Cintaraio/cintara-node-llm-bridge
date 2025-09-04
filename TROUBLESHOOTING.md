# 🔧 Smart Cintara Node Troubleshooting Guide

This guide helps diagnose and resolve common issues with your Smart Cintara Node + LLM integration.

## 🚨 Quick Diagnostic Commands

Run these commands first to identify the problem area:

```bash
# Quick health check of all services
./scripts/verify-smart-node.sh

# Check Docker services status
docker compose ps

# Check Cintara node status  
curl -s http://localhost:26657/status | jq .sync_info

# View recent logs
docker compose logs --tail=50
```

---

## 📋 Common Issues by Category

### 🔴 Cintara Node Issues

#### Issue: "Cintara node not responding on port 26657"

**Symptoms:**
```
❌ FAIL: Cintara Node RPC Endpoint
curl: (7) Failed to connect to localhost port 26657: Connection refused
```

**Diagnosis:**
```bash
# Check if cintarad process is running
ps aux | grep cintarad

# Check if port is open
sudo netstat -tlnp | grep :26657
```

**Solutions:**

1. **Node not started:**
   ```bash
   cd ~/cintara-node/cintara-testnet-script
   ./cintara_ubuntu_node.sh  # Re-run setup if needed
   # Or manually start:
   cintarad start --home ~/.tmp-cintarad
   ```

2. **Node crashed/stopped:**
   ```bash
   # Check system logs
   journalctl -u cintarad -n 100
   
   # If running as systemd service, restart:
   sudo systemctl restart cintarad
   ```

3. **Wrong RPC address:**
   ```bash
   # Check node configuration
   cat ~/.tmp-cintarad/config/config.toml | grep laddr
   # Should show: laddr = "tcp://127.0.0.1:26657"
   ```

#### Issue: "Node is syncing but taking too long"

**Symptoms:**
```json
{"catching_up": true, "latest_block_height": "1234"}
```

**Solutions:**
```bash
# Check sync progress
watch -n 10 'curl -s http://localhost:26657/status | jq .sync_info'

# Check peer connectivity
curl -s http://localhost:26657/net_info | jq .result.n_peers

# If low peer count, try restarting node
```

---

### 🔴 Docker & LLM Issues

#### Issue: "Docker services not starting"

**Symptoms:**
```
❌ FAIL: Docker Services Running
State: restarting, exited, unhealthy
```

**Diagnosis:**
```bash
# Check specific service status
docker compose ps
docker compose logs llama
docker compose logs bridge
```

**Solutions:**

1. **Model file missing:**
   ```bash
   # Check model file exists
   ls -la models/
   # Should show: mistral-7b-instruct.Q4_K_M.gguf
   
   # If missing, re-download:
   cd models
   wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf
   ```

2. **Environment file issues:**
   ```bash
   # Check .env file exists and has correct settings
   cat .env
   # Should contain: MODEL_FILE=mistral-7b-instruct.Q4_K_M.gguf
   
   # If missing:
   cp .env.example .env
   nano .env  # Edit the file
   ```

3. **Memory insufficient:**
   ```bash
   # Check available memory (need 8GB+)
   free -h
   
   # If low memory, stop other services or reduce LLM threads:
   echo "LLM_THREADS=4" >> .env
   docker compose restart llama
   ```

4. **Port conflicts:**
   ```bash
   # Check if ports are already in use
   sudo netstat -tlnp | grep -E ":(8000|8080)"
   
   # Kill conflicting processes if found
   sudo kill -9 <PID>
   ```

#### Issue: "LLM Server fails to load model"

**Symptoms:**
```
llama-1  | ERROR: Model file not found
llama-1  | FATAL: Failed to load model
```

**Solutions:**
```bash
# 1. Verify model file path and permissions
ls -la models/mistral-7b-instruct.Q4_K_M.gguf
# Should show file size ~4GB

# 2. Check .env configuration matches file name
grep MODEL_FILE .env

# 3. Restart with verbose logging
docker compose restart llama
docker compose logs -f llama

# 4. If file corrupted, re-download:
cd models
rm mistral-7b-instruct.Q4_K_M.gguf
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf
```

---

### 🔴 AI Bridge Issues

#### Issue: "AI Bridge cannot connect to services"

**Symptoms:**
```
❌ FAIL: AI Bridge Health
bridge-1  | ERROR: Could not connect to Cintara node
bridge-1  | ERROR: Could not connect to LLM server
```

**Diagnosis:**
```bash
# Test bridge connectivity to both services
docker compose exec bridge curl -s http://llama:8000/health
docker compose exec bridge curl -s http://host.docker.internal:26657/status
```

**Solutions:**

1. **LLM connection issues:**
   ```bash
   # Verify LLM server is responsive
   curl -s http://localhost:8000/health
   
   # If not, restart LLM:
   docker compose restart llama
   ```

2. **Cintara node connection issues:**
   ```bash
   # Test node from host
   curl -s http://localhost:26657/status
   
   # Check bridge environment
   docker compose exec bridge env | grep CINTARA_NODE_URL
   # Should show: CINTARA_NODE_URL=http://host.docker.internal:26657
   ```

3. **Network connectivity:**
   ```bash
   # Restart all services with fresh network
   docker compose down
   docker compose up -d
   ```

#### Issue: "AI responses are slow or timeout"

**Symptoms:**
```
❌ FAIL: AI Node Diagnostics  
HTTP 504 Gateway Timeout
```

**Solutions:**
```bash
# 1. Increase LLM threads (if you have more CPU cores)
echo "LLM_THREADS=8" >> .env
docker compose restart llama

# 2. Reduce context size to speed up processing
echo "CTX_SIZE=1024" >> .env
docker compose restart llama

# 3. Check system load
top
# If high CPU usage, wait or restart services

# 4. Check LLM server directly
curl -s -X POST http://localhost:8000/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Hello","max_tokens":5}'
```

---

### 🔴 Integration Issues

#### Issue: "AI analysis returns empty or incorrect results"

**Symptoms:**
```json
{"diagnosis": {"health_score": "unknown", "summary": "Analysis parsing failed"}}
```

**Solutions:**
```bash
# 1. Test LLM directly with simple prompt
curl -s -X POST http://localhost:8000/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt":"The blockchain is","max_tokens":20}'

# 2. Check bridge logs for JSON parsing errors
docker compose logs bridge | grep -E "(ERROR|WARNING)"

# 3. Restart services to clear any state issues
docker compose restart

# 4. Verify node data is accessible
curl -s http://localhost:8080/node/status | jq .
```

#### Issue: "Log analysis fails - no logs found"

**Symptoms:**
```json
{"logs_found": 0, "log_analysis": {"summary": "No logs available"}}
```

**Solutions:**
```bash
# 1. Check if Cintara node is writing logs
journalctl -u cintarad -n 20

# 2. For Docker-based logs, ensure node container logs are accessible
docker logs cintara-node 2>/dev/null || echo "No container logs"

# 3. Manually check node data directory
ls -la ~/.tmp-cintarad/
find ~/.tmp-cintarad -name "*.log" -type f

# 4. Test RPC-based log analysis fallback
curl -s http://localhost:8080/node/logs | jq .log_sample
```

---

## 🔧 Complete Recovery Procedures

### Recovery Procedure 1: Clean Restart

```bash
#!/bin/bash
echo "🔄 Performing clean restart..."

# 1. Stop all Docker services
docker compose down

# 2. Check Cintara node status
curl -s http://localhost:26657/status || echo "Node may need restart"

# 3. Clear any Docker issues
docker system prune -f
docker compose pull  # Get latest images

# 4. Restart services
docker compose up -d

# 5. Wait and verify
sleep 10
./scripts/verify-smart-node.sh
```

### Recovery Procedure 2: Full Reset

```bash
#!/bin/bash
echo "🚨 Performing full system reset..."

# 1. Stop and remove all containers
docker compose down -v
docker system prune -af

# 2. Check model file integrity
echo "Checking model file..."
cd models
ls -la mistral-7b-instruct.Q4_K_M.gguf
# If corrupted or missing, re-download:
# wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf

# 3. Reset configuration
cd ..
cp .env.example .env
nano .env  # Update MODEL_FILE and other settings

# 4. Restart everything
docker compose up -d

# 5. Wait for services to stabilize
echo "Waiting for services to start..."
sleep 30

# 6. Run full verification
./scripts/verify-smart-node.sh
```

### Recovery Procedure 3: Cintara Node Reset

```bash
#!/bin/bash
echo "🔄 Resetting Cintara Node..."

# 1. Stop node (if running)
pkill -f cintarad

# 2. Backup existing data (optional)
cp -r ~/.tmp-cintarad ~/.tmp-cintarad.backup.$(date +%Y%m%d)

# 3. Re-run official setup
cd ~/cintara-node/cintara-testnet-script
git pull origin main  # Get latest updates
./cintara_ubuntu_node.sh

# 4. Wait for sync to start
sleep 10
curl -s http://localhost:26657/status | jq .sync_info

# 5. Restart AI services
cd /path/to/cintara-node-llm-bridge
docker compose restart

# 6. Full verification
./scripts/verify-smart-node.sh
```

---

## 📊 Performance Monitoring

### System Resource Monitoring

```bash
# Check overall system health
htop

# Monitor Docker container resources
docker stats

# Check disk usage
df -h
du -sh models/  # Model file should be ~4GB

# Monitor network connectivity
ping -c 3 8.8.8.8
curl -s http://localhost:26657/net_info | jq .result.n_peers
```

### Service-Specific Monitoring

```bash
# Monitor LLM performance
while true; do
  echo "Testing LLM response time..."
  time curl -s -X POST http://localhost:8000/completion \
    -H "Content-Type: application/json" \
    -d '{"prompt":"Test","max_tokens":5}' > /dev/null
  sleep 30
done

# Monitor node sync progress
watch -n 10 'curl -s http://localhost:26657/status | jq "{height: .sync_info.latest_block_height, catching_up: .sync_info.catching_up}"'

# Monitor AI Bridge response times
while true; do
  echo "$(date): AI Bridge health check"
  time curl -s http://localhost:8080/health > /dev/null
  sleep 60
done
```

---

## 🆘 Emergency Contacts & Resources

### Log Locations
- **Cintara Node Logs**: `journalctl -u cintarad -f`
- **Docker Logs**: `docker compose logs -f`
- **System Logs**: `/var/log/syslog`

### Configuration Files
- **Node Config**: `~/.tmp-cintarad/config/config.toml`
- **Environment**: `.env`
- **Docker Compose**: `docker-compose.yml`

### External Resources
- **Cintara Documentation**: [Official Testnet Guide](https://github.com/Cintaraio/cintara-testnet-script)
- **Docker Documentation**: [Compose Reference](https://docs.docker.com/compose/)
- **Model Repository**: [Hugging Face](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF)

### Support Commands
```bash
# Generate diagnostic report
echo "=== DIAGNOSTIC REPORT ===" > diagnostic-report.txt
echo "Date: $(date)" >> diagnostic-report.txt
echo "" >> diagnostic-report.txt
echo "=== System Info ===" >> diagnostic-report.txt
uname -a >> diagnostic-report.txt
free -h >> diagnostic-report.txt
df -h >> diagnostic-report.txt
echo "" >> diagnostic-report.txt
echo "=== Docker Status ===" >> diagnostic-report.txt
docker --version >> diagnostic-report.txt
docker compose ps >> diagnostic-report.txt
echo "" >> diagnostic-report.txt
echo "=== Service Tests ===" >> diagnostic-report.txt
curl -s http://localhost:26657/status | jq .sync_info >> diagnostic-report.txt 2>&1
curl -s http://localhost:8000/health >> diagnostic-report.txt 2>&1
curl -s http://localhost:8080/health >> diagnostic-report.txt 2>&1
echo "" >> diagnostic-report.txt
echo "=== Recent Logs ===" >> diagnostic-report.txt
docker compose logs --tail=20 >> diagnostic-report.txt 2>&1

echo "Diagnostic report saved to: diagnostic-report.txt"
```

Remember: The Smart Cintara Node combines multiple complex systems. Most issues can be resolved by systematically checking each component and ensuring proper configuration and connectivity.