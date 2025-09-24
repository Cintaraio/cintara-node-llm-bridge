#!/bin/bash
# Setup script for SecretVM directory structure

set -e

echo "🔧 Setting up SecretVM directory structure..."

# Create base directory
sudo mkdir -p /data/secretvm

# Create all required subdirectories
echo "📁 Creating SecretVM data directories..."
sudo mkdir -p /data/secretvm/{cintara,home,models,logs,supervisor,attestation}

# Set appropriate permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER /data/secretvm
sudo chmod -R 755 /data/secretvm

# Create some initial structure
echo "📋 Creating initial configuration structure..."
mkdir -p /data/secretvm/cintara/{config,data}
mkdir -p /data/secretvm/home/.cintarad
mkdir -p /data/secretvm/logs/{cintara,llama,bridge}

# Verify structure
echo "✅ SecretVM directory structure created:"
tree /data/secretvm 2>/dev/null || ls -la /data/secretvm/

echo ""
echo "🚀 SecretVM directories ready! You can now run:"
echo "   docker-compose -f docker-compose.secretvm.yml up -d"
echo ""
echo "📊 Directory usage:"
du -sh /data/secretvm/* 2>/dev/null || echo "Empty directories created"