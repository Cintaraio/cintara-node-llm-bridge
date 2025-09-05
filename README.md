# 🚀 Smart Cintara Node with AI Integration

A hybrid setup that combines a Cintara blockchain testnet validator with AI-powered analysis capabilities using LLM integration. This setup uses the [official Cintara testnet script](https://github.com/Cintaraio/cintara-testnet-script) for maximum reliability.

## 📋 Prerequisites

**Environment Requirements:**
- **EC2 Instance** (recommended: t3.medium or larger) or equivalent cloud/VPS environment
- **Ubuntu 22.04 LTS** or compatible Linux distribution
- **Minimum 4 CPU cores** and **8GB RAM** for optimal performance
- **20GB+ storage** for blockchain data and AI model
- **Docker and Docker Compose** installed
- **Public IP address** for P2P connectivity

**Recommended Setup:**
- AWS EC2 with SSM Session Manager for secure access
- Security groups configured for ports 26656 (P2P), 26657 (RPC), 1317 (API)
- EBS volume with encryption enabled

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# 2. Make scripts executable
chmod +x scripts/*.sh

# 3. Setup Cintara node (follow prompts - SAVE MNEMONIC PHRASE!)
./scripts/setup-blockchain-node.sh

# 4. Configure environment
cp .env.example .env
nano .env  # Edit MODEL_FILE and other settings

# 5. Download AI model (~638MB)
mkdir -p models && cd models
wget https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O tinyllama-1.1b-chat.Q4_K_M.gguf
cd ..

# 6. Start AI services
./scripts/start-smart-node.sh

# 7. Verify everything works
./scripts/verify-smart-node.sh
```

**🎯 Result**: Smart Cintara Node with AI capabilities running on:
- **Cintara Node**: `http://localhost:26657` (RPC) + `http://localhost:1317` (API)
- **AI Bridge**: `http://localhost:8080` (AI-powered blockchain analysis)

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cintara Node  │    │   LLM Server     │    │   AI Bridge     │
│   (Official)    │◄───┤   (Docker)       │◄───┤   (Docker)      │
│   Port: 26657   │    │   Port: 8000     │    │   Port: 8080    │
│   Chain: cintara│    │   TinyLlama 1B   │    │   FastAPI       │
│   _11001-1      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🎯 What You Get

- **Cintara Testnet Node** - Official testnet validator using proven setup scripts
- **AI/LLM Integration** - CPU-based TinyLlama 1.1B model for intelligent blockchain analysis
- **Smart Bridge API** - AI-powered Cintara node monitoring and diagnostics
- **Hybrid Architecture** - Reliable official node setup + containerized AI services
- **Production Ready** - Based on official Cintara documentation and best practices

## 📋 Prerequisites

- **AWS EC2 Instance** with Ubuntu 22.04 (recommended) or local macOS
- **Instance Type**: t3.large or larger (8GB+ RAM, 50GB+ storage)
- **Docker and Docker Compose** installed
- **Internet connection** for model download (~4GB)
- **AWS CLI** configured (for EC2 setup)

---

## 🚀 Complete Setup Guide

### Step 1: AWS EC2 Instance Setup (Recommended)

#### 1.1 Launch EC2 Instance with Security Hardening

**Create EC2 instance using AWS CLI:**
```bash
# Set your variables
REGION="us-east-1"
KEY_PAIR_NAME="your-key-pair"
INSTANCE_NAME="smart-blockchain-node"

# Create security group with minimal required ports
aws ec2 create-security-group \
  --group-name blockchain-node-sg \
  --description "Security group for Smart Blockchain Node" \
  --region $REGION

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=blockchain-node-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $REGION)

# Configure security group rules (restrictive by design)
# Allow P2P blockchain traffic (26656) from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 26656 \
  --cidr 0.0.0.0/0 \
  --region $REGION

# Allow RPC access (26657) only from your IP for security
YOUR_IP=$(curl -s ifconfig.me)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 26657 \
  --cidr $YOUR_IP/32 \
  --region $REGION

# Allow AI Bridge (8080) only from your IP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr $YOUR_IP/32 \
  --region $REGION

# LLM server (8000) - internal only, no external access needed
```

#### 1.2 Launch Instance with Nitro Hardening

```bash
# Launch instance with security hardening
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.large \
  --key-name $KEY_PAIR_NAME \
  --security-group-ids $SG_ID \
  --block-device-mappings '[{
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "VolumeSize": 50,
      "VolumeType": "gp3",
      "Encrypted": true,
      "DeleteOnTermination": true
    }
  }]' \
  --metadata-options '{
    "HttpEndpoint": "enabled",
    "HttpTokens": "required",
    "HttpPutResponseHopLimit": 1,
    "InstanceMetadataServiceOptions": {
      "HttpEndpoint": "enabled",
      "HttpTokens": "required"
    }
  }' \
  --monitoring Enabled=true \
  --tag-specifications "ResourceType=instance,Tags=[
    {Key=Name,Value=$INSTANCE_NAME},
    {Key=Environment,Value=blockchain-node},
    {Key=Security,Value=nitro-hardened}
  ]" \
  --region $REGION
```

#### 1.3 Configure IAM Role for SSM Access

**Create IAM role for SSM Session Manager:**
```bash
# Create trust policy for EC2
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name BlockchainNodeSSMRole \
  --assume-role-policy-document file://trust-policy.json

# Attach SSM managed policy
aws iam attach-role-policy \
  --role-name BlockchainNodeSSMRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name BlockchainNodeProfile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name BlockchainNodeProfile \
  --role-name BlockchainNodeSSMRole

# Attach instance profile to your EC2 instance
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text \
  --region $REGION)

aws ec2 associate-iam-instance-profile \
  --instance-id $INSTANCE_ID \
  --iam-instance-profile Name=BlockchainNodeProfile \
  --region $REGION
```

#### 1.4 Connect via SSM Session Manager

**Connect securely without SSH keys:**
```bash
# Install AWS CLI and Session Manager plugin (if not already installed)
# For macOS:
brew install awscli session-manager-plugin

# For Ubuntu:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Session Manager plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb

# Connect to your instance
aws ssm start-session --target $INSTANCE_ID --region $REGION
```

#### 1.5 Configure VPC Flow Logs (Additional Security)

```bash
# Create VPC Flow Logs for network monitoring
VPC_ID=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].VpcId' \
  --output text \
  --region $REGION)

# Create CloudWatch Log Group
aws logs create-log-group \
  --log-group-name /aws/vpc/flowlogs \
  --region $REGION

# Create Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids $VPC_ID \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs \
  --deliver-logs-permission-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/flowlogsRole \
  --region $REGION
```

### Step 2: Initial Server Hardening

**Once connected via SSM, harden the server:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Install security tools
sudo apt install -y fail2ban ufw htop curl jq

# Configure firewall (UFW)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 26656/tcp comment 'Blockchain P2P'
sudo ufw allow from $YOUR_IP to any port 26657 comment 'RPC access'
sudo ufw allow from $YOUR_IP to any port 8080 comment 'AI Bridge'
sudo ufw --force enable

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Secure shared memory
echo 'tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0' | sudo tee -a /etc/fstab

# Disable unused network protocols
echo 'install dccp /bin/true' | sudo tee -a /etc/modprobe.d/blacklist-rare-network.conf
echo 'install sctp /bin/true' | sudo tee -a /etc/modprobe.d/blacklist-rare-network.conf
echo 'install rds /bin/true' | sudo tee -a /etc/modprobe.d/blacklist-rare-network.conf
echo 'install tipc /bin/true' | sudo tee -a /etc/modprobe.d/blacklist-rare-network.conf

# Configure kernel parameters for security
cat | sudo tee -a /etc/sysctl.conf << 'EOF'
# Network security
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.all.log_martians=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
EOF

sudo sysctl -p

# Enable AWS CloudWatch monitoring
sudo apt install -y collectd
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
cat | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "BlockchainNode/System",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "diskio": {
        "measurement": ["io_time"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": ["tcp_established", "tcp_time_wait"],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": ["swap_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "/aws/ec2/blockchain-node/auth",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/blockchain-node/syslog",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable Nitro Enclave (if supported by instance type)
# Note: Requires specific instance types like m5n, c5n, r5n, etc.
if grep -q "nitro" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
    echo "Nitro system detected - enabling additional hardening"
    
    # Install AWS Nitro Enclaves CLI (if needed for enhanced security)
    sudo amazon-linux-extras install aws-nitro-enclaves-cli -y 2>/dev/null || true
    
    # Configure Nitro Enclaves allocator service
    cat | sudo tee /etc/nitro_enclaves/allocator.yaml << 'EOF' 2>/dev/null || true
---
# Allocator configuration
memory_mib: 512
cpu_count: 2
EOF
    
    sudo systemctl enable --now nitro-enclaves-allocator.service 2>/dev/null || true
fi

# Configure AWS Inspector for vulnerability assessments
aws inspector2 enable --resource-types EC2 --region $REGION 2>/dev/null || echo "Inspector v2 setup requires additional permissions"

# Install and configure AWS Systems Manager Patch Manager
sudo snap install amazon-ssm-agent --classic 2>/dev/null || true
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service 2>/dev/null || true
sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service 2>/dev/null || true
```

### Step 3: Install Dependencies

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Note: You may need to log out and back in for group changes to take effect
```

**macOS:**
```bash
# Install Docker Desktop
brew install --cask docker
```

### Step 4: Clone Smart Cintara Node Repository

**Clone the Smart Cintara Node with AI Integration repository:**
```bash
# Clone the official Smart Cintara Node repository
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge

# Make scripts executable
chmod +x scripts/*.sh

# Verify repository contents
ls -la
```

**Repository contents:**
```
cintara-node-llm-bridge/
├── README.md                    # Complete setup guide
├── docker-compose.yml           # LLM + AI Bridge services
├── .env.example                 # Environment configuration template
├── bridge/                      # AI Bridge FastAPI application
│   ├── app.py                   # Main AI bridge server
│   ├── Dockerfile               # Container configuration
│   └── requirements.txt         # Python dependencies
├── scripts/                     # Automated setup scripts
│   ├── setup-blockchain-node.sh    # Cintara node setup
│   ├── start-smart-node.sh         # Unified startup
│   ├── verify-smart-node.sh        # Comprehensive testing
│   └── test-llm-functionality.sh   # LLM-specific tests
└── models/                      # AI model directory (created during setup)
```

### Step 5: Setup Cintara Blockchain Node

This setup uses the [Official Cintara Testnet Script](https://github.com/Cintaraio/cintara-testnet-script) for maximum reliability and compatibility.

#### 5.1 Cintara Node Requirements

**System Requirements (from official docs):**
- **OS**: Ubuntu 20.04 or 22.04 LTS (recommended: 22.04)
- **RAM**: 4GB minimum (8GB recommended for AI integration)
- **Storage**: 20GB available (50GB recommended for full setup)
- **CPU**: 2 cores minimum
- **Network**: Stable internet connection

#### 5.2 Cintara Network Details

- **Chain ID**: `cintara_11001-1`
- **Token Denom**: `cint`
- **RPC Port**: 26657
- **API Port**: 1317  
- **P2P Port**: 26656

#### 5.3 Automated Setup

```bash
# Run automated setup script (uses official Cintara script)
./scripts/setup-blockchain-node.sh
```

**The script will:**
1. Clone the [official Cintara testnet repository](https://github.com/Cintaraio/cintara-testnet-script)
2. Run `cintara_ubuntu_node.sh` with interactive setup
3. Configure the node as a systemd service
4. Initialize blockchain data directory

#### 5.4 Interactive Setup Process

**During setup, you'll be prompted for:**
- **Node Name**: Enter a unique identifier (e.g., "my-smart-node")
- **Keyring Password**: Set a secure password (8+ characters)

#### 🚨 CRITICAL: Mnemonic Phrase Security

**The setup will display a 24-word mnemonic phrase that looks like:**
```
word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 word21 word22 word23 word24
```

**⚠️ IMMEDIATELY SAVE THIS MNEMONIC PHRASE:**

**✅ DO THIS:**
1. **Write it down on paper** - Store in a fireproof safe
2. **Take a photo** - Store on an encrypted device offline
3. **Save to password manager** - Use encrypted vault (recommended)
4. **Create multiple copies** - Store in different secure locations
5. **Verify you wrote it correctly** - Double-check every word

**❌ NEVER DO THIS:**
- Don't store in plain text files on your computer
- Don't send via email or messaging apps
- Don't store in cloud services without encryption
- Don't share with anyone
- Don't lose it (funds cannot be recovered!)

**🔒 Why This Matters:**
- **Only way to recover your validator** if the server fails
- **Required for accessing any staked tokens** 
- **Cannot be regenerated** - once lost, it's gone forever
- **Anyone with this phrase controls your validator**

**Example secure storage command during setup:**
```bash
# When the mnemonic appears, immediately save it
echo "word1 word2 word3..." > ~/mnemonic_backup.txt
chmod 600 ~/mnemonic_backup.txt

# Then immediately move to secure location and delete from server
```

#### 5.5 Verify Cintara Node Installation

```bash
# Check if node service is running
sudo systemctl status cintarachain.service

# View real-time node logs
journalctl -u cintarachain.service -f

# Test RPC endpoint
curl -s http://localhost:26657/status | jq .result.sync_info

# Check sync status (should eventually show "catching_up": false)
curl -s http://localhost:26657/status | jq .result.sync_info.catching_up

# Check peer connections
curl -s http://localhost:26657/net_info | jq .result.n_peers
```

#### 5.6 Manual Setup (Alternative)

If you prefer to run the official setup manually:

```bash
# Clone official repository
git clone https://github.com/Cintaraio/cintara-testnet-script.git
cd cintara-testnet-script

# Make script executable  
chmod +x cintara_ubuntu_node.sh

# Run official setup
./cintara_ubuntu_node.sh
```

**Important Notes:**
- This is **testnet software** - use at your own risk
- The node will sync with the Cintara testnet blockchain
- Initial sync may take 30-60 minutes depending on network speed
- **🚨 CRITICAL**: Your 24-word mnemonic phrase is the ONLY way to recover your validator keys. Write it down immediately when displayed during setup and store it securely offline. Loss of mnemonic = permanent loss of validator access!

### Step 6: Configure Environment

```bash
# Copy and edit environment file
cp .env.example .env
nano .env
```

**Required settings in `.env`:**
```bash
# Model configuration
MODEL_FILE=tinyllama-1.1b-chat.Q4_K_M.gguf
LLM_THREADS=4  # Set to your CPU count (4 for most systems)
CTX_SIZE=2048  # Reduce to 1024 if you have <8GB RAM

# Node connection
NODE_URL=http://localhost:26657
```

**💡 Resource Optimization Tips:**
- **LLM_THREADS**: Set to your CPU count or less. Check with `nproc` command
- **CTX_SIZE**: 
  - 2048 (default) - for 8GB+ RAM systems
  - 1024 - for 4-8GB RAM systems  
  - 512 - for <4GB RAM systems (minimal)

### Step 7: Download AI Model

```bash
mkdir -p models
cd models

# Download TinyLlama model (~638MB) - takes 1-2 minutes
echo "📥 Downloading AI model (this may take a couple minutes)..."
wget https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O tinyllama-1.1b-chat.Q4_K_M.gguf

cd ..
```

### Step 8: Start AI Services

```bash
# Use unified startup script (recommended)
./scripts/start-smart-node.sh

# Or start manually
docker compose up -d
```

---

## ✅ Verification & Testing

### Quick Health Check

```bash
# Run automated verification suite
./scripts/verify-smart-node.sh
```

### Manual Health Checks

```bash
# Test Cintara node RPC
curl http://localhost:26657/status | jq .sync_info

# Test Cintara node API  
curl http://localhost:1317/cosmos/base/node/v1beta1/config

# Test LLM server  
curl http://localhost:8000/health

# Test AI bridge
curl http://localhost:8080/health
```

---

## 🧠 AI-Powered Features

### 1. Intelligent Node Diagnostics

Get AI-powered analysis of your node's health:

```bash
curl -s -X POST http://localhost:8080/node/diagnose | jq .
```

**Example response:**
```json
{
  "diagnosis": {
    "health_score": "good",
    "issues": [],
    "recommendations": ["Monitor peer diversity"],
    "summary": "Node is healthy and fully synchronized"
  },
  "timestamp": "2024-09-04T14:30:00Z"
}
```

### 2. Smart Transaction Analysis

Analyze transactions with AI insights:

```bash
curl -s -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": {
      "hash": "0xabc123...",
      "amount": "1000",
      "from": "addr1...",
      "to": "addr2..."
    }
  }' | jq .
```

### 3. Intelligent Log Analysis

Get AI-powered analysis of blockchain node logs:

```bash
# Get recent logs with AI analysis
curl -s http://localhost:8080/node/logs | jq .

# Analyze specific patterns
curl -s -X POST http://localhost:8080/node/logs/analyze \
  -H "Content-Type: application/json" \
  -d '{"lines": 100, "level": "error"}' | jq .
```

### 4. Interactive AI Chat

Ask the AI about your node:

```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the current status of my blockchain node?"}' | jq .
```

**Example questions:**
- "What is the current status of my node?"
- "Are there any issues I should be concerned about?"
- "How is my node's performance?"
- "What maintenance should I perform?"

### 5. Peer Connectivity Analysis

Analyze network connectivity with AI:

```bash
curl -s http://localhost:8080/node/peers | jq .
```

### 6. Block Transaction Analysis

Analyze transactions in specific blocks:

```bash
# Analyze latest block transactions
LATEST_BLOCK=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
curl -s http://localhost:8080/node/transactions/$LATEST_BLOCK | jq .
```

---

## 🎛️ Available Services

| Service | Port | Description |
|---------|------|-------------|
| **Cintara Node RPC** | 26657 | Blockchain RPC API (cintara_11001-1) |
| **Cintara Node API** | 1317 | REST API endpoint |
| **Cintara P2P** | 26656 | Peer-to-peer network connections |
| **Smart Bridge** | 8080 | AI-enhanced Cintara monitoring API |
| **LLM Server** | 8000 | Internal AI model server (TinyLlama 1.1B) |

---

---

## 🔐 AWS Security Monitoring & Maintenance

### Security Monitoring

**Monitor your EC2 instance security:**
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace BlockchainNode/System \
  --metric-name cpu_usage_user \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region $REGION

# Check security group compliance
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region $REGION

# Review VPC Flow Logs
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region $REGION

# Check for unauthorized access attempts
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["grep \"Failed password\" /var/log/auth.log | tail -10"]' \
  --region $REGION
```

### Cost Optimization

**Monitor and optimize costs:**
```bash
# Enable detailed monitoring (additional cost but better insights)
aws ec2 monitor-instances --instance-ids $INSTANCE_ID --region $REGION

# Set up billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "BlockchainNode-HighCosts" \
  --alarm-description "Alert when blockchain node costs are high" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 100.0 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --region us-east-1

# Schedule instance stop/start (optional - for non-24/7 operations)
# Create Lambda function to stop instance during off-hours
cat > stop-instance-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:StopInstances",
        "ec2:StartInstances",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
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
EOF
```

### Backup and Recovery

**Setup automated backups:**
```bash
# Create AMI snapshots
aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name "blockchain-node-backup-$(date +%Y%m%d)" \
  --description "Automated backup of blockchain node" \
  --region $REGION

# Setup automated daily snapshots via Lambda
aws events put-rule \
  --name "daily-blockchain-backup" \
  --schedule-expression "cron(0 2 * * ? *)" \
  --region $REGION

# Backup blockchain data to S3
aws s3 mb s3://your-blockchain-backups-$(date +%s) --region $REGION

# Sync blockchain data directory
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo aws s3 sync ~/.tmp-blockchain-data s3://your-blockchain-backups-bucket/data/"]' \
  --region $REGION
```

---

## 🛠️ Management Commands

### View Logs
```bash
# All Docker services
docker compose logs -f

# Specific service
docker compose logs -f llama
docker compose logs -f bridge

# Blockchain node logs (if running as service)
journalctl -u blockchain-node -f
```

### Restart Services
```bash
# Restart Docker services only
docker compose restart

# Stop Docker services
docker compose down

# Full restart including node
./scripts/start-smart-node.sh
```

### Health Monitoring

**Local monitoring script:**
```bash
# Create comprehensive monitoring script
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "🔍 Smart Blockchain Node Health Check"
echo "===================================="
echo "Timestamp: $(date)"
echo ""

# System Resources
echo "📊 System Resources:"
echo "- CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "- Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%"), $3/$2 * 100.0}')"
echo "- Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"
echo ""

# Blockchain Node
echo "🔗 Blockchain Node Status:"
if curl -s http://localhost:26657/status > /dev/null; then
    echo "✅ Blockchain Node: Healthy"
    SYNC=$(curl -s http://localhost:26657/status | jq -r .result.sync_info.catching_up)
    BLOCK_HEIGHT=$(curl -s http://localhost:26657/status | jq -r .result.sync_info.latest_block_height)
    PEERS=$(curl -s http://localhost:26657/net_info | jq -r .result.n_peers)
    echo "   Sync Status: $([ "$SYNC" = "false" ] && echo "✅ Synced" || echo "⏳ Syncing")"
    echo "   Block Height: $BLOCK_HEIGHT"
    echo "   Peer Count: $PEERS"
else
    echo "❌ Blockchain Node: Down"
fi
echo ""

# Docker Services
echo "🐳 Docker Services:"
if command -v docker > /dev/null; then
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
else
    echo "Docker not available"
fi
echo ""

# LLM Server
echo "🤖 LLM Server:"
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ LLM Server: Healthy"
    MODEL_INFO=$(curl -s http://localhost:8000/v1/models | jq -r '.data[0].id // "Unknown"' 2>/dev/null)
    echo "   Model: $MODEL_INFO"
else
    echo "❌ LLM Server: Down"
fi
echo ""

# AI Bridge
echo "🌉 AI Bridge:"
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ AI Bridge: Healthy"
    # Test AI functionality
    AI_RESPONSE=$(curl -s -X POST http://localhost:8080/chat \
      -H "Content-Type: application/json" \
      -d '{"message":"ping"}' | jq -r '.response // "No response"' 2>/dev/null)
    echo "   AI Test: ${AI_RESPONSE:0:50}..."
else
    echo "❌ AI Bridge: Down"
fi
echo ""

# Security Status
echo "🔐 Security Status:"
echo "- Firewall: $(sudo ufw status | grep -q "Status: active" && echo "✅ Active" || echo "❌ Inactive")"
echo "- Fail2ban: $(sudo systemctl is-active fail2ban 2>/dev/null || echo "❌ Not running")"
if command -v aws > /dev/null; then
    echo "- SSM Agent: $(sudo systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent.service 2>/dev/null || echo "❌ Not running")"
fi
EOF

chmod +x monitor.sh
./monitor.sh
```

**AWS CloudWatch monitoring:**
```bash
# Create CloudWatch dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "BlockchainNodeDashboard" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["BlockchainNode/System", "cpu_usage_user", "InstanceId", "'$INSTANCE_ID'"],
            [".", "mem_used_percent", ".", "."],
            [".", "disk_used_percent", ".", "."]
          ],
          "period": 300,
          "stat": "Average",
          "region": "'$REGION'",
          "title": "System Resources"
        }
      }
    ]
  }' \
  --region $REGION

# Create custom metric for blockchain sync status
aws cloudwatch put-metric-data \
  --namespace "BlockchainNode/Custom" \
  --metric-data MetricName=SyncStatus,Value=1,Unit=None \
  --region $REGION
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: "Blockchain node not responding"
```bash
# Check if node process is running
ps aux | grep blockchain-node

# If not running, restart
cd ~/blockchain-node/testnet-script
# Follow the restart instructions from setup

# Check node logs
journalctl -u blockchain-node -n 50
```

#### Issue: "LLM server not starting"
```bash
# Check Docker logs
docker compose logs llama

# Common solutions:
# 1. Model file missing - re-download model
# 2. Insufficient memory - check: free -h
# 3. Port conflict - check: sudo netstat -tlnp | grep :8000

# Restart LLM service
docker compose restart llama
```

#### Issue: "Error response from daemon: range of CPUs is from 0.01 to X.XX, as there are only X CPUs available"

**This error occurs when Docker Compose tries to allocate more CPU resources than available.**

```bash
# Check your system's CPU count
nproc

# Update your .env file with appropriate CPU settings
echo "LLM_THREADS=$(nproc)" >> .env

# For systems with 4 CPUs, use these settings:
echo "LLM_THREADS=4" >> .env
echo "CTX_SIZE=1024" >> .env  # Reduce if low memory

# Restart services
docker compose down
docker compose up -d
```

**System-specific recommendations:**
- **4 CPU cores**: `LLM_THREADS=4`, Docker limit `3.5 CPUs`
- **8 CPU cores**: `LLM_THREADS=6`, Docker limit `7.0 CPUs`  
- **16+ CPU cores**: `LLM_THREADS=8`, Docker limit `14.0 CPUs`

#### Issue: "AI Bridge shows blockchain_node: down"

**Symptoms:**
```json
{"status":"degraded","components":{"llm_server":"ok","blockchain_node":"down"}}
```

**This means the AI Bridge can't connect to the Cintara node.**

```bash
# 1. Verify Cintara node is actually running
curl http://localhost:26657/status | jq .sync_info

# 2. Check if node is listening on correct interface
sudo netstat -tlnp | grep :26657

# 3. Check bridge logs for connection errors
docker compose logs bridge

# 4. Test bridge connectivity to node
docker compose exec bridge curl -v http://localhost:26657/status

# 5. Restart bridge service
docker compose restart bridge

# 6. If still failing, recreate services
docker compose down
docker compose up -d
```

**Root causes:**
- Cintara node not running or crashed
- Node listening only on 127.0.0.1 instead of 0.0.0.0
- Firewall blocking local connections
- Docker networking issues

### Complete Recovery

```bash
# Clean restart procedure
docker compose down
docker system prune -f
docker compose up -d
sleep 10
./scripts/verify-smart-node.sh
```

### Performance Monitoring

```bash
# System resources
htop
docker stats
df -h

# Service response times
time curl -s http://localhost:8080/health
time curl -s http://localhost:26657/status
```

---

## 📁 Repository Structure

```
cintara-node-llm-bridge/         # https://github.com/Cintaraio/cintara-node-llm-bridge
├── README.md                    # Complete setup and usage guide
├── docker-compose.yml           # LLM + AI Bridge services configuration
├── .env.example                 # Environment variables template
├── bridge/                      # AI Bridge FastAPI application
│   ├── app.py                   # Main AI bridge server with Cintara integration
│   ├── Dockerfile               # Container configuration
│   └── requirements.txt         # Python dependencies
├── scripts/                     # Automated setup and management scripts
│   ├── setup-blockchain-node.sh    # Cintara node setup (uses official script)
│   ├── start-smart-node.sh         # Unified startup for all services
│   ├── verify-smart-node.sh        # Comprehensive 5-phase testing
│   └── test-llm-functionality.sh   # LLM-specific functionality tests
└── models/                      # AI model files directory (.gguf files)
```

---

## 🎯 Benefits of Smart Cintara Node Approach

✅ **Official Cintara Integration** - Uses official Cintara testnet scripts for guaranteed compatibility  
✅ **Simplified AI Services** - Only AI components in Docker, easier to debug and manage  
✅ **Superior Performance** - Cintara node runs natively on host for optimal blockchain performance  
✅ **Independent Updates** - Update Cintara node and AI components separately  
✅ **Clear Architecture** - Blockchain and AI concerns properly separated for maintainability  
✅ **Production Ready** - Enterprise-grade AWS security + proven Cintara node setup  
✅ **AI-Enhanced Monitoring** - Intelligent analysis specifically designed for Cintara blockchain  
✅ **Open Source** - Available at [github.com/Cintaraio/cintara-node-llm-bridge](https://github.com/Cintaraio/cintara-node-llm-bridge)

---

## 🧪 Testing Your Smart Node

### Basic Functionality Test
```bash
./scripts/test-llm-functionality.sh
```

### Comprehensive Verification (5 Phases)
```bash
./scripts/verify-smart-node.sh
```

The verification covers:
1. **Infrastructure** - Docker, models, configuration
2. **Blockchain Node** - RPC, sync status, connectivity  
3. **AI Services** - LLM server, Bridge health
4. **AI Integration** - Smart features, diagnostics
5. **Advanced Features** - Transaction analysis, peer monitoring

### Interactive Testing

Try these AI features once everything is running:

```bash
# Get comprehensive health report
curl -X POST http://localhost:8080/chat \
  -H 'Content-Type: application/json' \
  -d '{"message":"Give me a complete health report of my blockchain node"}' | jq -r .response

# Analyze recent activity
curl -X POST http://localhost:8080/node/diagnose | jq .diagnosis

# Monitor logs in real-time with AI analysis
watch -n 30 'curl -s http://localhost:8080/node/logs | jq -r .log_analysis.summary'
```

---

## 🎉 Success Verification

Your Smart Blockchain Node is fully operational when:

- [ ] Blockchain node responds on port 26657
- [ ] Node is fully synced (catching_up: false)
- [ ] LLM server responds on port 8000
- [ ] AI Bridge responds on port 8080
- [ ] All automated tests pass
- [ ] AI can analyze node logs and provide diagnostics
- [ ] Interactive AI chat responds with node insights

**Final test:**
```bash
curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Give me a complete health report of my Cintara node"}' | jq -r .response
```

If this returns intelligent analysis of your Cintara node, congratulations! Your **Smart Cintara Node with AI Integration** is fully operational and connected to the Cintara testnet.

---

## 📞 Support & Resources

### Official Documentation
- **Cintara Testnet Guide**: [Official Cintara Testnet Script](https://github.com/Cintaraio/cintara-testnet-script) - Primary reference for node setup
- **Cintara Network**: `cintara_11001-1` testnet blockchain
- **Token Information**: Native token `cint`

### Technical Resources
- **Docker Issues**: `docker compose logs -f` for AI services debugging
- **Node Issues**: `journalctl -u cintarachain.service -f` for Cintara node logs
- **AI Model**: [TinyLlama 1.1B GGUF Model](https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0)

### Diagnostic Tools
```bash
# Generate comprehensive diagnostic report
./scripts/verify-smart-node.sh > diagnostic-report.txt

# Monitor Cintara node sync status
watch -n 10 'curl -s http://localhost:26657/status | jq .result.sync_info'

# Check AI integration health
curl -s http://localhost:8080/health | jq .
```

### Important Notes
- **⚠️ Testnet Software**: This is testnet software for the Cintara blockchain - use at your own risk
- **Mnemonic Security**: Always backup your mnemonic phrase securely during node setup
- **Hybrid Architecture**: Official Cintara node setup + containerized AI services for optimal reliability
- **Network**: Connected to Cintara testnet (`cintara_11001-1`)

**This setup provides enterprise-grade blockchain infrastructure with AI-powered monitoring specifically designed for the Cintara ecosystem.**