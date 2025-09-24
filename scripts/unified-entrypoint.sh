#!/bin/bash
set -e

echo "🚀 Starting Cintara Unified Node (ECR Pre-built)"
echo "🏗️  Built at: ${BUILD_TIMESTAMP:-unknown}"
echo "🎯 Target Architecture: ${TARGET_ARCH:-x86_64}"
echo "🔐 Password configurable via CINTARA_NODE_PASSWORD environment variable"
echo ""

# Create necessary directories
mkdir -p /var/log/supervisor /app/logs /data/.tmp-cintarad
chown -R cintara:cintara /var/log/supervisor /app/logs /data /home/cintara /models /app

# Start supervisor
echo "📊 Starting all services with supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf