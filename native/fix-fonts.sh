#!/bin/bash

# DataKnobs Markdown Tools - Font Fix Script
# Fixes missing text in mermaid diagrams

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  DataKnobs - Mermaid Font Fix${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

print_info "This script fixes missing text in mermaid diagrams"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_info "Detected macOS"

    # Install fonts
    print_info "Installing required fonts..."

    # Check for Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        print_error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install font casks
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-liberation 2>/dev/null || true

    # Also try installing via regular brew
    brew install font-liberation-sans 2>/dev/null || true

    print_success "Fonts installed"

elif command -v apt-get >/dev/null 2>&1; then
    print_info "Detected Debian/Ubuntu"

    print_info "Installing required fonts..."
    sudo apt-get update
    sudo apt-get install -y fonts-liberation fonts-liberation2 fonts-noto fonts-dejavu

    # Refresh font cache
    fc-cache -f -v >/dev/null 2>&1 || true

    print_success "Fonts installed"

elif command -v dnf >/dev/null 2>&1; then
    print_info "Detected Fedora/RHEL"

    print_info "Installing required fonts..."
    sudo dnf install -y liberation-fonts google-noto-fonts dejavu-fonts-common

    # Refresh font cache
    fc-cache -f -v >/dev/null 2>&1 || true

    print_success "Fonts installed"

elif command -v pacman >/dev/null 2>&1; then
    print_info "Detected Arch Linux"

    print_info "Installing required fonts..."
    sudo pacman -S --noconfirm ttf-liberation noto-fonts ttf-dejavu

    # Refresh font cache
    fc-cache -f -v >/dev/null 2>&1 || true

    print_success "Fonts installed"

else
    print_error "Unsupported operating system"
    echo ""
    echo "Please manually install Liberation or Arial fonts for your system"
    exit 1
fi

echo ""

# Test if mermaid-cli can find fonts
print_info "Testing mermaid-cli font rendering..."

# Create a test mermaid diagram
TEST_FILE="/tmp/test-mermaid.md"
cat > "$TEST_FILE" << 'EOF'
```mermaid
graph TD
    A[Test Node] --> B[Font Test]
```
EOF

# Try to render it
if command -v mmdc >/dev/null 2>&1; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    PUPPETEER_ARGS=""

    if [ -f "$PROJECT_ROOT/src/config/puppeteer-config.json" ]; then
        PUPPETEER_ARGS="-p $PROJECT_ROOT/src/config/puppeteer-config.json"
    fi

    if mmdc -i "$TEST_FILE" -o "/tmp/test-mermaid-output.md" $PUPPETEER_ARGS 2>/dev/null; then
        print_success "Mermaid-cli is working properly"
        rm -f "$TEST_FILE" "/tmp/test-mermaid-output.md" "/tmp/test-mermaid-output-*.svg" 2>/dev/null
    else
        print_warning "Mermaid-cli test failed, but fonts are installed"
        echo "Try converting a file to see if the issue is resolved"
    fi
else
    print_warning "mermaid-cli not found, skipping test"
fi

echo ""
print_info "Font fix complete!"
echo ""
echo "Try converting your markdown file again:"
echo "  ./bin/dk-md2pdf examples/mermaid-diagrams.md test.pdf"
echo ""
echo "If text is still missing, try:"
echo "  1. Restart your terminal"
echo "  2. Clear npm cache: npm cache clean --force"
echo "  3. Reinstall mermaid-cli: npm install -g @mermaid-js/mermaid-cli@latest"