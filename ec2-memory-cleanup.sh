#!/bin/bash
# EC2 Memory Cleanup Script
# Run this before building Docker images to free up memory

set -e

echo "🧹 EC2 Memory Cleanup Script"
echo "=============================="

# Check current memory usage
echo "📊 Current memory usage:"
free -h
echo ""

# Clean package caches
echo "🗑️  Cleaning package caches..."
sudo yum clean all 2>/dev/null || sudo apt-get clean 2>/dev/null || echo "No package manager cache to clean"

# Clean Docker system (if Docker is installed)
if command -v docker &> /dev/null; then
    echo "🐳 Cleaning Docker system..."

    # Stop all running containers
    sudo docker stop $(sudo docker ps -q) 2>/dev/null || echo "No running containers to stop"

    # Remove all containers
    sudo docker rm $(sudo docker ps -aq) 2>/dev/null || echo "No containers to remove"

    # Remove all images
    sudo docker rmi $(sudo docker images -q) 2>/dev/null || echo "No images to remove"

    # Clean Docker system
    sudo docker system prune -af --volumes 2>/dev/null || echo "Docker system clean completed"

    echo "✅ Docker cleanup completed"
else
    echo "⚠️  Docker not installed, skipping Docker cleanup"
fi

# Clean temporary files
echo "🗂️  Cleaning temporary files..."
sudo rm -rf /tmp/* 2>/dev/null || echo "Temp directory cleaned"
sudo rm -rf /var/tmp/* 2>/dev/null || echo "Var temp directory cleaned"

# Clean logs (keep recent ones)
echo "📝 Cleaning old logs..."
sudo find /var/log -name "*.log" -type f -mtime +7 -delete 2>/dev/null || echo "Log cleanup completed"

# Clear swap if it exists
if [ -f /swapfile ]; then
    echo "💾 Managing swap file..."
    sudo swapoff /swapfile 2>/dev/null || echo "Swap already off"
    sudo rm -f /swapfile 2>/dev/null || echo "Swap file cleaned"
fi

# Create fresh swap (2GB)
echo "💾 Creating 2GB swap file for Docker builds..."
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add swap to fstab for persistence
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
fi

# Clear buffer cache
echo "🔄 Clearing buffer cache..."
sudo sync
sudo sysctl vm.drop_caches=3

# Check final memory status
echo ""
echo "✅ Cleanup completed! Final memory status:"
free -h
echo ""
echo "💾 Swap status:"
sudo swapon --show
echo ""

# Recommendations
echo "💡 Recommendations:"
echo "   - Wait 30 seconds before starting Docker build"
echo "   - Use: docker build --memory=4g --memory-swap=6g (if needed)"
echo "   - Monitor: watch 'free -h' during build"
echo ""
echo "🚀 Ready for Docker build!"