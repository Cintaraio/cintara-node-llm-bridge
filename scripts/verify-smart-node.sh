#!/bin/bash

echo "🔍 Smart Blockchain Node Verification Workflow"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run verification step
verify_step() {
    local step_name="$1"
    local command="$2"
    local expected_pattern="$3"
    local optional="$4"
    
    echo -e "${BLUE}🔹 Verifying: $step_name${NC}"
    
    # Run the command and capture output
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$output" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $step_name"
        ((TESTS_PASSED++))
        return 0
    else
        if [ "$optional" = "optional" ]; then
            echo -e "${YELLOW}⚠️  OPTIONAL${NC}: $step_name (not critical)"
            echo "   Output: $output"
        else
            echo -e "${RED}❌ FAIL${NC}: $step_name"
            echo "   Command: $command"
            echo "   Output: $output"
            ((TESTS_FAILED++))
        fi
        echo ""
        return 1
    fi
    echo ""
}

echo "🚀 Starting Smart Cintara Node Verification..."
echo ""

# Phase 1: Infrastructure Verification
echo -e "${CYAN}📋 Phase 1: Infrastructure & Prerequisites${NC}"
echo "=============================================="

verify_step "Docker Installation" \
    "docker --version" \
    "Docker version"

verify_step "Docker Compose Installation" \
    "docker compose version" \
    "Docker Compose version"

verify_step "Models Directory Exists" \
    "ls -la models/" \
    "mistral.*gguf"

verify_step "Environment Configuration" \
    "test -f .env && grep -q MODEL_FILE .env" \
    ""

echo ""

# Phase 2: Cintara Node Verification
echo -e "${CYAN}📋 Phase 2: Cintara Blockchain Node${NC}"
echo "=================================="

verify_step "Cintara Node Process Running" \
    "pgrep -x cintarad || curl -s http://localhost:26657/health" \
    "" \
    "optional"

verify_step "Cintara Node RPC Endpoint" \
    "curl -s http://localhost:26657/status" \
    "result.*node_info"

verify_step "Cintara Node Sync Status" \
    "curl -s http://localhost:26657/status | jq -r '.result.sync_info.catching_up'" \
    "false" \
    "optional"

verify_step "Cintara Node Peer Connectivity" \
    "curl -s http://localhost:26657/net_info | jq -r '.result.n_peers'" \
    "[1-9]" \
    "optional"

echo ""

# Phase 3: LLM Services Verification
echo -e "${CYAN}📋 Phase 3: LLM & AI Services${NC}"
echo "============================="

verify_step "Docker Services Running" \
    "docker compose ps --format json | jq -r '.[].State'" \
    "running"

verify_step "LLM Server Health" \
    "curl -s http://localhost:8000/health" \
    ".*"

verify_step "LLM Models Endpoint" \
    "curl -s http://localhost:8000/v1/models" \
    "object.*list"

verify_step "AI Bridge Health" \
    "curl -s http://localhost:8080/health" \
    "status.*ok"

echo ""

# Phase 4: AI Integration Verification
echo -e "${CYAN}📋 Phase 4: AI Integration & Smart Features${NC}"
echo "=========================================="

verify_step "AI Bridge Node Connection" \
    "curl -s http://localhost:8080/node/status" \
    "status.*healthy"

verify_step "LLM Text Completion" \
    "curl -s -X POST http://localhost:8000/completion -H 'Content-Type: application/json' -d '{\"prompt\":\"Hello\",\"max_tokens\":10}'" \
    "content"

verify_step "AI Node Diagnostics" \
    "curl -s -X POST http://localhost:8080/node/diagnose" \
    "diagnosis\\|health_score"

verify_step "AI Transaction Analysis" \
    "curl -s -X POST http://localhost:8080/analyze -H 'Content-Type: application/json' -d '{\"transaction\":{\"hash\":\"0x123\",\"amount\":\"100\"}}'" \
    "analysis\\|risk_level"

verify_step "AI Log Analysis" \
    "curl -s http://localhost:8080/node/logs" \
    "log_analysis\\|timestamp"

verify_step "Interactive AI Chat" \
    "curl -s -X POST http://localhost:8080/chat -H 'Content-Type: application/json' -d '{\"message\":\"What is the status of my node?\"}'" \
    "response\\|message"

verify_step "AI Peer Analysis" \
    "curl -s http://localhost:8080/node/peers" \
    "peer_analysis\\|peer_count"

echo ""

# Phase 5: Advanced Smart Features
echo -e "${CYAN}📋 Phase 5: Advanced Smart Features${NC}"
echo "=================================="

# Get latest block height for transaction analysis
LATEST_BLOCK=$(curl -s http://localhost:26657/status 2>/dev/null | jq -r '.result.sync_info.latest_block_height' 2>/dev/null || echo "1")

verify_step "Block Transaction Analysis" \
    "curl -s http://localhost:8080/node/transactions/$LATEST_BLOCK" \
    "block_height\\|analysis" \
    "optional"

echo ""

# Results Summary
echo "================================================"
echo -e "${BLUE}📊 Verification Results Summary${NC}"
echo "================================================"
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "📈 Total Tests: $TOTAL_TESTS"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Smart Blockchain Node fully verified and operational!${NC}"
    echo ""
    echo "🚀 Your node is ready for:"
    echo "- AI-powered blockchain monitoring"
    echo "- Intelligent transaction analysis"
    echo "- Smart log diagnostics"
    echo "- Interactive AI assistance"
    echo ""
    echo "🔗 Access URLs:"
    echo "- Blockchain Node: http://localhost:26657"
    echo "- LLM Server: http://localhost:8000"
    echo "- AI Bridge: http://localhost:8080"
    
    echo ""
    echo -e "${CYAN}💡 Try these AI features:${NC}"
    echo "================================"
    echo "# Get AI health report"
    echo "curl -X POST http://localhost:8080/chat \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"message\":\"Give me a complete health report of my node\"}'"
    echo ""
    echo "# Analyze recent activity"
    echo "curl -X POST http://localhost:8080/node/diagnose | jq .diagnosis"
    echo ""
    echo "# Monitor in real-time"
    echo "watch -n 30 'curl -s http://localhost:8080/node/logs | jq .log_analysis.summary'"
    
elif [ $TESTS_FAILED -le 3 ]; then
    echo -e "${YELLOW}⚠️  Smart Blockchain Node mostly operational with minor issues${NC}"
    echo ""
    echo "✅ Core functionality working"
    echo "⚠️  Some advanced features may need attention"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Review failed tests above"
    echo "2. Check service logs: docker compose logs -f"
    echo "3. Ensure blockchain node is fully synced"
    echo "4. Re-run verification: ./scripts/verify-smart-node.sh"
else
    echo -e "${RED}❌ Smart Blockchain Node has significant issues${NC}"
    echo ""
    echo "🔧 Troubleshooting checklist:"
    echo "1. Verify all prerequisites are installed"
    echo "2. Check if blockchain node is running and synced"
    echo "3. Ensure Docker services are up: docker compose ps"
    echo "4. Check LLM model file exists: ls -la models/"
    echo "5. Review service logs: docker compose logs"
    echo "6. Restart services: docker compose restart"
fi

echo ""
echo "📋 Manual verification commands:"
echo "================================"
echo "# Check all service status"
echo "docker compose ps"
echo ""
echo "# Test individual components"
echo "curl http://localhost:26657/status | jq .sync_info"
echo "curl http://localhost:8000/health"
echo "curl http://localhost:8080/health"
echo ""
echo "# View service logs"
echo "docker compose logs -f"

exit $TESTS_FAILED