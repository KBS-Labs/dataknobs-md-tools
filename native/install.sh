#!/bin/bash

# DataKnobs Markdown Tools - Simple Installer with uv
# Automatically sets up uv and installs all dependencies

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  DataKnobs Markdown Tools - Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main installation flow
main() {
    print_header

    local PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Step 1: Install uv
    echo -e "${CYAN}=== Installing uv (Python package manager) ===${NC}"
    echo ""

    if command_exists uv; then
        print_success "uv is already installed ($(uv --version))"
    else
        print_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh

        # Add uv to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        if command_exists uv; then
            print_success "uv installed successfully ($(uv --version))"
        else
            print_warning "uv installed but not in PATH. You may need to restart your shell."
            print_info "After restart, re-run: $0"
        fi
    fi

    echo ""

    # Step 2: Install system dependencies
    echo -e "${CYAN}=== Installing system dependencies ===${NC}"
    echo ""

    # Detect OS and install dependencies
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command_exists brew; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Install pandoc
        if ! command_exists pandoc; then
            print_info "Installing pandoc..."
            brew install pandoc
        else
            print_success "pandoc already installed"
        fi

        # Install Node.js
        if ! command_exists npm; then
            print_info "Installing Node.js..."
            brew install node
        else
            print_success "npm already installed"
        fi

        # Install system libraries for weasyprint
        print_info "Installing system libraries for weasyprint..."
        brew install pango gdk-pixbuf cairo gobject-introspection 2>/dev/null || true

        # Install fonts for better mermaid diagram rendering
        print_info "Installing fonts for mermaid diagrams..."
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-liberation 2>/dev/null || true

    elif command_exists apt-get; then
        # Debian/Ubuntu
        print_info "Updating package list..."
        sudo apt-get update

        print_info "Installing system dependencies..."
        sudo apt-get install -y \
            pandoc \
            nodejs \
            npm \
            python3-cffi \
            python3-brotli \
            libpango-1.0-0 \
            libpangoft2-1.0-0 \
            fonts-liberation \
            fonts-noto \
            curl

    elif command_exists dnf; then
        # Fedora/RHEL
        print_info "Installing system dependencies..."
        sudo dnf install -y \
            pandoc \
            nodejs \
            npm \
            liberation-fonts \
            google-noto-fonts \
            curl

    elif command_exists pacman; then
        # Arch
        print_info "Installing system dependencies..."
        sudo pacman -S --noconfirm \
            pandoc \
            nodejs \
            npm \
            curl
    else
        print_warning "Unrecognized package manager. Please install manually:"
        echo "  - pandoc"
        echo "  - Node.js and npm"
        echo "  - System libraries for weasyprint (pango, cairo, etc.)"
    fi

    echo ""

    # Step 3: Install Node packages
    echo -e "${CYAN}=== Installing Node.js packages ===${NC}"
    echo ""

    # Install or update mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        npm install -g @mermaid-js/mermaid-cli@latest
    else
        print_info "Updating mermaid-cli..."
        npm update -g @mermaid-js/mermaid-cli || true
    fi

    echo ""

    # Step 4: Install Python dependencies with uv
    echo -e "${CYAN}=== Installing Python dependencies ===${NC}"
    echo ""

    cd "$PROJECT_ROOT"

    if command_exists uv; then
        print_info "Installing Python $(cat .python-version) and dependencies..."
        print_info "Running: uv sync"
        uv sync
        print_success "Python dependencies installed"
    else
        print_error "uv not found. Please restart your shell and re-run: $0"
        exit 1
    fi

    echo ""

    # Step 5: Verification
    echo -e "${CYAN}=== Verifying installation ===${NC}"
    echo ""

    local all_good=true

    # Check tools
    if command_exists pandoc; then
        echo -e "${GREEN}✓${NC} pandoc $(pandoc --version | head -n1)"
    else
        echo -e "${RED}✗${NC} pandoc not found"
        all_good=false
    fi

    if command_exists mmdc; then
        echo -e "${GREEN}✓${NC} mermaid-cli $(mmdc --version 2>/dev/null || echo "installed")"
    else
        echo -e "${RED}✗${NC} mermaid-cli not found"
        all_good=false
    fi

    if command_exists uv; then
        echo -e "${GREEN}✓${NC} uv $(uv --version)"
    else
        echo -e "${RED}✗${NC} uv not found"
        all_good=false
    fi

    # Test Python and weasyprint via uv
    if cd "$PROJECT_ROOT" && uv run python3 -c "import weasyprint; print('weasyprint', weasyprint.__version__)" 2>/dev/null; then
        local wp_version=$(uv run python3 -c "import weasyprint; print(weasyprint.__version__)" 2>/dev/null)
        echo -e "${GREEN}✓${NC} weasyprint $wp_version"
    else
        echo -e "${RED}✗${NC} weasyprint module import failed"
        all_good=false
    fi

    echo ""

    # Final instructions
    if [[ "$all_good" == true ]]; then
        print_success "All dependencies installed successfully!"
        echo ""
        echo -e "${GREEN}Installation complete!${NC}"
        echo ""
        echo "To convert files:"
        echo "  ./native/dk-md2pdf input.md output.pdf"
        echo ""
        echo "Or add to your PATH:"
        echo "  export PATH=\"$PROJECT_ROOT/native:\$PATH\""
        echo ""
        echo "Then use from anywhere:"
        echo "  dk-md2pdf input.md output.pdf"
    else
        print_warning "Some dependencies are missing or not working correctly."
        echo ""
        echo "Common fixes:"
        echo "  - Restart your shell if uv was just installed"
        echo "  - Check that Node.js and npm are in your PATH"
        echo "  - On Linux, ensure system libraries are installed"
    fi
}

# Run main installation
main "$@"