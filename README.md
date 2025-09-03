# Cintara Phase-1 — Validator + LLM + Bridge (Shareable Pack)

This package runs a **Cintara testnet validator node** side-by-side with a **CPU LLM (llama.cpp)** and a small **FastAPI bridge** that turns API calls into LLM prompts and returns **JSON**.

---

## Contents

- `docker-compose.yml` — Full stack (node + llama + bridge + patcher)
- `Dockerfile` — Node image with prebuilt `cintarad` baked in
- `entrypoint.sh` — Init vs. start controller
- `.env.example` — Copy to `.env` and fill `PUBLIC_IP`, etc.
- `bridge/` — FastAPI app with JSON grammar-constrained output
- `scripts/` — Patcher + cleanup scripts
- `models/` — Put your `.gguf` model here
- `data/` — Chain home persists here

---

## 1. EC2 Setup with AWS Nitro Hardening

### Instance Configuration
- **AMI:** Ubuntu Server 22.04 LTS (x86_64)
- **Instance type:** Use AWS Nitro-based instances for enhanced security:
  - `c6i.2xlarge` (8 vCPU / 16 GB) recommended
  - `c6i.xlarge` possible, slower
  - `c6i.4xlarge` faster
- **Storage:** 150 GB gp3 with encryption enabled
- **Nitro Enclaves:** Enable if available for your instance type

### Security Group Configuration
- **Outbound rules:** HTTPS (443) to 0.0.0.0/0 for SSM communication
- **Inbound rules:**
  - TCP 26656 (P2P) from specific CIDR blocks only
  - TCP 26657 (RPC) from specific CIDR blocks only
  - TCP 8080 (Bridge) - restrict to known IPs only
  - **NO SSH (port 22)** - use SSM Session Manager instead

### IAM Role Setup
Create an IAM role with the following policies:
- `AmazonSSMManagedInstanceCore` (for SSM Session Manager)
- Custom policy for CloudWatch logging:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### AWS Nitro Hardening
1. **Instance Metadata Service (IMDSv2):**
   ```bash
   # Force IMDSv2 (prevents SSRF attacks on metadata service)
   # Replace i-0293d765131967de7 with your actual instance ID
   aws ec2 modify-instance-metadata-options \
     --instance-id i-0293d765131967de7 \
     --http-endpoint enabled \
     --http-tokens required \
     --http-put-response-hop-limit 1
   ```

2. **EBS Encryption:** Ensure all volumes are encrypted at rest
3. **VPC Flow Logs:** Enable for network monitoring
4. **CloudTrail:** Enable for API call auditing

**Note:** These hardening steps should be applied after the instance is launched but before deploying the application.

## 2. Connect via SSM Session Manager

### Prerequisites
Install AWS CLI and Session Manager plugin on your local machine:

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Session Manager plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

### Connect to Instance
```bash
# Configure AWS credentials (you'll need AccessKey, SecretKey, and Region)
aws configure

# Get your instance ID from AWS console or CLI:
# aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Connect to your instance via secure shell session (no SSH keys needed)
aws ssm start-session --target i-1234567890abcdef0

# Alternative: Port forwarding for local development access
# This creates a tunnel: localhost:8080 -> instance:8080
aws ssm start-session --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
```

**Tips:**
- Keep the port forwarding session running in a separate terminal
- Use different local ports if 8080 is already in use on your machine
- Multiple port forwarding sessions can run simultaneously

### Instance Setup After Connection
Once connected via SSM, install the SSM agent (if not pre-installed):

```bash
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
```

---

## 3. Install Docker + Compose

**Run these commands on the EC2 instance after connecting via SSM:**

```bash
# Update package index and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg unzip jq

# Create directory for Docker GPG keys
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository to package sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker packages
sudo apt-get update

# Install Docker Engine, CLI, and Compose plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (avoids needing sudo for docker commands)
sudo usermod -aG docker $USER

# Apply group membership for current session
newgrp docker
```

**Verify installation:**
```bash
docker --version
docker compose version
```

---

## 4. Project Setup

```bash
# Clone the repository (replace with actual repository URL)
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Create environment file from template
cp .env.example .env

# Edit the environment file - IMPORTANT: Set your EC2's public IP
nano .env   # set PUBLIC_IP=<your EC2 public IP/DNS>
```

**Key environment variables to configure:**
- `PUBLIC_IP`: Your EC2 instance's public IP or DNS name
- `MODEL_FILE`: Must match the GGUF file you download (default: mistral-7b-instruct.Q4_K_M.gguf)
- `LLM_THREADS`: Number of CPU threads for LLM (default: 8, adjust based on instance size)

**Get your EC2 public IP:**
```bash
# AWS CLI (on your local machine)
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query 'Reservations[0].Instances[0].PublicIpAddress'
```

---

## 5. Download a Model (GGUF)

**Create models directory and download LLM model:**

```bash
# Create models directory if it doesn't exist
mkdir -p models
cd models

# Download Mistral 7B model (4-bit quantized, ~4GB download)
# This may take 5-10 minutes depending on connection speed
**Important:** Ensure the `MODEL_FILE` in your `.env` file matches the downloaded filename exactly.
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf -O mistral-7b-instruct.Q4_K_M.gguf

cd ..
```

**Model options (choose one):**
- `Q4_K_M.gguf` - 4-bit quantized, good balance (recommended)
- `Q5_K_M.gguf` - 5-bit quantized, better quality, larger size
- `Q8_0.gguf` - 8-bit quantized, best quality, much larger

**Verify model configuration:**
```bash
# Check what model file is configured in .env
grep "MODEL_FILE=" .env

# Check what model files are actually downloaded
ls -la models/

# Verify they match - both commands should show the same filename
echo "Configured: $(grep 'MODEL_FILE=' .env | cut -d'=' -f2)"
echo "Available: $(ls models/*.gguf 2>/dev/null | xargs -n1 basename)"
```

**Important:** Ensure the `MODEL_FILE` in your `.env` file matches the downloaded filename exactly.



---

## 6. Build, Init, Patch, Run

**Follow these steps in order - each step is required:**

```bash
# Step 1: Build all Docker images (takes 5-10 minutes)
docker compose build

# Step 2: Fix data directory permissions (required for Docker volume mounting)
sudo mkdir -p ./data
sudo chown -R $USER:$USER ./data
sudo chmod -R 755 ./data

# Step 2.1: Fix script permissions (required for config patcher)
chmod +x scripts/*.sh

# Step 3: Initialize the Cintara node (creates blockchain data directory and wallet)
docker compose run --rm -e RUN_MODE=init cintara-node

# IMPORTANT: The init step will display your mnemonic phrase and wallet address
# SAVE THE MNEMONIC PHRASE SECURELY - you'll need it to recover your wallet!

# Step 3.1: Verify initialization completed
ls -la data/.tmp-cintarad/config/
# You should see config.toml and other config files

# Step 3.2: Check your wallet information
cat data/.tmp-cintarad/mnemonic.txt  # Your mnemonic phrase (KEEP SECURE!)
docker compose run --rm cintara-node cintarad keys show validator -a --home /data/.tmp-cintarad --keyring-backend=file

# Step 4: Patch configuration files (sets network addresses)
docker compose run --rm config-patcher

# Step 5: Start all services in background
docker compose up -d
```

**What each step does:**
1. **Build**: Downloads base images and builds the Cintara node container
2. **Permissions**: Creates data directory with correct ownership for Docker volumes
2.1. **Script Permissions**: Ensures shell scripts are executable
3. **Init**: Creates blockchain configuration, generates wallet and mnemonic phrase
4. **Patch**: Updates config files with your public IP for P2P networking
5. **Run**: Starts the validator node, LLM server, and bridge API

**Important Security Notes:**
- **NEVER share your mnemonic phrase** - it provides full access to your wallet
- **Backup your mnemonic securely** - store it offline in a safe place
- The mnemonic is saved to `data/.tmp-cintarad/mnemonic.txt` for reference

**Monitor startup progress:**
```bash
# Watch all service logs
docker compose logs -f

# Watch specific service
docker compose logs -f cintara-node
docker compose logs -f bridge
docker compose logs -f llama
```

---

## 7. Verify and Get Node Information

**Check services are running properly:**

```bash
# Check all container status
docker compose ps

# 1. Check blockchain node status (should show false when synced)
curl -s http://localhost:26657/status | jq .sync_info.catching_up

# 2. Check bridge API health (now includes node status)
curl -s http://localhost:8080/health | jq .

# 3. Get detailed node status
curl -s http://localhost:8080/node/status | jq .

# 4. Get LLM-powered node diagnostics
curl -s -X POST http://localhost:8080/node/diagnose | jq .

# 5. Test transaction analysis
curl -s -X POST http://localhost:8080/analyze \
  -H "content-type: application/json" \
  -d '{"transaction":{"hash":"0xabc","amount":"123","from":"addr1","to":"addr2"}}' | jq .

# 6. Analyze node logs for issues
curl -s http://localhost:8080/node/logs | jq .
```

**Get your node and wallet information:**
```bash
# Get your Node ID (needed for network peers)
docker compose exec cintara-node cintarad tendermint show-node-id --home /data/.tmp-cintarad

# Get your validator address
docker compose exec cintara-node cintarad keys show validator -a --home /data/.tmp-cintarad --keyring-backend=file

# View your mnemonic (KEEP SECURE!)
cat data/.tmp-cintarad/mnemonic.txt

# Get validator public key (needed for creating validator)
docker compose exec cintara-node cintarad tendermint show-validator --home /data/.tmp-cintarad
```

**Connect to Cintara Network:**
- Use your **Node ID** to connect with other peers
- Use your **Validator Address** to receive tokens for staking
- Use your **Mnemonic** to restore your wallet in other applications
- Use your **Validator Public Key** when creating a validator on-chain

**Access from your laptop (using SSM port forwarding):**
```bash
# First, set up port forwarding via SSM (run in separate terminal)
aws ssm start-session --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["26657"],"localPortNumber":["26657"]}'

# Then access via localhost (run in another terminal)
curl -s http://localhost:26657/status | jq .
```

**Expected responses:**

**Bridge Health Check:**
```json
{
  "status": "ok",
  "components": {
    "llm_server": "ok",
    "blockchain_node": "synced"
  },
  "timestamp": "2024-01-01T00:00:00.000000"
}
```

**Node Diagnostics:**
```json
{
  "diagnosis": {
    "health_score": "good",
    "issues": [],
    "recommendations": ["Node is healthy"],
    "summary": "Node is synced and performing well"
  },
  "latency_ms": 1500
}
```

**Transaction Analysis:**
```json
{
  "analysis": {
    "risk_level": "low",
    "risks": ["No significant risks detected"],
    "insights": ["Standard transfer transaction"],
    "recommendation": "Transaction appears safe"
  },
  "latency_ms": 800
}
```

**Troubleshooting:**

**Common Docker Issues:**
```bash
# Permission denied errors (like "cannot create directory '/data/.tmp-cintarad'")
sudo mkdir -p ./data ./models
sudo chown -R $USER:$USER ./data ./models
sudo chmod -R 755 ./data ./models

# Script permission errors (like "/work/scripts/patch-config.sh: Permission denied")
chmod +x scripts/*.sh

# If init step fails with permission errors, reset data directory:
sudo rm -rf ./data
sudo mkdir -p ./data
sudo chown -R $USER:$USER ./data

# If services fail to start
docker compose logs cintara-node
docker compose logs bridge
docker compose logs llama

# Restart specific service
docker compose restart bridge

# Check disk space (models are large)
df -h

# Check Docker daemon is running
sudo systemctl status docker

# Reset everything and start fresh
docker compose down -v
sudo rm -rf ./data
# Then repeat from Step 2 (permissions)
```

**Port already in use errors:**
```bash
# Find what's using the port
sudo netstat -tlnp | grep :8080
sudo netstat -tlnp | grep :26657

# Kill process using the port (replace PID)
sudo kill <PID>
```

---

## 8. Cleanup

```bash
./scripts/cleanup.sh
```

---

## 9. Autostart with systemd (optional)

**Create a systemd service for automatic startup on boot:**

```bash
# Create systemd service file
sudo tee /etc/systemd/system/cintara-compose.service >/dev/null <<'EOF'
[Unit]
Description=Cintara Phase-1 Compose
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=/home/ubuntu/cintara-node-llm-bridge
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable --now cintara-compose
```

**Manage the service:**
```bash
# Check service status
sudo systemctl status cintara-compose

# Stop the service
sudo systemctl stop cintara-compose

# Start the service
sudo systemctl start cintara-compose

# View service logs
sudo journalctl -u cintara-compose -f
```

**Note:** Adjust the `WorkingDirectory` path if you cloned the repository to a different location.

**Keeping your deployment updated:**
```bash
# Pull latest changes
cd ~/cintara-node-llm-bridge
git pull

# Rebuild and restart services if needed
docker compose build
docker compose up -d
```

---
