#!/bin/bash

# DataKnobs Markdown Tools - Diagnostic Script
# Helps diagnose installation issues

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  DataKnobs Markdown Tools - Diagnostic${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_header

# System Information
echo -e "${BLUE}System Information:${NC}"
echo "OS: $OSTYPE"
echo "Shell: $SHELL"
echo "PATH entries with python/npm:"
echo "$PATH" | tr ':' '\n' | grep -E "(python|npm|local)" || echo "  None found"
echo ""

# Check for pyenv
echo -e "${BLUE}Pyenv Status:${NC}"
if command_exists pyenv; then
    echo -e "${GREEN}✓${NC} pyenv installed: $(pyenv --version)"

    # Check for project virtual environment
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$PROJECT_ROOT/.python-version" ]; then
        echo "  Project Python version: $(cat "$PROJECT_ROOT/.python-version")"
    fi

    if [ -d "$PROJECT_ROOT/.venv" ]; then
        echo -e "${GREEN}✓${NC} Virtual environment found at $PROJECT_ROOT/.venv"

        # Check if we can activate it
        if source "$PROJECT_ROOT/.venv/bin/activate" 2>/dev/null; then
            echo "  Virtual environment Python: $(python --version)"
            deactivate 2>/dev/null
        fi
    else
        echo -e "${YELLOW}⚠${NC} No virtual environment found"
        echo "  Run ./native/install.sh to set up isolated environment"
    fi
else
    echo -e "${YELLOW}⚠${NC} pyenv not installed"
    echo "  Consider running ./native/install.sh for better Python management"
fi
echo ""

# Check Python
echo -e "${BLUE}Python Status:${NC}"
if command_exists python3; then
    PYTHON_PATH=$(which python3)
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "${GREEN}✓${NC} Python3 found: $PYTHON_PATH"
    echo "  Version: $PYTHON_VERSION"

    # Check pip
    if python3 -m pip --version >/dev/null 2>&1; then
        PIP_VERSION=$(python3 -m pip --version)
        echo -e "${GREEN}✓${NC} pip: $PIP_VERSION"
    else
        echo -e "${RED}✗${NC} pip not found"
    fi

    # Python user base
    PYTHON_USER_BASE=$(python3 -m site --user-base 2>/dev/null || echo "Unknown")
    echo "  User base: $PYTHON_USER_BASE"

    # Check Python user bin directories
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  Checking Python user bin directories:"
        for py_ver in 3.9 3.10 3.11 3.12 3.13; do
            PYTHON_USER_BIN="$HOME/Library/Python/$py_ver/bin"
            if [ -d "$PYTHON_USER_BIN" ]; then
                echo "    Found: $PYTHON_USER_BIN"
                if [ -f "$PYTHON_USER_BIN/weasyprint" ]; then
                    echo -e "      ${GREEN}✓${NC} weasyprint found in this directory"
                fi
            fi
        done
    fi
else
    echo -e "${RED}✗${NC} Python3 not found"
fi
echo ""

# Check Node.js/npm
echo -e "${BLUE}Node.js/npm Status:${NC}"
if command_exists node; then
    NODE_PATH=$(which node)
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js found: $NODE_PATH"
    echo "  Version: $NODE_VERSION"
else
    echo -e "${RED}✗${NC} Node.js not found"
fi

if command_exists npm; then
    NPM_PATH=$(which npm)
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm found: $NPM_PATH"
    echo "  Version: $NPM_VERSION"
else
    echo -e "${RED}✗${NC} npm not found"
fi
echo ""

# Check required tools
echo -e "${BLUE}Required Tools:${NC}"

# Pandoc
if command_exists pandoc; then
    PANDOC_PATH=$(which pandoc)
    PANDOC_VERSION=$(pandoc --version | head -n1)
    echo -e "${GREEN}✓${NC} pandoc: $PANDOC_PATH"
    echo "  $PANDOC_VERSION"
else
    echo -e "${RED}✗${NC} pandoc not found"
    echo "  Install with: brew install pandoc (macOS) or apt-get install pandoc (Linux)"
fi

# Mermaid CLI
if command_exists mmdc; then
    MMDC_PATH=$(which mmdc)
    MMDC_VERSION=$(mmdc --version 2>/dev/null || echo "Version check failed")
    echo -e "${GREEN}✓${NC} mermaid-cli: $MMDC_PATH"
    echo "  Version: $MMDC_VERSION"
else
    echo -e "${RED}✗${NC} mermaid-cli not found"
    echo "  Install with: npm install -g @mermaid-js/mermaid-cli"
fi

# WeasyPrint
echo -e "\n${BLUE}WeasyPrint Status:${NC}"

# First check if it's in PATH
if command_exists weasyprint; then
    WEASYPRINT_PATH=$(which weasyprint)
    echo -e "${GREEN}✓${NC} weasyprint found in PATH: $WEASYPRINT_PATH"
else
    echo -e "${YELLOW}⚠${NC} weasyprint not found in PATH"

    # Check if it exists in Python user directories
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  Searching in Python user directories..."
        for py_ver in 3.9 3.10 3.11 3.12 3.13; do
            WEASYPRINT_BIN="$HOME/Library/Python/$py_ver/bin/weasyprint"
            if [ -f "$WEASYPRINT_BIN" ]; then
                echo -e "  ${GREEN}✓${NC} Found at: $WEASYPRINT_BIN"
                echo "    To use this version, add to PATH:"
                echo "    export PATH=\"\$PATH:$HOME/Library/Python/$py_ver/bin\""
            fi
        done
    fi
fi

# Test WeasyPrint import
echo ""
echo "Testing WeasyPrint Python import:"
python3 -c "import weasyprint; print(f'  ✓ WeasyPrint {weasyprint.__version__} imported successfully')" 2>&1 || {
    echo -e "  ${RED}✗${NC} Failed to import weasyprint"
    echo ""
    echo "  This usually means:"
    echo "  1. WeasyPrint is not installed for the current Python version"
    echo "  2. GTK libraries are missing (macOS)"
    echo ""
    echo "  To fix:"
    echo "  # Install GTK dependencies (macOS)"
    echo "  brew install pango gdk-pixbuf cairo gobject-introspection"
    echo ""
    echo "  # Reinstall weasyprint"
    echo "  pip3 install --user --force-reinstall weasyprint"
}

echo ""

# GTK Dependencies (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}GTK Dependencies (required for WeasyPrint on macOS):${NC}"

    for lib in pango gdk-pixbuf cairo gobject-introspection; do
        if brew list $lib >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $lib installed"
        else
            echo -e "${RED}✗${NC} $lib not installed"
            echo "  Install with: brew install $lib"
        fi
    done
fi

echo ""

# Summary
echo -e "${BLUE}Summary:${NC}"

ALL_GOOD=true

# Setup PATH for checking
if [[ "$OSTYPE" == "darwin"* ]]; then
    for py_ver in 3.9 3.10 3.11 3.12 3.13; do
        PYTHON_USER_BIN="$HOME/Library/Python/$py_ver/bin"
        if [ -d "$PYTHON_USER_BIN" ] && [[ ":$PATH:" != *":$PYTHON_USER_BIN:"* ]]; then
            export PATH="$PATH:$PYTHON_USER_BIN"
        fi
    done
fi

if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Check all tools
if ! command_exists pandoc; then
    echo -e "${RED}✗${NC} pandoc is missing"
    ALL_GOOD=false
fi

if ! command_exists mmdc; then
    echo -e "${RED}✗${NC} mermaid-cli is missing"
    ALL_GOOD=false
fi

if ! command_exists weasyprint; then
    echo -e "${RED}✗${NC} weasyprint is not accessible"
    ALL_GOOD=false
fi

# Test WeasyPrint import silently
if ! python3 -c "import weasyprint" 2>/dev/null; then
    echo -e "${RED}✗${NC} weasyprint cannot be imported (library issues)"
    ALL_GOOD=false
fi

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✓${NC} All dependencies are properly installed!"
    echo ""
    echo "You should be able to use:"
    echo "  ./bin/dk-md2pdf input.md output.pdf"
else
    echo ""
    echo -e "${YELLOW}Some issues were found. Please fix them and run this diagnostic again.${NC}"
    echo ""
    echo "Quick fix attempt:"
    echo "  ./native/install.sh"
fi