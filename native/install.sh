#!/bin/bash

# DataKnobs Markdown Tools - Dependency Installer
# Installs pandoc, mermaid-cli, and weasyprint across different platforms

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
    echo -e "${BLUE}  DataKnobs Markdown Tools - Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi

    echo "$OS"
}

# Install on macOS
install_macos() {
    print_info "Detected macOS"

    # Check for Homebrew
    if ! command_exists brew; then
        print_error "Homebrew not found. Please install from https://brew.sh"
        exit 1
    fi

    # Install pandoc
    if ! command_exists pandoc; then
        print_info "Installing pandoc..."
        brew install pandoc
    else
        print_info "pandoc already installed"
    fi

    # Check for Node.js/npm
    if ! command_exists npm; then
        print_info "Installing Node.js..."
        brew install node
    fi

    # Install mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        npm install -g @mermaid-js/mermaid-cli
    else
        print_info "mermaid-cli already installed"
    fi

    # Check for Python 3
    if ! command_exists python3; then
        print_info "Installing Python 3..."
        brew install python3
    fi

    # Install weasyprint
    if ! command_exists weasyprint; then
        print_info "Installing weasyprint..."
        pip3 install --user weasyprint
    else
        print_info "weasyprint already installed"
    fi
}

# Install on Ubuntu/Debian
install_debian() {
    print_info "Detected Debian/Ubuntu"

    # Update package list
    print_info "Updating package list..."
    sudo apt-get update

    # Install pandoc
    if ! command_exists pandoc; then
        print_info "Installing pandoc..."
        sudo apt-get install -y pandoc
    else
        print_info "pandoc already installed"
    fi

    # Install Node.js and npm
    if ! command_exists npm; then
        print_info "Installing Node.js and npm..."
        sudo apt-get install -y nodejs npm
    fi

    # Install mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        sudo npm install -g @mermaid-js/mermaid-cli
    else
        print_info "mermaid-cli already installed"
    fi

    # Install Python 3 and pip
    if ! command_exists python3; then
        print_info "Installing Python 3..."
        sudo apt-get install -y python3 python3-pip
    fi

    # Install weasyprint dependencies
    print_info "Installing weasyprint dependencies..."
    sudo apt-get install -y python3-pip python3-cffi python3-brotli libpango-1.0-0 libpangoft2-1.0-0

    # Install weasyprint
    if ! command_exists weasyprint; then
        print_info "Installing weasyprint..."
        pip3 install --user weasyprint
    else
        print_info "weasyprint already installed"
    fi
}

# Install on Red Hat/Fedora/CentOS
install_redhat() {
    print_info "Detected Red Hat/Fedora/CentOS"

    # Install pandoc
    if ! command_exists pandoc; then
        print_info "Installing pandoc..."
        sudo dnf install -y pandoc || sudo yum install -y pandoc
    else
        print_info "pandoc already installed"
    fi

    # Install Node.js and npm
    if ! command_exists npm; then
        print_info "Installing Node.js and npm..."
        sudo dnf install -y nodejs npm || sudo yum install -y nodejs npm
    fi

    # Install mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        sudo npm install -g @mermaid-js/mermaid-cli
    else
        print_info "mermaid-cli already installed"
    fi

    # Install Python 3 and pip
    if ! command_exists python3; then
        print_info "Installing Python 3..."
        sudo dnf install -y python3 python3-pip || sudo yum install -y python3 python3-pip
    fi

    # Install weasyprint
    if ! command_exists weasyprint; then
        print_info "Installing weasyprint..."
        pip3 install --user weasyprint
    else
        print_info "weasyprint already installed"
    fi
}

# Install on Arch Linux
install_arch() {
    print_info "Detected Arch Linux"

    # Install pandoc
    if ! command_exists pandoc; then
        print_info "Installing pandoc..."
        sudo pacman -S --noconfirm pandoc
    else
        print_info "pandoc already installed"
    fi

    # Install Node.js and npm
    if ! command_exists npm; then
        print_info "Installing Node.js and npm..."
        sudo pacman -S --noconfirm nodejs npm
    fi

    # Install mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        sudo npm install -g @mermaid-js/mermaid-cli
    else
        print_info "mermaid-cli already installed"
    fi

    # Install Python and pip
    if ! command_exists python3; then
        print_info "Installing Python 3..."
        sudo pacman -S --noconfirm python python-pip
    fi

    # Install weasyprint
    if ! command_exists weasyprint; then
        print_info "Installing weasyprint..."
        pip install --user weasyprint
    else
        print_info "weasyprint already installed"
    fi
}

# Manual installation instructions
manual_install() {
    print_warning "Automatic installation not available for your OS"
    echo ""
    echo "Please install the following dependencies manually:"
    echo ""
    echo "1. Pandoc:"
    echo "   https://pandoc.org/installing.html"
    echo ""
    echo "2. Node.js and npm:"
    echo "   https://nodejs.org/en/download/"
    echo ""
    echo "3. Mermaid CLI:"
    echo "   npm install -g @mermaid-js/mermaid-cli"
    echo ""
    echo "4. Python 3 and pip:"
    echo "   https://www.python.org/downloads/"
    echo ""
    echo "5. WeasyPrint:"
    echo "   pip install weasyprint"
    echo "   https://weasyprint.org/start/"
}

# Verify installation
verify_installation() {
    echo ""
    print_info "Verifying installation..."
    echo ""

    local all_good=true

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

    if command_exists weasyprint; then
        echo -e "${GREEN}✓${NC} weasyprint $(weasyprint --version 2>/dev/null | head -n1 || echo "installed")"
    else
        echo -e "${RED}✗${NC} weasyprint not found"
        all_good=false
    fi

    echo ""
    if [ "$all_good" = true ]; then
        print_info "All dependencies installed successfully!"
        echo ""
        echo "You can now use the converter:"
        echo "  ./native/dk-md2pdf input.md output.pdf"
    else
        print_warning "Some dependencies are missing. Please install them manually."
    fi
}

# Main installation flow
main() {
    print_header

    OS=$(detect_os)

    case "$OS" in
        macos)
            install_macos
            ;;
        ubuntu|debian)
            install_debian
            ;;
        fedora|rhel|centos)
            install_redhat
            ;;
        arch|manjaro)
            install_arch
            ;;
        *)
            manual_install
            ;;
    esac

    verify_installation

    # Add local bin to PATH if needed
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "You may need to add ~/.local/bin to your PATH:"
        echo "  export PATH=\"\$PATH:\$HOME/.local/bin\""
        echo "  Add this to your ~/.bashrc or ~/.zshrc"
    fi
}

# Run main function
main