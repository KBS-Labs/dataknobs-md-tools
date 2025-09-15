# DataKnobs Markdown Tools - Installation Guide

## Quick Install (Recommended)

Our smart installer handles everything automatically:

```bash
./native/install.sh
```

This will:
- **Offer to install pyenv** for isolated Python environment (recommended)
- Install all required dependencies (pandoc, mermaid-cli, weasyprint)
- Set up virtual environment if using pyenv
- Configure PATH automatically
- Handle Python version conflicts

The installer will prompt you once about using pyenv, then handle everything else automatically.

## CI/CD Installation

For automated environments (CI/CD, Docker):

```bash
./native/install-ci.sh
```

This installs dependencies using system packages without any prompts.

## System Requirements

- **Operating System**: macOS, Linux (Ubuntu/Debian, Fedora/RHEL, Arch), or Windows (WSL)
- **Python**: 3.7 or higher
- **Node.js**: 14.x or higher
- **Package Managers**:
  - macOS: Homebrew
  - Linux: apt, yum/dnf, or pacman
  - All: npm (comes with Node.js)

## Dependencies

The following tools will be installed:

1. **Pandoc** - Universal document converter
2. **Mermaid CLI** - Diagram and flowchart generator
3. **WeasyPrint** - HTML/CSS to PDF converter

## Benefits of Using Pyenv (Recommended)

When you run `./native/install.sh`, it will offer to set up pyenv. Here's why we recommend it:

1. **No Python Version Conflicts** - Your tools always use the correct Python version
2. **No System Pollution** - All packages are isolated in a virtual environment
3. **No sudo Required** - Everything installs in your user space
4. **Consistent Across Updates** - System Python updates won't break your tools
5. **Easy Cleanup** - Just delete the `.venv` directory to remove all Python packages

If you choose pyenv, the installer will:
- Install pyenv automatically (if not present)
- Set up Python 3.11.9 (stable, well-tested version)
- Create a virtual environment in the project
- Install all Python dependencies isolated from your system

## Common Installation Issues and Solutions

### 1. Puppeteer Deprecation Warning

**Issue**: When installing mermaid-cli, you may see:
```
npm warn deprecated puppeteer@23.11.1: < 24.10.2 is no longer supported
```

**Solution**: The install script now installs the latest version of mermaid-cli. To update manually:
```bash
npm update -g @mermaid-js/mermaid-cli
```

### 2. Pip Version Warning

**Issue**: You may see a warning about pip being outdated:
```
WARNING: You are using pip version 21.2.4; however, version 25.2 is available.
```

**Solution**: The install script now automatically upgrades pip. To update manually:
```bash
python3 -m pip install --upgrade pip --user
```

### 3. PATH Configuration Issues

**Issue**: After installation, you may see "weasyprint not found" even though it was installed successfully.

**Cause**: Python packages installed with `--user` are placed in a user-specific directory that may not be in your PATH.

**Solution**: Add the Python user bin directory to your PATH:

#### macOS
```bash
# Find your Python version
python3 --version

# Add to your ~/.zshrc or ~/.bash_profile
export PATH="$PATH:$HOME/Library/Python/3.9/bin"  # Replace 3.9 with your version

# Reload your shell configuration
source ~/.zshrc  # or source ~/.bash_profile
```

#### Linux
```bash
# Add to your ~/.bashrc or ~/.zshrc
export PATH="$PATH:$HOME/.local/bin"

# Reload your shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

### 4. Homebrew Not Found (macOS)

**Issue**: The installer fails with "Homebrew not found"

**Solution**: Install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 5. Python Version Mismatch

**Issue**: WeasyPrint fails with library import errors even after installation, or "weasyprint not found" after Python upgrade.

**Cause**: WeasyPrint was installed with one Python version but the system is now using a different version (e.g., after `brew upgrade python`).

**Solution**:

1. Check your current Python version:
```bash
python3 --version
```

2. Reinstall weasyprint with the current Python version:
```bash
# First, ensure GTK dependencies are installed (macOS)
brew install pango gdk-pixbuf cairo gobject-introspection

# Reinstall weasyprint
pip3 install --user --force-reinstall weasyprint
```

3. The updated scripts will now check multiple Python version paths automatically.

### 6. WeasyPrint Library Errors (macOS)

**Issue**: WeasyPrint fails with errors like:
```
OSError: cannot load library 'libgobject-2.0-0'
```

**Solution**: Install the required GTK libraries:
```bash
brew install pango gdk-pixbuf cairo gobject-introspection
```

Then reinstall weasyprint:
```bash
pip3 install --user --force-reinstall weasyprint
```

### 7. Missing Text in Mermaid Diagrams

**Issue**: Mermaid diagrams render but text is missing in Flow Charts, Class Diagrams, State Diagrams, or ER Diagrams.

**Cause**: Missing system fonts that Chromium/Puppeteer needs for rendering text in SVGs.

**Solution**: Run the font fix script:
```bash
./native/fix-fonts.sh
```

Or manually install fonts:

**macOS:**
```bash
brew tap homebrew/cask-fonts
brew install --cask font-liberation
```

**Ubuntu/Debian:**
```bash
sudo apt-get install fonts-liberation fonts-noto
```

**Fedora/RHEL:**
```bash
sudo dnf install liberation-fonts google-noto-fonts
```

After installing fonts, you may need to:
1. Clear npm cache: `npm cache clean --force`
2. Restart your terminal
3. Try the conversion again

### 8. Permission Denied Errors

**Issue**: Installation fails with permission errors

**Solution**:
- Never run the install script with `sudo`
- For global npm packages on Linux, you may need to configure npm to use a different directory:
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Manual Installation

If the automatic installer doesn't work for your system, you can install the dependencies manually:

### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install pandoc node python3

# Install npm packages
npm install -g @mermaid-js/mermaid-cli@latest

# Upgrade pip
python3 -m pip install --upgrade pip --user

# Install Python packages
pip3 install --user weasyprint

# Add Python user bin to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="$PATH:$HOME/Library/Python/$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')/bin"
```

### Ubuntu/Debian

```bash
# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install -y pandoc nodejs npm python3 python3-pip
sudo apt-get install -y python3-cffi python3-brotli libpango-1.0-0 libpangoft2-1.0-0

# Install npm packages
sudo npm install -g @mermaid-js/mermaid-cli@latest

# Upgrade pip
python3 -m pip install --upgrade pip --user

# Install Python packages
pip3 install --user weasyprint

# Add to PATH (add to ~/.bashrc)
export PATH="$PATH:$HOME/.local/bin"
```

### Fedora/RHEL/CentOS

```bash
# Install dependencies
sudo dnf install -y pandoc nodejs npm python3 python3-pip

# Install npm packages
sudo npm install -g @mermaid-js/mermaid-cli@latest

# Upgrade pip
python3 -m pip install --upgrade pip --user

# Install Python packages
pip3 install --user weasyprint

# Add to PATH (add to ~/.bashrc)
export PATH="$PATH:$HOME/.local/bin"
```

### Arch Linux

```bash
# Install dependencies
sudo pacman -S --noconfirm pandoc nodejs npm python python-pip

# Install npm packages
sudo npm install -g @mermaid-js/mermaid-cli@latest

# Upgrade pip
python -m pip install --upgrade pip --user

# Install Python packages
pip install --user weasyprint

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/.local/bin"
```

## Verification

After installation, verify that all tools are accessible:

```bash
# Check installations
pandoc --version
mmdc --version
weasyprint --version

# If any command is not found, check your PATH configuration
echo $PATH
```

## Diagnostic Tool

If you're experiencing issues, run the diagnostic script first:

```bash
./native/diagnose.sh
```

This will:
- Check all required dependencies
- Detect Python version mismatches
- Find tools in non-standard locations
- Verify library imports
- Provide specific fix instructions

## Troubleshooting PATH Issues

If a command is not found after installation:

1. **Find where it was installed:**
   ```bash
   # For Python packages
   python3 -m site --user-base

   # For npm packages
   npm list -g --depth=0
   ```

2. **Check if the directory is in your PATH:**
   ```bash
   echo $PATH | tr ':' '\n' | grep -E "(npm|python|local)"
   ```

3. **Add the missing directory to your PATH:**
   - Edit your shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`)
   - Add the appropriate `export PATH` line
   - Reload your shell configuration or restart your terminal

## Testing the Installation

Once everything is installed, test the converter:

```bash
# Create a simple test file
echo "# Test\n\nThis is a **test** document." > test.md

# Convert to PDF
./native/dk-md2pdf test.md test.pdf

# Check if the PDF was created
ls -la test.pdf
```

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [GitHub Issues](https://github.com/dataknobs/markdown-tools/issues) page
2. Review the error messages carefully - they often indicate what's missing
3. Ensure your system is up to date
4. Try running the commands manually to identify which step is failing

## Next Steps

After successful installation:

1. Review the [README.md](README.md) for usage instructions
2. Check the [examples](examples/) directory for sample conversions
3. Configure your preferred conversion settings