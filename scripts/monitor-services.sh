#!/bin/bash

# Cintara Services Monitor Script
echo "🔍 Monitoring Cintara Services..."
echo "================================="

# Function to test endpoint with timeout
test_endpoint() {
    local url=$1
    local name=$2
    echo -n "Testing $name ($url): "
    
    if timeout 5 curl -sf "$url" >/dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ FAILED"
        return 1
    fi
}

# Function to check docker container
check_container() {
    local container=$1
    echo -n "Container $container: "
    
    if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health")
        echo "✅ Running ($health)"
        return 0
    else
        echo "❌ Not running"
        return 1
    fi
}

echo
echo "📋 Container Status:"
check_container "cintara-llm"
check_container "cintara-ai-bridge" 
check_container "cintara-web-ui"

echo
echo "🌐 Service Endpoints:"
test_endpoint "http://localhost:8000/health" "LLM Server"
test_endpoint "http://localhost:8080/health" "Bridge API"
test_endpoint "http://localhost:3000/health" "Web UI"
test_endpoint "http://localhost:26657/status" "Cintara Node"

echo
echo "🔧 Quick Diagnostics:"
echo "LLM Memory Usage: $(docker stats cintara-llm --no-stream --format 'table {{.MemUsage}}' 2>/dev/null | tail -1 || echo 'N/A')"
echo "Bridge Logs (last 3): "
docker logs cintara-ai-bridge --tail=3 2>/dev/null | sed 's/^/  /'

echo
echo "📊 System Resources:"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"