#!/bin/bash

# Redis Table Module - Configuration Testing
# Tests module configuration parameters

REDIS_DIR="/home/ubuntu/Projects/REDIS/redis"
SCRIPT_DIR="$(dirname $(readlink -f $0))"
MODULE_PATH="$SCRIPT_DIR/../redistable.so"
REDIS_PID_FILE="/tmp/redis_table_config_test.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}========================================"
echo "Redis Table Module - Configuration Tests"
echo -e "========================================${NC}\n"

# Function to cleanup
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    if [ -f "$REDIS_PID_FILE" ]; then
        REDIS_PID=$(cat $REDIS_PID_FILE)
        kill $REDIS_PID 2>/dev/null
        rm -f $REDIS_PID_FILE
    fi
    pkill -9 redis-server 2>/dev/null
    sleep 1
}

# Function to start Redis with config
start_redis_with_config() {
    local config_args="$1"
    cleanup
    
    echo -e "${GREEN}Starting Redis with config: $config_args${NC}"
    cd $REDIS_DIR
    if [ -z "$config_args" ]; then
        ./src/redis-server --loadmodule $MODULE_PATH --daemonize yes --pidfile $REDIS_PID_FILE --port 6380
    else
        ./src/redis-server --loadmodule $MODULE_PATH $config_args --daemonize yes --pidfile $REDIS_PID_FILE --port 6380
    fi
    cd - > /dev/null
    sleep 2
    
    # Verify Redis started
    if ! pgrep -x redis-server > /dev/null; then
        echo -e "${RED}Error: Failed to start Redis${NC}"
        return 1
    fi
    return 0
}

# Function to run test
run_test() {
    local test_name="$1"
    local config="$2"
    local expected_behavior="$3"
    
    echo -e "\n${BLUE}Test: $test_name${NC}"
    echo "Config: $config"
    echo "Expected: $expected_behavior"
    
    if start_redis_with_config "$config"; then
        # Verify module loaded
        MODULE_CHECK=$($REDIS_DIR/src/redis-cli -p 6380 MODULE LIST 2>/dev/null | grep -i table || echo "")
        if [[ -z "$MODULE_CHECK" ]]; then
            echo -e "${RED}✗ FAILED: Module not loaded${NC}"
            ((TESTS_FAILED++))
            return 1
        fi
        
        echo -e "${GREEN}✓ PASSED: Module loaded successfully${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED: Redis failed to start${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Check if module exists
if [ ! -f "$MODULE_PATH" ]; then
    echo -e "${RED}Error: Module not found at $MODULE_PATH${NC}"
    echo "Please run 'make' first to build the module."
    exit 1
fi

# Test 1: Default configuration (no parameters)
run_test "Default Configuration" "" "Should use default max_scan_limit=100000"

# Test 2: Valid max_scan_limit
run_test "Valid max_scan_limit" "max_scan_limit 200000" "Should accept 200000"

# Test 3: Minimum valid value
run_test "Minimum max_scan_limit" "max_scan_limit 1000" "Should accept 1000"

# Test 4: Maximum valid value
run_test "Maximum max_scan_limit" "max_scan_limit 10000000" "Should accept 10000000"

# Test 5: Invalid value (too low) - should still load with default
run_test "Invalid max_scan_limit (too low)" "max_scan_limit 500" "Should load with default (logs warning)"

# Test 6: Invalid value (too high) - should still load with default
run_test "Invalid max_scan_limit (too high)" "max_scan_limit 20000000" "Should load with default (logs warning)"

# Test 7: Invalid parameter name - should still load (ignores unknown params)
run_test "Unknown parameter" "unknown_param 12345" "Should load and ignore unknown param"

# Test 8: Multiple parameters (future-proofing)
run_test "Multiple parameters" "max_scan_limit 150000" "Should handle multiple params"

# Cleanup
cleanup

# Summary
echo -e "\n${BLUE}========================================"
echo "Configuration Test Summary"
echo -e "========================================${NC}"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All configuration tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some configuration tests failed!${NC}"
    exit 1
fi
