#!/bin/bash

# DataKnobs Markdown Tools - Smart Installer with Pyenv
# Automatically sets up pyenv and creates an isolated Python environment

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
    echo -e "${BLUE}  DataKnobs Markdown Tools - Smart Installer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prompt for user confirmation
confirm() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" -n 1 -r
    echo

    if [[ "$default" == "y" ]]; then
        [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Install pyenv based on OS
install_pyenv() {
    print_info "Installing pyenv..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command_exists brew; then
            print_info "Installing pyenv via Homebrew..."
            brew install pyenv
        else
            print_error "Homebrew not found. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install pyenv
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        print_info "Installing pyenv for Linux..."

        # Install dependencies first
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev
        elif command_exists dnf; then
            sudo dnf install -y make gcc zlib-devel bzip2 bzip2-devel readline-devel \
                sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel
        elif command_exists pacman; then
            sudo pacman -S --noconfirm base-devel openssl zlib xz tk
        fi

        # Install pyenv via git
        curl https://pyenv.run | bash
    else
        print_error "Unsupported operating system"
        return 1
    fi

    setup_pyenv_shell
}

# Setup shell configuration for pyenv
setup_pyenv_shell() {
    print_info "Configuring shell for pyenv..."

    # Detect shell and config file
    local shell_configs=()

    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_configs+=("$HOME/.zshrc")
    fi

    if [[ "$SHELL" == *"bash"* ]] || [[ -f "$HOME/.bashrc" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            shell_configs+=("$HOME/.bash_profile")
        fi
        shell_configs+=("$HOME/.bashrc")
    fi

    if [[ ${#shell_configs[@]} -eq 0 ]]; then
        shell_configs+=("$HOME/.profile")
    fi

    local pyenv_config='
# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'

    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]] && ! grep -q 'PYENV_ROOT' "$config_file" 2>/dev/null; then
            echo "$pyenv_config" >> "$config_file"
            print_info "Added pyenv configuration to $config_file"
        fi
    done

    # Load pyenv for current session
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
}

# Main installation flow
main() {
    print_header

    local USE_PYENV=false
    local PYTHON_VERSION="3.11.9"
    local PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Step 1: Check Python situation
    echo -e "${CYAN}=== Python Environment Setup ===${NC}"
    echo ""

    if command_exists pyenv; then
        print_info "pyenv is already installed"
        USE_PYENV=true
    else
        echo "Pyenv is not installed. Pyenv provides:"
        echo "  • Isolated Python environment (no system conflicts)"
        echo "  • Consistent Python version across updates"
        echo "  • Easy dependency management"
        echo "  • No sudo required for Python packages"
        echo ""

        if confirm "Would you like to install pyenv for better Python management?"; then
            install_pyenv
            USE_PYENV=true
        else
            print_warning "Proceeding with system Python (may have version conflicts)"
        fi
    fi

    echo ""

    # Step 2: Setup Python environment
    if [[ "$USE_PYENV" == true ]]; then
        echo -e "${CYAN}=== Setting up isolated Python environment ===${NC}"

        # Ensure pyenv is available
        if ! command_exists pyenv; then
            print_warning "pyenv installation may require shell restart"
            export PYENV_ROOT="$HOME/.pyenv"
            [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
            eval "$(pyenv init -)" 2>/dev/null || true
        fi

        # Install Python version if needed
        if command_exists pyenv; then
            if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
                print_info "Installing Python $PYTHON_VERSION..."

                # Install build dependencies for macOS
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    brew install openssl readline sqlite3 xz zlib tcl-tk 2>/dev/null || true
                fi

                pyenv install "$PYTHON_VERSION"
            fi

            # Set local Python version
            cd "$PROJECT_ROOT"
            pyenv local "$PYTHON_VERSION"

            # Create virtual environment
            if [[ ! -d "$PROJECT_ROOT/.venv" ]]; then
                print_info "Creating virtual environment..."
                python -m venv .venv
            fi

            # Activate virtual environment
            source "$PROJECT_ROOT/.venv/bin/activate"

            # Use pip from virtual environment
            PIP_CMD="pip"
            PYTHON_CMD="python"
        else
            print_error "pyenv command not found. You may need to restart your shell."
            print_info "Run this command after restarting: $0"
            exit 1
        fi
    else
        # Use system Python
        PYTHON_CMD="python3"
        PIP_CMD="pip3"

        # Check Python version
        if command_exists python3; then
            CURRENT_PYTHON=$(python3 --version | cut -d' ' -f2)
            print_info "Using system Python: $CURRENT_PYTHON"
        else
            print_error "Python 3 not found. Please install Python 3 first."
            exit 1
        fi
    fi

    echo ""

    # Step 3: Install system dependencies
    echo -e "${CYAN}=== Installing system dependencies ===${NC}"

    # Detect OS and install dependencies
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command_exists brew; then
            print_error "Homebrew not found. Installing..."
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

        # Install GTK dependencies for weasyprint
        print_info "Installing GTK dependencies for weasyprint..."
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
        sudo apt-get install -y pandoc nodejs npm python3-pip python3-cffi python3-brotli \
            libpango-1.0-0 libpangoft2-1.0-0 fonts-liberation fonts-noto

    elif command_exists dnf; then
        # Fedora/RHEL
        print_info "Installing system dependencies..."
        sudo dnf install -y pandoc nodejs npm python3-pip liberation-fonts google-noto-fonts

    elif command_exists pacman; then
        # Arch
        print_info "Installing system dependencies..."
        sudo pacman -S --noconfirm pandoc nodejs npm python python-pip
    fi

    echo ""

    # Step 4: Install Python packages
    echo -e "${CYAN}=== Installing Python packages ===${NC}"

    # Upgrade pip
    print_info "Upgrading pip..."
    $PIP_CMD install --upgrade pip

    # Install weasyprint
    print_info "Installing weasyprint..."
    if [[ "$USE_PYENV" == true ]]; then
        pip install weasyprint
    else
        pip3 install --user weasyprint

        # Add Python user bin to PATH for system Python
        if [[ "$OSTYPE" == "darwin"* ]]; then
            PYTHON_VERSION=$($PYTHON_CMD -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            PYTHON_USER_BIN="$HOME/Library/Python/$PYTHON_VERSION/bin"

            if [[ -d "$PYTHON_USER_BIN" ]] && [[ ":$PATH:" != *":$PYTHON_USER_BIN:"* ]]; then
                export PATH="$PATH:$PYTHON_USER_BIN"
                print_warning "Added $PYTHON_USER_BIN to PATH for this session"
            fi
        fi
    fi

    echo ""

    # Step 5: Install Node packages
    echo -e "${CYAN}=== Installing Node.js packages ===${NC}"

    # Install mermaid-cli
    if ! command_exists mmdc; then
        print_info "Installing mermaid-cli..."
        npm install -g @mermaid-js/mermaid-cli@latest
    else
        print_info "Updating mermaid-cli..."
        npm update -g @mermaid-js/mermaid-cli
    fi

    echo ""

    # Step 6: Create convenience wrapper if using pyenv
    if [[ "$USE_PYENV" == true ]]; then
        # Create a simple convenience wrapper at project root
        cat > "$PROJECT_ROOT/dk-md2pdf" << 'EOF'
#!/bin/bash
# Convenience wrapper for dk-md2pdf
exec "$(dirname "${BASH_SOURCE[0]}")/bin/dk-md2pdf" "$@"
EOF
        chmod +x "$PROJECT_ROOT/dk-md2pdf"
    fi

    echo ""

    # Step 7: Verification
    echo -e "${CYAN}=== Verifying installation ===${NC}"

    local all_good=true

    # Setup PATH for verification
    if [[ "$USE_PYENV" == false ]] && [[ "$OSTYPE" == "darwin"* ]]; then
        for py_ver in 3.9 3.10 3.11 3.12 3.13; do
            PYTHON_USER_BIN="$HOME/Library/Python/$py_ver/bin"
            if [[ -d "$PYTHON_USER_BIN" ]] && [[ ":$PATH:" != *":$PYTHON_USER_BIN:"* ]]; then
                export PATH="$PATH:$PYTHON_USER_BIN"
            fi
        done
    fi

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

    if command_exists weasyprint; then
        echo -e "${GREEN}✓${NC} weasyprint installed"
    else
        echo -e "${RED}✗${NC} weasyprint not found in PATH"
        if [[ "$USE_PYENV" == false ]]; then
            print_warning "You may need to add Python user bin to your PATH"
        fi
        all_good=false
    fi

    # Test Python import
    if $PYTHON_CMD -c "import weasyprint" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} weasyprint module imports correctly"
    else
        echo -e "${RED}✗${NC} weasyprint module import failed"
        all_good=false
    fi

    echo ""

    # Final instructions
    if [[ "$all_good" == true ]]; then
        print_success "All dependencies installed successfully!"
        echo ""

        if [[ "$USE_PYENV" == true ]]; then
            echo -e "${GREEN}Installation complete with isolated environment!${NC}"
            echo ""
            echo "The tools will automatically use the virtual environment."
            echo ""
            echo "To convert files:"
            echo "  ./bin/dk-md2pdf input.md output.pdf"
            echo ""
            echo "Or from anywhere in the project:"
            echo "  ./dk-md2pdf input.md output.pdf"
        else
            echo -e "${GREEN}Installation complete!${NC}"
            echo ""
            echo "To convert files:"
            echo "  ./bin/dk-md2pdf input.md output.pdf"

            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo ""
                print_warning "If weasyprint is not found, add this to your shell config:"
                echo "  export PATH=\"\$PATH:$HOME/Library/Python/\$(python3 -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")')/bin\""
            fi
        fi
    else
        print_warning "Some dependencies are missing or not working correctly."
        echo "Run ./native/diagnose.sh for detailed diagnostics"
    fi
}

# Run main installation
main "$@"