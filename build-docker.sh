#!/bin/bash
# Build script for dataknobs/md-tools Docker image

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building dataknobs/md-tools Docker image...${NC}"
echo ""

# Build the Docker image
cd "$SCRIPT_DIR"
docker build -t dataknobs/md-tools -f docker/Dockerfile .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Docker image built successfully!${NC}"
    echo ""
    echo "Image: dataknobs/md-tools:latest"
    echo ""
    echo "To test: dk-md2pdf input.md output.pdf"
else
    echo ""
    echo -e "${YELLOW}✗ Build failed${NC}"
    exit 1
fi
