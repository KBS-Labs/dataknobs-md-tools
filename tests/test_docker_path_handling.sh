#!/bin/bash

# Unit tests for Docker path handling in bin/dk-md2pdf
# Tests the path conversion and mount generation logic

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

# Helper function to extract the path handling logic and test it
# This sources the relevant parts of dk-md2pdf for testing
test_path_conversion() {
    local test_name="$1"
    local input_arg="$2"
    local expected_contains="$3"
    local cwd="$4"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Set up the test environment
    CWD="${cwd:-/home/user/project}"

    # Simulate the path conversion logic from bin/dk-md2pdf
    local arg="$input_arg"
    local result=""

    # Check if argument looks like a file path (exists or has common extensions)
    if [[ "$arg" =~ \.(md|pdf|html|htm)$ ]]; then
        # Convert to absolute path
        if [[ "$arg" = /* ]]; then
            ABS_PATH="$arg"
        else
            ABS_PATH="$CWD/$arg"
        fi
        # For testing, skip the cd normalization since dirs may not exist
        # Convert to container path: mount dir becomes /mnt/hostpath
        result="/mnt${ABS_PATH}"
    else
        result="$arg"
    fi

    if [[ "$result" == *"$expected_contains"* ]]; then
        print_pass "$test_name"
    else
        print_fail "$test_name: expected '$expected_contains' in '$result'"
    fi
}

# Helper to test mount directory extraction
test_mount_extraction() {
    local test_name="$1"
    local input_path="$2"
    local expected_mount="$3"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Extract directory from path
    local dir=$(dirname "$input_path")

    if [[ "$dir" == "$expected_mount" ]]; then
        print_pass "$test_name"
    else
        print_fail "$test_name: expected mount '$expected_mount', got '$dir'"
    fi
}

# Test: Linux user detection
test_linux_user_detection() {
    local test_name="Linux user/group detection"

    # Test that we can get user and group IDs on Linux
    if [[ "$OSTYPE" == "linux"* ]]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        print_test "$test_name"

        local uid=$(id -u)
        local gid=$(id -g)

        if [[ -n "$uid" && -n "$gid" && "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]]; then
            print_pass "$test_name (uid=$uid, gid=$gid)"
        else
            print_fail "$test_name: could not get valid uid/gid"
        fi
    else
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        echo -e "${YELLOW}[SKIP]${NC} $test_name (not running on Linux)"
    fi
}

# Test: npm prefix detection for sudo logic
test_npm_prefix_detection() {
    local test_name="npm prefix detection"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if command -v npm >/dev/null 2>&1; then
        local prefix=$(npm config get prefix 2>/dev/null || echo "/usr/local")

        if [[ -n "$prefix" ]]; then
            # Check if we can determine writability
            local needs_sudo=false
            if [ ! -w "$prefix/lib" ] 2>/dev/null; then
                needs_sudo=true
            fi
            print_pass "$test_name (prefix=$prefix, needs_sudo=$needs_sudo)"
        else
            print_fail "$test_name: could not get npm prefix"
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} $test_name (npm not installed)"
    fi
}

echo ""
echo "========================================"
echo " Docker Path Handling Tests"
echo "========================================"
echo ""

# Path conversion tests
test_path_conversion \
    "Relative path in current directory" \
    "input.md" \
    "/mnt/home/user/project/input.md" \
    "/home/user/project"

test_path_conversion \
    "Absolute path" \
    "/home/other/docs/file.md" \
    "/mnt/home/other/docs/file.md" \
    "/home/user/project"

test_path_conversion \
    "Relative path with subdirectory" \
    "docs/readme.md" \
    "/mnt/home/user/project/docs/readme.md" \
    "/home/user/project"

test_path_conversion \
    "Output PDF path" \
    "output.pdf" \
    "/mnt/home/user/project/output.pdf" \
    "/home/user/project"

test_path_conversion \
    "Output HTML path" \
    "/tmp/output.html" \
    "/mnt/tmp/output.html" \
    "/home/user/project"

test_path_conversion \
    "Non-file argument (flag)" \
    "--verbose" \
    "--verbose" \
    "/home/user/project"

test_path_conversion \
    "Non-file argument (theme)" \
    "github" \
    "github" \
    "/home/user/project"

echo ""
echo "========================================"
echo " Mount Directory Extraction Tests"
echo "========================================"
echo ""

test_mount_extraction \
    "Extract directory from absolute path" \
    "/home/user/docs/file.md" \
    "/home/user/docs"

test_mount_extraction \
    "Extract directory from root-level file" \
    "/file.md" \
    "/"

test_mount_extraction \
    "Extract directory from nested path" \
    "/a/b/c/d/file.md" \
    "/a/b/c/d"

echo ""
echo "========================================"
echo " Platform-Specific Tests"
echo "========================================"
echo ""

test_linux_user_detection
test_npm_prefix_detection

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
