#!/bin/bash

# Master test runner for dataknobs-md-tools
# Runs all unit tests and reports results

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Track overall results
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} DataKnobs Markdown Tools - Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to run a test suite
run_suite() {
    local suite_name="$1"
    local suite_script="$2"

    SUITES_RUN=$((SUITES_RUN + 1))
    echo -e "${YELLOW}Running: $suite_name${NC}"
    echo ""

    if "$suite_script"; then
        SUITES_PASSED=$((SUITES_PASSED + 1))
        echo ""
        echo -e "${GREEN}✓ $suite_name passed${NC}"
    else
        SUITES_FAILED=$((SUITES_FAILED + 1))
        echo ""
        echo -e "${RED}✗ $suite_name failed${NC}"
    fi
    echo ""
}

# Run Python tests if pytest is available
run_python_tests() {
    echo -e "${YELLOW}Running: Python unit tests${NC}"
    echo ""

    cd "$PROJECT_ROOT"

    if command -v uv >/dev/null 2>&1; then
        SUITES_RUN=$((SUITES_RUN + 1))
        # Ensure dependencies are synced (including dev dependencies for pytest)
        echo "Syncing dependencies with uv..."
        uv sync --quiet --extra dev
        if uv run pytest tests/ -v; then
            SUITES_PASSED=$((SUITES_PASSED + 1))
            echo ""
            echo -e "${GREEN}✓ Python unit tests passed${NC}"
        else
            SUITES_FAILED=$((SUITES_FAILED + 1))
            echo ""
            echo -e "${RED}✗ Python unit tests failed${NC}"
        fi
    elif command -v pytest >/dev/null 2>&1; then
        SUITES_RUN=$((SUITES_RUN + 1))
        if pytest tests/ -v; then
            SUITES_PASSED=$((SUITES_PASSED + 1))
            echo ""
            echo -e "${GREEN}✓ Python unit tests passed${NC}"
        else
            SUITES_FAILED=$((SUITES_FAILED + 1))
            echo ""
            echo -e "${RED}✗ Python unit tests failed${NC}"
        fi
    else
        echo -e "${YELLOW}[SKIP]${NC} uv and pytest not available"
    fi
    echo ""
}

# Run shell script test suites
run_suite "Install Script Tests" "$SCRIPT_DIR/test_install_script.sh"
run_suite "Docker Path Handling Tests" "$SCRIPT_DIR/test_docker_path_handling.sh"
run_suite "dk-md2pdf Wrapper Tests" "$SCRIPT_DIR/test_dk_md2pdf_wrapper.sh"

# Run Python tests
run_python_tests

# Final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} Final Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Test suites run:    $SUITES_RUN"
echo -e "Test suites passed: ${GREEN}$SUITES_PASSED${NC}"
echo -e "Test suites failed: ${RED}$SUITES_FAILED${NC}"
echo ""

if [ $SUITES_FAILED -eq 0 ]; then
    echo -e "${GREEN}All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}Some test suites failed.${NC}"
    exit 1
fi
