#!/bin/bash

# Unit tests for bin/dk-md2pdf wrapper script
# Tests the Docker argument handling and Linux compatibility features

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

# Test: dk-md2pdf has valid bash syntax
test_wrapper_syntax() {
    local test_name="bin/dk-md2pdf has valid bash syntax"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if bash -n "$PROJECT_ROOT/bin/dk-md2pdf" 2>/dev/null; then
        print_pass "$test_name"
    else
        print_fail "$test_name"
    fi
}

# Test: wrapper contains Linux user detection
test_linux_user_detection_present() {
    local test_name="wrapper contains Linux user detection"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'OSTYPE.*linux' "$PROJECT_ROOT/bin/dk-md2pdf" && \
       grep -q 'id -u' "$PROJECT_ROOT/bin/dk-md2pdf" && \
       grep -q 'id -g' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: Linux user/group detection not found"
    fi
}

# Test: wrapper contains --user flag for Docker
test_docker_user_flag() {
    local test_name="wrapper uses --user flag for Docker on Linux"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q '\-\-user' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: --user flag not found"
    fi
}

# Test: wrapper handles file paths for Docker mounting
test_path_handling_logic() {
    local test_name="wrapper has path handling logic"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'MOUNT_DIRS' "$PROJECT_ROOT/bin/dk-md2pdf" && \
       grep -q 'CONVERTED_ARGS' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: path handling variables not found"
    fi
}

# Test: wrapper converts absolute paths for container
test_absolute_path_conversion() {
    local test_name="wrapper converts paths to container format"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q '/mnt' "$PROJECT_ROOT/bin/dk-md2pdf" && \
       grep -q 'CONTAINER_PATH' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: container path conversion not found"
    fi
}

# Test: wrapper mounts additional directories
test_additional_mounts() {
    local test_name="wrapper mounts additional directories"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Check for the loop that adds additional mounts
    if grep -q 'for dir in.*MOUNT_DIRS' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: additional mount loop not found"
    fi
}

# Test: wrapper detects file arguments by extension
test_file_extension_detection() {
    local test_name="wrapper detects files by extension"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q '\.md\|\.pdf\|\.html\|\.htm' "$PROJECT_ROOT/bin/dk-md2pdf" || \
       grep -qE '\.(md|pdf|html|htm)' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: file extension detection not found"
    fi
}

# Test: wrapper preserves non-file arguments
test_non_file_args_preserved() {
    local test_name="wrapper distinguishes file from non-file args"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Check that there's an else branch for non-file arguments
    if grep -q 'CONVERTED_ARGS+=("$arg")' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: non-file argument handling not found"
    fi
}

# Test: wrapper always mounts current directory
test_cwd_mount() {
    local test_name="wrapper always mounts current directory"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q '\-v.*CWD:/workspace' "$PROJECT_ROOT/bin/dk-md2pdf" || \
       grep -q '\-v "\$CWD:/workspace"' "$PROJECT_ROOT/bin/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: CWD mount not found"
    fi
}

# Test: help message displays correctly
test_help_message() {
    local test_name="help message displays"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    # Run with --help and check output
    local help_output
    help_output=$("$PROJECT_ROOT/bin/dk-md2pdf" --help 2>&1 || true)

    if [[ "$help_output" == *"DataKnobs Markdown Tools"* ]] && \
       [[ "$help_output" == *"--format"* ]] && \
       [[ "$help_output" == *"--theme"* ]]; then
        print_pass "$test_name"
    else
        print_fail "$test_name: help message missing expected content"
    fi
}

echo ""
echo "========================================"
echo " dk-md2pdf Wrapper Script Tests"
echo "========================================"
echo ""

test_wrapper_syntax
test_linux_user_detection_present
test_docker_user_flag
test_path_handling_logic
test_absolute_path_conversion
test_additional_mounts
test_file_extension_detection
test_non_file_args_preserved
test_cwd_mount
test_help_message

# Test: native/dk-md2pdf has Docker detection
test_docker_detection() {
    local test_name="native/dk-md2pdf detects Docker environment"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'IN_DOCKER' "$PROJECT_ROOT/native/dk-md2pdf" && \
       grep -q '/.dockerenv' "$PROJECT_ROOT/native/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: Docker detection not found"
    fi
}

# Test: native/dk-md2pdf has run_python helper
test_run_python_helper() {
    local test_name="native/dk-md2pdf has run_python helper"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'run_python()' "$PROJECT_ROOT/native/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: run_python helper not found"
    fi
}

# Test: native/dk-md2pdf uses run_python for weasyprint
test_uses_run_python() {
    local test_name="native/dk-md2pdf uses run_python for Python calls"

    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"

    if grep -q 'run_python -m weasyprint' "$PROJECT_ROOT/native/dk-md2pdf" && \
       grep -q 'run_python -m python.process_html' "$PROJECT_ROOT/native/dk-md2pdf"; then
        print_pass "$test_name"
    else
        print_fail "$test_name: run_python not used for Python calls"
    fi
}

test_docker_detection
test_run_python_helper
test_uses_run_python

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
