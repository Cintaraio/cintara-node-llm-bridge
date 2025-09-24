#!/bin/bash
echo "🔍 Checking service health..."

# Check each service
services_healthy=0

if timeout 10 curl -sf http://localhost:26657/status > /dev/null 2>&1; then
    echo "✅ Cintara node: healthy"
    services_healthy=$((services_healthy + 1))
else
    echo "⚠️ Cintara node: placeholder mode"
fi

if timeout 10 curl -sf http://localhost:8000 > /dev/null 2>&1; then
    echo "✅ LLM server: healthy"
    services_healthy=$((services_healthy + 1))
else
    echo "❌ LLM server: unhealthy"
fi

if timeout 10 curl -sf http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ AI bridge: healthy"
    services_healthy=$((services_healthy + 1))
else
    echo "❌ AI bridge: unhealthy"
fi

if [ $services_healthy -ge 2 ]; then
    echo "✅ Sufficient services running ($services_healthy/3)"
    exit 0
else
    echo "❌ Insufficient services running ($services_healthy/3)"
    exit 1
fi