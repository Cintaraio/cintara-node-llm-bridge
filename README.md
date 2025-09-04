# 🚀 Smart Cintara Node with AI Integration

This setup creates a **Smart Cintara Node** that combines blockchain functionality with AI capabilities using Docker Compose. It includes a Cintara testnet validator, CPU-based LLM server (Mistral 7B), and an AI bridge for intelligent blockchain analysis.

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
- `CHAIN_ID`: Testnet chain ID (default: cintara_11001-1)
- `MONIKER`: Your node name (default: cintara-smart-node)
- `MODEL_FILE`: Must match the GGUF file you download (default: mistral-7b-instruct.Q4_K_M.gguf)
- `LLM_THREADS`: Number of CPU threads for LLM (default: 8, adjust based on instance size)
- `CTX_SIZE`: LLM context size (default: 2048)

**Get your EC2 public IP:**
```bash
# AWS CLI (on your local machine)
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query 'Reservations[0].Instances[0].PublicIpAddress'
```

## 5. Quick Start - One-Command Setup

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
docker compose up -d
```

This will:
1. 🔧 **Setup** the Cintara node automatically
2. 🧠 **Start** the AI/LLM server
3. 🌉 **Launch** the smart bridge API
4. 📊 **Monitor** all services

## 6. Verify Smart Node

```bash
# Check all services are running
docker compose ps

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
docker compose logs -f

# Restart services  
docker compose restart

# Stop everything
docker compose down

# Full reset (removes data)
docker compose down -v
sudo rm -rf ./data
```

## 7. Get Node Information

**Get your node and wallet information:**
```bash
# Get your Node ID (needed for network peers)
docker compose exec cintara-node cintarad tendermint show-node-id --home /data/.tmp-cintarad

# Get your validator address
docker compose exec cintara-node cintarad keys show validator -a --home /data/.tmp-cintarad --keyring-backend=test

# View your mnemonic (KEEP SECURE!)
cat data/.tmp-cintarad/mnemonic.txt

# Get validator public key (needed for creating validator)
docker compose exec cintara-node cintarad tendermint show-validator --home /data/.tmp-cintarad
```

**Access from your laptop (using SSM port forwarding):**
```bash
# First, set up port forwarding via SSM (run in separate terminal)
aws ssm start-session --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["26657"],"localPortNumber":["26657"]}'

# Then access via localhost (run in another terminal)
curl -s http://localhost:26657/status | jq .
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
docker compose logs cintara-setup

# Restart setup
docker compose restart node-setup
```

**AI not responding:**
```bash
# Check LLM server
docker compose logs llama

# Test model directly
curl http://localhost:8000/health
```

**Need manual setup:**
```bash
# Access node container
docker compose exec cintara-node bash

# Run manual setup
cd cintara-testnet-script
./cintara_ubuntu_node.sh
```

## 8. Autostart with systemd (optional)

**Create a systemd service for automatic startup on boot:**

```bash
# Create systemd service file
sudo tee /etc/systemd/system/cintara-compose.service >/dev/null <<'EOF'
[Unit]
Description=Cintara Smart Node Compose
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

## 9. Cleanup

```bash
./scripts/cleanup.sh
```

## 🎉 Success!

You now have a **Smart Cintara Node** with AI capabilities running! 

The node combines blockchain functionality with artificial intelligence to provide intelligent monitoring, analysis, and insights for your Cintara testnet participation.

---

## Contents

- `docker-compose.yml` — Full smart stack (node + llama + bridge + setup)
- `Dockerfile.simple` — Node image based on official cintara-testnet-script
- `setup-automation.sh` — Automated node initialization
- `.env.example` — Copy to `.env` and configure
- `bridge/` — FastAPI app with AI-powered analysis
- `scripts/` — Helper and cleanup scripts
- `models/` — Put your `.gguf` model here
- `data/` — Node data persists here