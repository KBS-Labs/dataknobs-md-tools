#!/bin/bash

# Docker entrypoint for DataKnobs Markdown Tools
# Handles file permissions and executes the converter

set -e

# Function to handle file permissions
fix_permissions() {
    # Get the UID/GID from the mounted volume
    if [ -f "$1" ]; then
        USER_UID=$(stat -c '%u' "$1" 2>/dev/null || echo 1000)
        USER_GID=$(stat -c '%g' "$1" 2>/dev/null || echo 1000)
    else
        USER_UID=${USER_UID:-1000}
        USER_GID=${USER_GID:-1000}
    fi
}

# Check if running interactively or with arguments
if [ $# -eq 0 ]; then
    echo "DataKnobs Markdown Tools - Docker Container"
    echo ""
    echo "Usage:"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools input.md [output]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show help"
    echo "  -f, --format        Output format: pdf (default) or html"
    echo "  -t, --theme         CSS theme: github (default), academic, minimal, business"
    echo "  --toc               Include table of contents"
    echo "  --list-fonts        List available fonts"
    echo "  --font-body FONT    Font for body text"
    echo "  --font-code FONT    Font for code blocks"
    echo "  --font-size SIZE    Base font size in pixels"
    echo ""
    echo "Examples:"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools input.md"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools -f html input.md output.html"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools --toc -t academic paper.md"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools --list-fonts"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools --font-body \"Roboto\" input.md"
    echo ""
    echo "Font Management:"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools dk-fonts list"
    echo "  docker run -v \$(pwd):/workspace dataknobs/md-tools dk-fonts info"
    exit 0
fi

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    exec /app/dk-md2pdf --help
fi

# Set the PROJECT_ROOT for the converter script
export PROJECT_ROOT=/app

# Set Puppeteer environment variables for Docker
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Change to workspace
cd /workspace

# Execute the converter with all arguments
exec /app/dk-md2pdf "$@"