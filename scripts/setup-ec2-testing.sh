#!/bin/bash

set -e

echo "🚀 Setting up EC2 instance for Cintara SecretVM testing"
echo "======================================================"

# Check if running on EC2
if ! curl -s http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    echo "⚠️  Warning: This script is designed for EC2 instances"
    echo "   It may not work correctly on other systems"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo "❌ Cannot detect operating system"
    exit 1
fi

echo "✅ Detected OS: $OS"

# Install Docker based on OS
if [[ "$OS" == *"Amazon Linux"* ]]; then
    echo "📦 Installing Docker on Amazon Linux..."
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    chkconfig docker on

elif [[ "$OS" == *"Ubuntu"* ]]; then
    echo "📦 Installing Docker on Ubuntu..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker

else
    echo "❌ Unsupported OS: $OS"
    echo "   This script supports Amazon Linux and Ubuntu only"
    exit 1
fi

# Add ec2-user to docker group
if id "ec2-user" &>/dev/null; then
    usermod -a -G docker ec2-user
    echo "✅ Added ec2-user to docker group"
elif id "ubuntu" &>/dev/null; then
    usermod -a -G docker ubuntu
    echo "✅ Added ubuntu to docker group"
else
    echo "⚠️  No standard user found (ec2-user or ubuntu)"
fi

# Install Docker Compose
echo "📦 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.24.1"
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
echo "📦 Installing Git..."
if [[ "$OS" == *"Amazon Linux"* ]]; then
    yum install -y git
elif [[ "$OS" == *"Ubuntu"* ]]; then
    apt-get install -y git
fi

# Install additional tools
echo "📦 Installing additional tools..."
if [[ "$OS" == *"Amazon Linux"* ]]; then
    yum install -y htop curl wget jq
elif [[ "$OS" == *"Ubuntu"* ]]; then
    apt-get install -y htop curl wget jq
fi

# Create working directory
USER_HOME="/home/ec2-user"
if id "ubuntu" &>/dev/null; then
    USER_HOME="/home/ubuntu"
fi

mkdir -p ${USER_HOME}/cintara-test
if id "ec2-user" &>/dev/null; then
    chown ec2-user:ec2-user ${USER_HOME}/cintara-test
elif id "ubuntu" &>/dev/null; then
    chown ubuntu:ubuntu ${USER_HOME}/cintara-test
fi

echo "📁 Created working directory: ${USER_HOME}/cintara-test"

# Clone repository as the user
echo "📥 Cloning Cintara repository..."
if id "ec2-user" &>/dev/null; then
    sudo -u ec2-user bash << EOF
cd ${USER_HOME}/cintara-test
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/unified-automated-setup

# Create data directories
mkdir -p ${USER_HOME}/data/secretvm/{cintara,home,models,logs,supervisor,attestation}
chmod -R 755 ${USER_HOME}/data
EOF
elif id "ubuntu" &>/dev/null; then
    sudo -u ubuntu bash << EOF
cd ${USER_HOME}/cintara-test
git clone https://github.com/Cintaraio/cintara-node-llm-bridge.git
cd cintara-node-llm-bridge
git checkout feat/unified-automated-setup

# Create data directories
mkdir -p ${USER_HOME}/data/secretvm/{cintara,home,models,logs,supervisor,attestation}
chmod -R 755 ${USER_HOME}/data
EOF
fi

# Create systemd service for auto-start (optional)
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/cintara-secretvm.service << EOF
[Unit]
Description=Cintara SecretVM Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${USER_HOME}/cintara-test/cintara-node-llm-bridge
ExecStart=/usr/local/bin/docker-compose -f docker-compose.secretvm.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.secretvm.yml down
$(id "ec2-user" &>/dev/null && echo "User=ec2-user" || echo "User=ubuntu")

[Install]
WantedBy=multi-user.target
EOF

# Create testing script
echo "📝 Creating testing script..."
cat > ${USER_HOME}/test-cintara.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Cintara SecretVM Setup"
echo "================================="

cd ~/cintara-test/cintara-node-llm-bridge

echo "📊 Starting services..."
docker-compose -f docker-compose.secretvm.yml up -d

echo "⏳ Waiting for services to initialize (this may take 5-10 minutes)..."
sleep 300

echo "🔍 Testing service endpoints..."

# Test Cintara node
echo -n "Cintara node (26657): "
if curl -sf http://localhost:26657/status >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test LLM server
echo -n "LLM server (8000): "
if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test AI bridge
echo -n "AI bridge (8080): "
if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test attestation endpoint
echo -n "Attestation (9999): "
if curl -sf http://localhost:9999/attestation >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "⚠️  Not available (expected in non-TEE environment)"
fi

echo ""
echo "📋 Service Status:"
docker-compose -f docker-compose.secretvm.yml ps

echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "🎉 Testing complete!"
echo "To view logs: docker-compose -f docker-compose.secretvm.yml logs -f"
echo "To stop: docker-compose -f docker-compose.secretvm.yml down"
EOF

if id "ec2-user" &>/dev/null; then
    chown ec2-user:ec2-user ${USER_HOME}/test-cintara.sh
elif id "ubuntu" &>/dev/null; then
    chown ubuntu:ubuntu ${USER_HOME}/test-cintara.sh
fi
chmod +x ${USER_HOME}/test-cintara.sh

# Update Docker daemon configuration for better performance
echo "⚙️  Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker with new configuration
systemctl restart docker

# Enable systemd service (optional)
systemctl daemon-reload
# systemctl enable cintara-secretvm.service

echo ""
echo "✅ EC2 setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Logout and login again (to apply docker group membership)"
echo "2. Run the test script: ~/test-cintara.sh"
echo "3. Or manually start: cd ~/cintara-test/cintara-node-llm-bridge && docker-compose -f docker-compose.secretvm.yml up -d"
echo ""
echo "🔗 Service endpoints (after startup):"
echo "   - Cintara node: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):26657/status"
echo "   - AI bridge: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/health"
echo "   - LLM server: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/health"
echo ""
echo "⚠️  Make sure your security group allows inbound traffic on ports 26656, 26657, 1317, 8000, 8080, 9090, 9999"
echo ""
echo "🎉 Happy testing!"