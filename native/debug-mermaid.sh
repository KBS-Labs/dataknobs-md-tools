#!/bin/bash

# DataKnobs - Debug Mermaid Rendering
# Helps diagnose mermaid text rendering issues

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

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  DataKnobs - Mermaid Debug Tool${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Create test file
TEST_DIR="/tmp/mermaid-debug-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

print_info "Working directory: $TEST_DIR"
echo ""

# Create test markdown with problematic diagram types
cat > test.md << 'EOF'
# Mermaid Test

## Flowchart (often missing text)
```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Result One]
    B -->|No| D[Result Two]
```

## Class Diagram (often missing text)
```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
    }
```

## State Diagram (often missing text)
```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

## Sequence Diagram (usually works)
```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>B: Hello Bob
    B->>A: Hi Alice
```
EOF

print_info "Created test markdown file"
echo ""

# Test 1: Basic mermaid-cli
print_info "Test 1: Basic mermaid-cli conversion"
if command -v mmdc >/dev/null 2>&1; then
    mmdc -i test.md -o test-basic.md --theme default 2>&1 | head -20 || true

    # Check if SVGs were created
    if ls *.svg >/dev/null 2>&1; then
        print_info "SVGs created:"
        ls -la *.svg

        # Check first SVG for text elements
        print_info "Checking for text in first SVG:"
        if grep -q '<text' test-basic-1.svg 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Text elements found in SVG"
            echo "Sample text elements:"
            grep '<text' test-basic-1.svg | head -3
        else
            echo -e "${RED}✗${NC} No text elements found in SVG!"
        fi
    else
        print_warning "No SVGs were created"
    fi
else
    print_error "mermaid-cli not found"
fi

echo ""

# Test 2: With puppeteer config
print_info "Test 2: With puppeteer config"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$PROJECT_ROOT/src/config/puppeteer-config.json" ]; then
    rm -f *.svg test-puppet.md 2>/dev/null || true

    mmdc -i test.md -o test-puppet.md \
         -p "$PROJECT_ROOT/src/config/puppeteer-config.json" 2>&1 | head -20 || true

    if ls test-puppet-*.svg >/dev/null 2>&1; then
        print_info "SVGs created with puppeteer config"

        # Check for text
        if grep -q '<text' test-puppet-1.svg 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Text elements found with puppeteer config"
        else
            echo -e "${RED}✗${NC} No text elements with puppeteer config"
        fi
    fi
fi

echo ""

# Test 3: With full config
print_info "Test 3: With mermaid + puppeteer configs"

if [ -f "$PROJECT_ROOT/src/config/mermaid-config.json" ]; then
    rm -f *.svg test-full.md 2>/dev/null || true

    mmdc -i test.md -o test-full.md \
         -c "$PROJECT_ROOT/src/config/mermaid-config.json" \
         -p "$PROJECT_ROOT/src/config/puppeteer-config.json" 2>&1 | head -20 || true

    if ls test-full-*.svg >/dev/null 2>&1; then
        print_info "SVGs created with full config"

        # Check for text and fonts
        if grep -q '<text' test-full-1.svg 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Text elements found"

            # Check for font-family
            if grep -q 'font-family' test-full-1.svg 2>/dev/null; then
                echo "Font families used:"
                grep -o 'font-family="[^"]*"' test-full-1.svg | sort -u | head -5
            fi
        else
            echo -e "${RED}✗${NC} No text elements found"
        fi
    fi
fi

echo ""

# Check system fonts
print_info "System font check:"

# Check for Liberation fonts
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ls /System/Library/Fonts/*.ttf >/dev/null 2>&1; then
        echo "System fonts available"
    fi

    if ls ~/Library/Fonts/*Liberation* >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Liberation fonts found in user fonts"
    else
        echo -e "${YELLOW}⚠${NC} Liberation fonts not found in user fonts"
    fi

    # Check if fonts are accessible to Chrome
    if [ -d "/Applications/Google Chrome.app" ]; then
        print_info "Chrome is installed"
    fi
else
    # Linux font check
    fc-list | grep -i liberation >/dev/null 2>&1 && \
        echo -e "${GREEN}✓${NC} Liberation fonts installed" || \
        echo -e "${RED}✗${NC} Liberation fonts not found"

    fc-list | grep -i arial >/dev/null 2>&1 && \
        echo -e "${GREEN}✓${NC} Arial fonts installed" || \
        echo -e "${YELLOW}⚠${NC} Arial fonts not found"
fi

echo ""

# Check Chrome/Chromium
print_info "Browser check:"
if command -v chromium >/dev/null 2>&1; then
    echo "Chromium: $(chromium --version 2>/dev/null || echo "version unknown")"
elif command -v google-chrome >/dev/null 2>&1; then
    echo "Chrome: $(google-chrome --version 2>/dev/null || echo "version unknown")"
elif [[ "$OSTYPE" == "darwin"* ]] && [ -d "/Applications/Google Chrome.app" ]; then
    echo "Chrome: Found at /Applications/Google Chrome.app"
else
    print_warning "No Chrome/Chromium found"
fi

echo ""
print_info "Debug complete. Check $TEST_DIR for generated files"
echo ""
echo "If text is missing in SVGs:"
echo "1. Try installing Chrome if not present"
echo "2. On macOS, try: brew install --cask google-chrome"
echo "3. Clear npm cache: npm cache clean --force"
echo "4. Reinstall mermaid-cli: npm uninstall -g @mermaid-js/mermaid-cli && npm install -g @mermaid-js/mermaid-cli@latest"