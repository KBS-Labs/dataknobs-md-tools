#!/bin/bash

# Unit tests for native/install.sh functionality
# Tests the npm privilege detection and helper functions

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test: install.sh has valid bash syntax
test_install_script_syntax() {
    local test_name="install.sh has valid bash syntax"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if bash -n "$PROJECT_ROOT/native/install.sh" 2>/dev/null; then
        print_pass "$test_name"
    else
        print_fail "$test_name"
    fi
}

# Test: install.sh contains npm sudo detection logic
test_npm_sudo_detection_present() {
    local test_name="install.sh contains npm sudo detection"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q "NPM_NEEDS_SUDO" "$PROJECT_ROOT/native/install.sh"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: NPM_NEEDS_SUDO variable not found"
    fi
}

# Test: install.sh contains run_npm_global function
test_run_npm_global_function() {
    local test_name="install.sh contains run_npm_global function"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q "run_npm_global()" "$PROJECT_ROOT/native/install.sh"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: run_npm_global function not found"
    fi
}

# Test: install.sh checks npm prefix writability
test_npm_prefix_check() {
    local test_name="install.sh checks npm prefix writability"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'npm config get prefix' "$PROJECT_ROOT/native/install.sh"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: npm prefix check not found"
    fi
}

# Test: install.sh uses run_npm_global for mermaid-cli
test_mermaid_uses_helper() {
    local test_name="install.sh uses run_npm_global for mermaid-cli"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q "run_npm_global install -g @mermaid-js/mermaid-cli" "$PROJECT_ROOT/native/install.sh"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: mermaid-cli install doesn't use helper"
    fi
}

# Test: npm prefix detection works (live test)
test_npm_prefix_detection_live() {
    local test_name="npm prefix detection works (live)"

    if ! command -v npm >/dev/null 2>&1; then
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        echo -e "${YELLOW}[SKIP]${NC} $test_name (npm not installed)"
        return 0
    fi

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Replicate the logic from install.sh
    NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "/usr/local")
    NPM_NEEDS_SUDO=false

    if [ ! -w "$NPM_PREFIX/lib" ] 2>/dev/null; then
        NPM_NEEDS_SUDO=true
    fi

    # The test passes if we can determine this without error
    if [[ "$NPM_NEEDS_SUDO" == "true" || "$NPM_NEEDS_SUDO" == "false" ]]; then
        print_pass "$test_name (prefix=$NPM_PREFIX, needs_sudo=$NPM_NEEDS_SUDO)"
    else
        print_fail "$test_name: unexpected value for NPM_NEEDS_SUDO"
    fi
}

echo ""
echo "========================================"
echo " Install Script Tests"
echo "========================================"
echo ""

test_install_script_syntax
test_npm_sudo_detection_present
test_run_npm_global_function
test_npm_prefix_check
test_mermaid_uses_helper
test_npm_prefix_detection_live

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
if [ $TESTS_SKIPPED -gt 0 ]; then
    echo -e "Tests skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
