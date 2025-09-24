#!/bin/bash
# Complete EC2 Setup for Cintara ECR Build
# Run this script on a fresh EC2 instance

set -e

echo "🚀 Setting up EC2 for Cintara ECR Build"
echo "======================================="

# System information
echo "📊 System Information:"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
echo "  Architecture: $(uname -m)"
echo "  CPU cores: $(nproc)"
echo "  Memory: $(free -h | grep ^Mem | awk '{print $2}')"
echo "  Disk space: $(df -h / | awk 'NR==2{print $4}')"
echo ""

# Check architecture compatibility
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    echo "❌ Error: Wrong architecture detected: $ARCH"
    echo "   SecretVM requires x86_64. Please use an Intel/AMD EC2 instance."
    exit 1
fi
echo "✅ Architecture compatible: $ARCH"

# Update system
echo "🔄 Updating system packages..."
if command -v yum &> /dev/null; then
    # Amazon Linux
    sudo yum update -y
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y git curl wget unzip
elif command -v apt &> /dev/null; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y build-essential git curl wget unzip
else
    echo "❌ Unsupported OS"
    exit 1
fi

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    if command -v yum &> /dev/null; then
        # Amazon Linux
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -a -G docker $USER
    else
        # Ubuntu
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -a -G docker $USER
        rm get-docker.sh
    fi
    echo "⚠️  Please logout and login again to use docker without sudo"
else
    echo "✅ Docker already installed"
fi

# Install AWS CLI v2
echo "☁️  Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "✅ AWS CLI already installed"
fi

# Setup swap for memory-intensive builds
echo "💾 Setting up swap space..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    # Make permanent
    echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
    echo "✅ Created 4GB swap file"
else
    echo "✅ Swap already configured"
fi

# Optimize Docker for builds
echo "🔧 Optimizing Docker configuration..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF

sudo systemctl restart docker 2>/dev/null || echo "Docker will restart on next login"

# Check disk space
echo "💿 Checking disk space..."
AVAILABLE_GB=$(df / | awk 'NR==2{print int($4/1024/1024)}')
if [ "$AVAILABLE_GB" -lt 25 ]; then
    echo "⚠️  Warning: Only ${AVAILABLE_GB}GB available. Consider using a larger instance."
else
    echo "✅ Sufficient disk space: ${AVAILABLE_GB}GB available"
fi

# Test AWS credentials
echo "🔐 Testing AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS credentials configured"
    aws sts get-caller-identity --query '[Account,Arn]' --output table
else
    echo "❌ AWS credentials not configured"
    echo "   Please run: aws configure"
    echo "   Or ensure IAM role is attached to this EC2 instance"
fi

# Clone repository
echo "📥 Setting up repository..."
REPO_DIR="cintara-node-llm-bridge"
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
    cd "$REPO_DIR"
    git checkout feat/unified-automated-setup
    echo "✅ Repository cloned and checked out"
else
    cd "$REPO_DIR"
    git pull origin feat/unified-automated-setup
    echo "✅ Repository updated"
fi

# Make build script executable
chmod +x build-ec2-to-ecr.sh
chmod +x ec2-memory-cleanup.sh 2>/dev/null || echo "Memory cleanup script not found (optional)"

echo ""
echo "🎉 EC2 Setup Complete!"
echo "======================"
echo ""
echo "📋 Next Steps:"
echo "1. Logout and login again (for Docker group membership)"
echo "2. Configure AWS credentials if needed: aws configure"
echo "3. Run memory cleanup: ./ec2-memory-cleanup.sh"
echo "4. Build and push to ECR: ./build-ec2-to-ecr.sh"
echo ""
echo "💡 System Specs:"
echo "   - Architecture: $(uname -m)"
echo "   - CPUs: $(nproc)"
echo "   - Memory: $(free -h | grep ^Mem | awk '{print $2}')"
echo "   - Swap: $(free -h | grep ^Swap | awk '{print $2}')"
echo "   - Free space: $(df -h / | awk 'NR==2{print $4}')"
echo ""
echo "✅ Ready to build Cintara ECR image!"