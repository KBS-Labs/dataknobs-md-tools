# Font Management Guide

Complete guide to managing and customizing fonts in DataKnobs MD Tools.

## Table of Contents

- [Quick Start](#quick-start)
- [Listing Available Fonts](#listing-available-fonts)
- [Using Custom Fonts](#using-custom-fonts)
- [Installing Additional Fonts](#installing-additional-fonts)
  - [Native Mode](#native-mode)
  - [Docker Mode](#docker-mode)
- [Default Fonts](#default-fonts)
- [Troubleshooting](#troubleshooting)

## Quick Start

### List all available fonts:
```bash
dk-fonts list

# Or via dk-md2pdf:
dk-md2pdf --list-fonts
```

### Use custom fonts in your PDF:
```bash
dk-md2pdf --font-body "Georgia" --font-code "Monaco" input.md output.pdf
```

### Change font sizes:
```bash
dk-md2pdf --font-size 14 --font-size-print 11pt input.md output.pdf
```

## Listing Available Fonts

The `dk-fonts` command provides a unified interface for font management that works in both native and Docker modes.

### Basic Listing

```bash
# List all fonts
dk-fonts list

# List fonts by category
dk-fonts list --category serif
dk-fonts list --category sans-serif
dk-fonts list --category monospace

# Search for specific fonts
dk-fonts search "Arial"
dk-fonts search "Liberation"

# Show detailed information (family, style, file path)
dk-fonts list --detailed

# Limit results
dk-fonts list --limit 20
```

### Available Categories

- `serif` - Traditional fonts with serifs (Times, Georgia, etc.)
- `sans-serif` - Modern fonts without serifs (Arial, Helvetica, etc.)
- `monospace` - Fixed-width fonts for code (Courier, Monaco, etc.)
- `cursive` - Handwriting-style fonts
- `fantasy` - Decorative fonts

### Validating Fonts

Check if a specific font is available:

```bash
dk-fonts validate "Arial"
dk-fonts validate "Georgia"

# Get suggestions if font not found
dk-fonts validate "Ariel"  # Will suggest "Arial"
```

### Font System Information

View your font system configuration:

```bash
dk-fonts info
```

This shows:
- Current environment (native or Docker)
- Operating system
- Total number of fonts available
- Font directories
- Status of recommended fonts

## Using Custom Fonts

### Command-Line Options

dk-md2pdf supports the following font customization options:

| Option | Description | Example |
|--------|-------------|---------|
| `--font-body FONT` | Set body text font | `--font-body "Georgia"` |
| `--font-code FONT` | Set code block font | `--font-code "Monaco"` |
| `--font-size SIZE` | Base font size (pixels) | `--font-size 14` |
| `--font-size-print SIZE` | Print font size (points) | `--font-size-print 11pt` |

### Examples

**Use Georgia for body text and Monaco for code:**
```bash
dk-md2pdf --font-body "Georgia" --font-code "Monaco" input.md output.pdf
```

**Create a larger document:**
```bash
dk-md2pdf --font-size 18 input.md output.pdf
```

**Use a combination of options:**
```bash
dk-md2pdf \
  --font-body "Liberation Serif" \
  --font-code "Liberation Mono" \
  --font-size 14 \
  --font-size-print 11pt \
  --theme academic \
  input.md output.pdf
```

**Use with verbose mode to see applied fonts:**
```bash
dk-md2pdf -v --font-body "Georgia" input.md output.pdf
```

### Font Name Format

- Use quotes if the font name contains spaces: `"Liberation Sans"`
- Font names are case-sensitive, but the validation is case-insensitive
- Font families can be specified with fallbacks in the CSS, but the command-line option takes a single font name

## Installing Additional Fonts

### Native Mode

#### Using dk-fonts (Recommended)

The `dk-fonts install` command provides easy installation on all platforms:

```bash
# Install individual font families
dk-fonts install liberation      # Liberation Sans, Serif, Mono
dk-fonts install noto            # Noto Sans, Serif, Mono, CJK
dk-fonts install dejavu          # DejaVu Sans, Serif, Mono
dk-fonts install source-code-pro # Adobe Source Code Pro (monospace)
dk-fonts install roboto          # Google Roboto

# Install all recommended fonts at once
dk-fonts install all

# Install a custom font file
dk-fonts install custom ~/Downloads/MyFont.ttf
```

#### Platform-Specific Installation

**macOS:**
```bash
# Using Homebrew (recommended)
brew tap homebrew/cask-fonts

# Install specific fonts
brew install --cask font-liberation
brew install --cask font-roboto
brew install --cask font-source-code-pro
brew install --cask font-fira-code
brew install --cask font-noto-sans

# Manual installation
# Copy .ttf or .otf files to:
#   ~/Library/Fonts/           (user fonts)
#   /Library/Fonts/            (system fonts, requires sudo)
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install -y \
    fonts-liberation \
    fonts-liberation2 \
    fonts-noto \
    fonts-noto-cjk \
    fonts-dejavu \
    fonts-roboto \
    fonts-source-code-pro

# Refresh font cache
fc-cache -f -v
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install -y \
    liberation-fonts \
    google-noto-fonts \
    dejavu-fonts-common \
    google-roboto-fonts \
    adobe-source-code-pro-fonts

# Refresh font cache
fc-cache -f -v
```

**Linux (Arch):**
```bash
sudo pacman -S --noconfirm \
    ttf-liberation \
    noto-fonts \
    noto-fonts-cjk \
    ttf-dejavu \
    ttf-roboto \
    adobe-source-code-pro-fonts

# Refresh font cache
fc-cache -f -v
```

**Manual installation (Linux):**
```bash
# Copy .ttf or .otf files to:
mkdir -p ~/.local/share/fonts
cp MyFont.ttf ~/.local/share/fonts/

# Refresh font cache
fc-cache -f -v
```

### Docker Mode

#### Using Pre-installed Fonts

The Docker image comes with a comprehensive set of fonts pre-installed:

- **Liberation** (Sans, Serif, Mono) - Metrically compatible with Arial, Times New Roman, Courier
- **Noto** (Sans, Serif, Mono, CJK) - Google's font family with extensive Unicode support
- **DejaVu** (Sans, Serif, Mono) - Popular open-source fonts
- **Roboto** - Google's modern sans-serif font

List fonts in Docker:
```bash
docker run --rm dataknobs/md-tools dk-fonts list
```

#### Using Custom Fonts in Docker

To use fonts not included in the Docker image, mount a fonts directory:

```bash
# Create a fonts directory
mkdir -p ~/my-custom-fonts

# Copy your font files there
cp ~/Downloads/MyCustomFont.ttf ~/my-custom-fonts/

# Mount the directory when running Docker
docker run --rm \
  -v ~/my-custom-fonts:/usr/local/share/fonts/custom \
  -v $(pwd):/workspace \
  dataknobs/md-tools \
  --font-body "MyCustomFont" input.md output.pdf
```

The mounted fonts will be automatically available for use.

## Default Fonts

### Body Text

By default, the following font stack is used for body text:
```
-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif
```

This ensures optimal rendering across different operating systems.

### Code Blocks

By default, the following font stack is used for code:
```
SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace
```

### Font Sizes

- **Screen**: 16px
- **Print**: 12pt

These can be customized using `--font-size` and `--font-size-print` options.

## Recommended Fonts

### For Body Text

**Serif fonts** (formal documents, academic papers):
- **Liberation Serif** - Free, metrically compatible with Times New Roman
- **Noto Serif** - Clean, extensive Unicode support
- **Georgia** - Readable, designed for screens
- **Times New Roman** - Classic, traditional

**Sans-serif fonts** (modern documents, presentations):
- **Liberation Sans** - Free, metrically compatible with Arial
- **Noto Sans** - Clean, modern, extensive Unicode support
- **Roboto** - Google's modern design
- **Open Sans** - Popular, readable
- **Arial** / **Helvetica** - Standard, widely available

### For Code Blocks

- **Liberation Mono** - Free, metrically compatible with Courier New
- **DejaVu Sans Mono** - Clean, excellent readability
- **Monaco** - macOS default, clean
- **Menlo** - macOS default, based on DejaVu
- **Consolas** - Windows default, very readable
- **Courier New** - Classic, universally available

### Cross-Platform Recommendations

For documents that need to work across different systems:

**Best for compatibility:**
```bash
dk-md2pdf \
  --font-body "Liberation Sans" \
  --font-code "Liberation Mono" \
  input.md output.pdf
```

**Best for modern look:**
```bash
dk-md2pdf \
  --font-body "Roboto" \
  --font-code "DejaVu Sans Mono" \
  input.md output.pdf
```

**Best for academic/formal documents:**
```bash
dk-md2pdf \
  --font-body "Liberation Serif" \
  --font-code "Liberation Mono" \
  --theme academic \
  input.md output.pdf
```

## Troubleshooting

### Font Not Found Error

If you get an error that a font is not available:

1. **Check the exact font name:**
   ```bash
   dk-fonts search "partial name"
   ```

2. **Verify the font is installed:**
   ```bash
   dk-fonts validate "Font Name"
   ```

3. **Install the font:**
   ```bash
   # Native mode
   dk-fonts install liberation

   # Or manually install the font and run:
   fc-cache -f -v  # Linux
   ```

### Text Missing in PDFs

If text appears missing or blank in PDFs:

1. **Check if fonts are properly installed:**
   ```bash
   dk-fonts info
   ```

2. **For Mermaid diagrams**, ensure fonts are available:
   ```bash
   # Native mode
   ./native/fix-fonts.sh

   # Or install Liberation fonts manually
   dk-fonts install liberation
   ```

3. **Use verbose mode to see what's happening:**
   ```bash
   dk-md2pdf -v --font-body "Arial" input.md output.pdf
   ```

### Font Doesn't Look Right

1. **Make sure you're using the correct font name:**
   - Use `dk-fonts search` to find the exact name
   - Font names are case-sensitive

2. **Check if the font style is available:**
   ```bash
   dk-fonts list --detailed | grep "Font Name"
   ```

3. **Try a different font from the same family:**
   ```bash
   # Instead of "Arial Bold", use "Arial" with CSS styling
   dk-md2pdf --font-body "Arial" input.md output.pdf
   ```

### Docker Can't Find Custom Fonts

If custom fonts aren't working in Docker:

1. **Verify the mount path is correct:**
   ```bash
   docker run --rm \
     -v /full/path/to/fonts:/usr/local/share/fonts/custom \
     -v $(pwd):/workspace \
     dataknobs/md-tools \
     dk-fonts list | grep "YourFont"
   ```

2. **Ensure fonts are in the mounted directory:**
   ```bash
   ls -la ~/my-custom-fonts/
   ```

3. **Check font file format:**
   - Use .ttf or .otf files
   - .ttc (TrueType Collection) may not work reliably

### fc-list Not Found

If `dk-fonts` reports that `fc-list` is not found:

**macOS:**
```bash
# fontconfig should be installed with most package managers
brew install fontconfig
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install fontconfig

# Fedora/RHEL
sudo dnf install fontconfig

# Arch
sudo pacman -S fontconfig
```

## Advanced Usage

### Using Font Fallbacks

While the command-line accepts a single font, you can create custom CSS themes with fallback fonts by editing the theme CSS files in `src/templates/styles/`.

### Custom CSS for Fonts

For advanced font customization, you can create a custom theme CSS file:

1. Copy an existing theme:
   ```bash
   cp src/templates/styles/github.css src/templates/styles/custom.css
   ```

2. Edit the font-family declarations

3. Use your custom theme:
   ```bash
   dk-md2pdf -t custom input.md output.pdf
   ```

### Embedding Fonts in PDFs

By default, PDFs generated by WeasyPrint embed the fonts, ensuring the document looks the same on all systems, even if the fonts aren't installed.

To verify fonts are embedded:
```bash
# Linux/macOS with pdffonts (from poppler-utils)
pdffonts output.pdf
```

## See Also

- [README.md](README.md) - Main documentation
- [INSTALL.md](INSTALL.md) - Installation instructions
- [examples/](examples/) - Example documents with different fonts

## Contributing

If you find issues with font handling or have suggestions for additional fonts to include in the Docker image, please open an issue on GitHub.
