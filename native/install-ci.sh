#!/bin/bash

# DataKnobs Markdown Tools - CI/CD Installer
# Minimal installer for CI/CD environments and Docker containers
# Uses system Python without any prompts or isolation
#
# This script installs:
# - pandoc (markdown processing)
# - mermaid-cli (diagram rendering)
# - weasyprint (HTML to PDF conversion)
# - Liberation/Noto fonts (fixes missing text in mermaid diagrams)
# - GTK dependencies (required by weasyprint)

set -e

# This script is designed for automated environments
export DEBIAN_FRONTEND=noninteractive

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

echo "[INFO] Installing DataKnobs dependencies for CI/CD environment..."
echo "[INFO] Detected OS: $OS"

case "$OS" in
    macos)
        # macOS (for GitHub Actions macOS runners)
        brew install pandoc pango gdk-pixbuf cairo gobject-introspection || true
        # Install fonts for mermaid
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-liberation 2>/dev/null || true
        npm install -g @mermaid-js/mermaid-cli@latest
        pip3 install --user weasyprint
        ;;

    ubuntu|debian)
        # Ubuntu/Debian
        apt-get update
        apt-get install -y pandoc nodejs npm python3-pip python3-cffi python3-brotli \
            libpango-1.0-0 libpangoft2-1.0-0 \
            fonts-liberation fonts-liberation2 fonts-noto fonts-dejavu
        npm install -g @mermaid-js/mermaid-cli@latest
        pip3 install weasyprint
        # Refresh font cache
        fc-cache -f -v >/dev/null 2>&1 || true
        ;;

    fedora|rhel|centos|rocky|almalinux)
        # Red Hat family
        dnf install -y pandoc nodejs npm python3-pip \
            liberation-fonts google-noto-fonts dejavu-fonts-common
        npm install -g @mermaid-js/mermaid-cli@latest
        pip3 install weasyprint
        # Refresh font cache
        fc-cache -f -v >/dev/null 2>&1 || true
        ;;

    alpine)
        # Alpine Linux (common in Docker)
        apk add --no-cache pandoc nodejs npm python3 py3-pip \
            pango cairo gdk-pixbuf \
            ttf-liberation font-noto ttf-dejavu fontconfig
        npm install -g @mermaid-js/mermaid-cli@latest
        pip3 install weasyprint
        # Refresh font cache
        fc-cache -f -v >/dev/null 2>&1 || true
        ;;

    arch|manjaro)
        # Arch Linux
        pacman -S --noconfirm pandoc nodejs npm python python-pip \
            ttf-liberation noto-fonts ttf-dejavu
        npm install -g @mermaid-js/mermaid-cli@latest
        pip install weasyprint
        # Refresh font cache
        fc-cache -f -v >/dev/null 2>&1 || true
        ;;

    *)
        echo "[ERROR] Unsupported OS: $OS"
        echo "Please install manually: pandoc, nodejs, npm, python3, and then:"
        echo "  npm install -g @mermaid-js/mermaid-cli@latest"
        echo "  pip3 install weasyprint"
        exit 1
        ;;
esac

echo "[INFO] Installation complete"

# Quick verification
command -v pandoc >/dev/null && echo "✓ pandoc installed" || echo "✗ pandoc missing"
command -v mmdc >/dev/null && echo "✓ mermaid-cli installed" || echo "✗ mermaid-cli missing"
command -v weasyprint >/dev/null && echo "✓ weasyprint installed" || echo "✗ weasyprint missing"