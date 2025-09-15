#!/bin/bash
# DataKnobs Environment Activation Script

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if virtual environment exists
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    echo "Virtual environment not found. Please run: ./native/install-with-pyenv.sh"
    return 1 2>/dev/null || exit 1
fi

# Activate virtual environment
source "$PROJECT_ROOT/.venv/bin/activate"

# Add project bin to PATH
export PATH="$PROJECT_ROOT/bin:$PATH"

echo "DataKnobs environment activated!"
echo "Python: $(which python) ($(python --version))"
echo "You can now use: dk-md2pdf input.md output.pdf"
