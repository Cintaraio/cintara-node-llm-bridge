#!/bin/bash

echo "🧪 Testing Smart Blockchain Node LLM Functionality"
echo "================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    echo -e "${BLUE}🔹 Testing: $test_name${NC}"
    
    # Run the command and capture output
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$output" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        echo "   Command: $command"
        echo "   Output: $output"
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo "🚀 Starting LLM Functionality Tests..."
echo ""

# Test 1: LLM Server Health
run_test "LLM Server Health Check" \
    "curl -s http://localhost:8000/health" \
    "status.*ok"

# Test 2: LLM Server Models Endpoint  
run_test "LLM Server Models Endpoint" \
    "curl -s http://localhost:8000/v1/models" \
    "object.*list"

# Test 3: Basic Text Completion
run_test "LLM Text Completion" \
    "curl -s -X POST http://localhost:8000/completion -H 'Content-Type: application/json' -d '{\"prompt\":\"The blockchain is\",\"max_tokens\":20}'" \
    "content"

# Test 4: AI Bridge Health
run_test "AI Bridge Health Check" \
    "curl -s http://localhost:8080/health" \
    "status.*ok"

# Test 5: AI Node Diagnostics
run_test "AI Node Diagnostics" \
    "curl -s -X POST http://localhost:8080/node/diagnose" \
    "diagnosis"

# Test 6: Transaction Analysis
run_test "AI Transaction Analysis" \
    "curl -s -X POST http://localhost:8080/analyze -H 'Content-Type: application/json' -d '{\"transaction\":{\"hash\":\"0x123\",\"amount\":\"100\"}}'" \
    "analysis"

# Test 7: Log Analysis
run_test "AI Log Analysis" \
    "curl -s http://localhost:8080/node/logs" \
    "logs\|analysis"

echo "================================================"
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo "================================================"
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "📈 Total Tests: $TOTAL_TESTS"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All LLM functionality tests passed!${NC}"
    echo ""
    echo "🚀 Your Smart Blockchain Node is fully operational with AI capabilities!"
    echo ""
    echo "🔗 Next steps:"
    echo "- Access AI Bridge API: http://localhost:8080"
    echo "- View API documentation: http://localhost:8080/docs"
    echo "- Monitor with: docker compose logs -f"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above for details.${NC}"
    echo ""
    echo "🔧 Troubleshooting tips:"
    echo "- Ensure all services are running: docker compose ps"
    echo "- Check LLM logs: docker compose logs llama"
    echo "- Check Bridge logs: docker compose logs bridge"
    echo "- Verify model file: ls -la models/"
fi

echo ""
echo "📋 Manual verification commands:"
echo "================================"
echo "# Check service status"
echo "docker compose ps"
echo ""
echo "# Test LLM directly"
echo "curl http://localhost:8000/health"
echo ""
echo "# Test AI Bridge"  
echo "curl http://localhost:8080/health"
echo ""
echo "# Interactive AI chat test"
echo "curl -X POST http://localhost:8080/chat \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"message\":\"What can you tell me about this blockchain node?\"}'"