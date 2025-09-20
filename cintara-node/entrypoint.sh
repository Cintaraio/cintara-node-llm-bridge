#!/bin/bash

set -e

echo "🚀 Cintara Node Container Entrypoint"
echo "==================================="

# Ensure critical directories exist with proper permissions
echo "🔧 Setting up directory permissions..."
mkdir -p /data
chown cintara:cintara /data
chmod 755 /data

mkdir -p /home/cintara/data
chown -R cintara:cintara /home/cintara/data

echo "✅ Directory permissions set"

# Switch to cintara user and run the initialization script
echo "🔄 Switching to cintara user and running initialization..."
exec su - cintara -c "/home/cintara/init-node.sh"