# DataKnobs Markdown Tools

Convert Markdown files with Mermaid diagrams to beautiful PDF and HTML documents.

## Features

- 📝 **Full Markdown Support** - All standard Markdown features
- 📊 **Mermaid Diagrams** - Flowcharts, sequence diagrams, Gantt charts, and more
- 🎨 **Multiple Themes** - GitHub, Academic, and Minimal styles
- 🔤 **Font Customization** - Choose fonts and sizes for body text and code
- 📄 **Multiple Formats** - Generate PDF and HTML outputs
- 🐳 **Docker Support** - Run without installing dependencies
- 🚀 **Fast & Lightweight** - Efficient conversion pipeline
- 📚 **Table of Contents** - Auto-generated TOC support
- 🎯 **Self-Contained HTML** - Embedded images for portable documents

## Installation

```bash
# Clone the repository
git clone https://github.com/KBS-Labs/dataknobs-md-tools
cd dataknobs-md-tools
```

### Option 1: Docker (Recommended - Single Dependency)

Docker is the easiest way to get started - it bundles all dependencies in a container.

```bash
# Build the Docker image (Docker Hub coming soon!)
./build-docker.sh

# Convert markdown to PDF
./bin/dk-md2pdf input.md output.pdf

# Convert markdown to HTML
./bin/dk-md2pdf -f html input.md output.html
```

The wrapper script (`bin/dk-md2pdf`) automatically uses Docker when native tools aren't installed.

**Alternative build methods:**
```bash
# Using buildx (recommended, no deprecation warnings)
docker buildx build -t dataknobs/md-tools -f docker/Dockerfile . --load

# Using legacy builder
DOCKER_BUILDKIT=1 docker build -t dataknobs/md-tools -f docker/Dockerfile .
```

**Note:** If you get "unknown command: docker buildx", install it:
- **macOS (Homebrew):** `brew install docker-buildx`
- **Linux:** Install from [Docker buildx releases](https://github.com/docker/buildx/releases)
- **Colima users:** Add to `~/.docker/config.json`:
  ```json
  {
    "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
  }
  ```

### Option 2: Native Installation (Faster Performance)

Native installation provides better performance but requires installing dependencies on your system.

```bash
# Run installer (supports macOS, Linux)
./native/install.sh

# Convert markdown to PDF
./bin/dk-md2pdf input.md output.pdf

# Add to PATH (optional)
export PATH="$PATH:$(pwd)/bin"
```

The installer automatically:
- Installs **uv** (Python package manager)
- Installs **pandoc**, **Node.js**, and **mermaid-cli**
- Installs Python 3.11.9 and **weasyprint** via `uv`
- Handles all system dependencies for your OS
- Uses sudo for npm global installs only when necessary

#### Manual Installation

If the installer doesn't work for your system:

**System Dependencies:**
1. **uv**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. **Pandoc**: https://pandoc.org/installing.html
3. **Node.js & npm**: https://nodejs.org/
4. **Mermaid CLI**: `npm install -g @mermaid-js/mermaid-cli`

**Python Dependencies:**
```bash
# From project root
uv sync
```

That's it! `uv` automatically installs the correct Python version and all dependencies.

## Version Information

### Current Versions (Updated 2025-01-10)

| Component | Version | Update Strategy |
|-----------|---------|-----------------|
| **Pandoc** | 3.1.11 | Pinned to 3.x |
| **Node.js** | 22.x LTS | Follow LTS |
| **Python** | 3.11.9 | Pinned patch |
| **Mermaid CLI** | Latest | Auto-update |
| **WeasyPrint** | 63.1 | Latest stable |

### Version Management

We use **major version pinning** to balance stability with security updates:
- ✅ Automatic patch releases (security fixes, bug fixes)
- ✅ Avoid breaking changes from major version bumps
- ✅ Manually review major updates quarterly

**For detailed version information**, including:
- Security monitoring guidance
- How to update each dependency
- Testing procedures after updates
- Rollback procedures

See **[VERSIONS.md](VERSIONS.md)** for complete documentation.

### Compatibility

The conversion script automatically detects tool versions and adapts:
- **Pandoc 3.x**: Uses `--embed-resources --standalone`
- **Pandoc 2.x**: Uses `--self-contained` (legacy)

This ensures both Docker and native installations work correctly regardless of the Pandoc version installed.

## Usage

### Command Line Interface

```bash
dk-md2pdf [OPTIONS] input.md [output]
```

**Output Format Auto-Detection**: The tool automatically detects the output format based on file extension:
- `.html` or `.htm` → HTML output
- `.pdf` or no extension → PDF output
- Use `-f` flag to override auto-detection

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-h, --help` | Show help message | - |
| `-f, --format` | Force output format: `pdf` or `html` | auto-detect |
| `-t, --theme` | CSS theme: `github`, `academic`, `minimal`, `business` | `github` |
| `--toc` | Include table of contents | disabled |
| `--no-mermaid` | Skip Mermaid diagram processing | disabled |
| `--standalone` | Create self-contained HTML with embedded CSS | disabled |
| `--keep-html` | When generating PDF, also save intermediate HTML | disabled |
| `--keep-svgs` | Keep SVG files as external files (HTML only) | embed in HTML |
| `-v, --verbose` | Enable verbose output | disabled |
| `--list-fonts` | List all available fonts and exit | - |
| `--font-body FONT` | Font for body text (e.g., "Georgia") | system default |
| `--font-code FONT` | Font for code blocks (e.g., "Monaco") | system default |
| `--font-size SIZE` | Base font size in pixels | 16 |
| `--font-size-print SIZE` | Print font size (e.g., "11pt") | 12pt |

### Examples

```bash
# Basic conversion (creates input.pdf)
dk-md2pdf input.md

# Auto-detect format from extension
dk-md2pdf input.md output.html    # Creates HTML
dk-md2pdf input.md output.pdf     # Creates PDF

# Generate both PDF and HTML in one run
dk-md2pdf --keep-html input.md output.pdf

# HTML with external SVG files (not embedded)
dk-md2pdf --keep-svgs input.md output.html

# Academic style with TOC
dk-md2pdf -t academic --toc paper.md

# Self-contained HTML with embedded CSS and images
dk-md2pdf --standalone --toc report.md report.html

# List available fonts
dk-md2pdf --list-fonts

# Use custom fonts
dk-md2pdf --font-body "Georgia" --font-code "Monaco" input.md output.pdf

# Customize font sizes
dk-md2pdf --font-size 14 --font-size-print 11pt input.md output.pdf

# Combine font options with theme
dk-md2pdf -t academic --font-body "Liberation Serif" --font-code "Liberation Mono" paper.md
```

### Global Installation

```bash
# Using symlink (Unix/Linux/macOS)
sudo ln -s $(pwd)/bin/dk-md2pdf /usr/local/bin/dk-md2pdf
sudo ln -s $(pwd)/bin/dk-md2html /usr/local/bin/dk-md2html

# Using alias
echo 'alias dk-md2pdf="'$(pwd)'/bin/dk-md2pdf"' >> ~/.bashrc
echo 'alias dk-md2html="'$(pwd)'/bin/dk-md2html"' >> ~/.bashrc
source ~/.bashrc
```

## Themes

### GitHub (Default)
Clean, modern style similar to GitHub's markdown rendering. Perfect for technical documentation and README files.

### Academic
Professional appearance suitable for papers, reports, and formal documents. Features serif fonts and formal formatting.

### Minimal
Simple, distraction-free design focusing on readability. Ideal for basic documents and printing.

### Business
Compact, professional styling optimized for business documents. Features clean Liberation Sans font, professional blue color scheme, compact spacing, and polished table formatting. Perfect for reports, proposals, and corporate documentation.

## Font Management

DataKnobs MD Tools provides comprehensive font management capabilities for customizing the appearance of your documents.

### Quick Start

```bash
# List all available fonts
dk-fonts list

# Search for specific fonts
dk-fonts search "Arial"

# Check if a font is available
dk-fonts validate "Georgia"

# See font system information
dk-fonts info
```

### Font Customization

Customize fonts in your documents using command-line options:

```bash
# Use custom body and code fonts
dk-md2pdf --font-body "Georgia" --font-code "Monaco" input.md output.pdf

# Adjust font sizes
dk-md2pdf --font-size 14 --font-size-print 11pt input.md output.pdf

# Combine with themes
dk-md2pdf -t academic --font-body "Liberation Serif" paper.md
```

### Installing Additional Fonts

**Native Mode:**
```bash
# Install recommended font families
dk-fonts install liberation    # Liberation Sans, Serif, Mono
dk-fonts install noto          # Noto Sans, Serif, Mono, CJK
dk-fonts install roboto        # Google Roboto
dk-fonts install all           # Install all recommended fonts

# Install custom fonts
dk-fonts install custom ~/Downloads/MyFont.ttf
```

**Docker Mode:**

The Docker image includes a comprehensive set of pre-installed fonts:
- Liberation (Sans, Serif, Mono)
- Noto (Sans, Serif, Mono, CJK)
- DejaVu (Sans, Serif, Mono)
- Roboto

For custom fonts in Docker, mount a fonts directory:
```bash
docker run -v ~/my-fonts:/usr/local/share/fonts/custom \
           -v $(pwd):/workspace dataknobs/md-tools \
           --font-body "MyCustomFont" input.md output.pdf
```

### Font Recommendations

**For cross-platform compatibility:**
- Body: Liberation Sans or Liberation Serif
- Code: Liberation Mono

**For modern documents:**
- Body: Roboto or Noto Sans
- Code: DejaVu Sans Mono

**For academic/formal documents:**
- Body: Liberation Serif or Noto Serif
- Code: Liberation Mono

For complete font management documentation, see **[FONTS.md](FONTS.md)**.

## HTML Output Features

### Self-Contained Documents

By default, HTML output creates fully self-contained documents:
- **Embedded Images**: All Mermaid diagrams are embedded as base64 data URIs
- **No External Files**: Single HTML file contains everything
- **Portable**: Share or email the HTML file without attachments
- **Clean Directories**: No SVG files cluttering your output folder

To keep SVG files as separate external files (previous behavior):
```bash
dk-md2pdf --keep-svgs input.md output.html
```

### Dual Output Generation

Generate both PDF and HTML in a single command:
```bash
dk-md2pdf --keep-html input.md output.pdf
# Creates: output.pdf and output.html
```

## Mermaid Diagram Support

All Mermaid diagram types are supported:

- Flowcharts
- Sequence diagrams
- Class diagrams
- State diagrams
- Entity Relationship diagrams
- Gantt charts
- Pie charts
- Git graphs
- User journey maps
- XY charts

For authoring tips, known limitations, and workarounds, see the **[Mermaid Authoring Guide](docs/mermaid-authoring-guide.md)**.

Example:

````markdown
```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Success]
    B -->|No| D[Try Again]
    D --> B
```
````

## CI/CD Integration

### GitHub Actions

```yaml
name: Generate PDFs
on: push

jobs:
  convert:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker pull dataknobs/md-tools
      - run: |
          for file in docs/*.md; do
            docker run --rm -v $(pwd):/workspace \
              dataknobs/md-tools "$file"
          done
      - uses: actions/upload-artifact@v3
        with:
          name: pdfs
          path: docs/*.pdf
```

### GitLab CI

```yaml
generate-docs:
  image: dataknobs/md-tools
  script:
    - dk-md2pdf --toc README.md documentation.pdf
  artifacts:
    paths:
      - documentation.pdf
```

## Programmatic Usage

### Python

```python
import subprocess

def convert_markdown(input_file, output_file, theme='github'):
    subprocess.run([
        'docker', 'run', '--rm',
        '-v', f'{os.getcwd()}:/workspace',
        'dataknobs/md-tools',
        '--theme', theme,
        input_file, output_file
    ], check=True)
```

### Node.js

```javascript
const { exec } = require('child_process');

function convertMarkdown(input, output, theme = 'github') {
    return new Promise((resolve, reject) => {
        exec(`dk-md2pdf --theme ${theme} ${input} ${output}`,
            (error, stdout, stderr) => {
                if (error) reject(error);
                else resolve(output);
            });
    });
}
```

## Troubleshooting

### Docker Issues

```bash
# Check Docker is running
docker info

# Build image locally if pull fails
DOCKER_BUILDKIT=1 docker build -t dataknobs/md-tools -f docker/Dockerfile .

# Run with more memory if needed
docker run --rm -m 1g -v $(pwd):/workspace dataknobs/md-tools input.md
```

**Files outside current directory:** The wrapper script (`bin/dk-md2pdf`) automatically handles mounting directories for files outside your current working directory. If using `docker run` directly, you'll need to mount each directory:
```bash
# Convert file from different directory
docker run --rm \
  -v $(pwd):/workspace \
  -v /path/to/docs:/mnt/path/to/docs \
  dataknobs/md-tools /mnt/path/to/docs/input.md output.pdf
```

**Linux file permission issues:** On Linux, output files may be owned by root. The wrapper script handles this automatically, but if using `docker run` directly:
```bash
docker run --rm --user "$(id -u):$(id -g)" -v $(pwd):/workspace dataknobs/md-tools input.md
```

### Native Installation Issues

```bash
# Check installed dependencies
which pandoc mmdc weasyprint

# Reinstall specific component (may need sudo on Linux)
sudo npm install -g @mermaid-js/mermaid-cli
pip install --upgrade weasyprint

# Use verbose mode for debugging
dk-md2pdf -v input.md
```

**npm permission errors on Linux:** If global npm installs fail, you can either:
1. Re-run the installer (`./native/install.sh`) - it now detects when sudo is needed
2. Configure npm to use a user-writable directory:
   ```bash
   mkdir -p ~/.npm-global
   npm config set prefix '~/.npm-global'
   echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

### Mermaid Rendering Issues

**Mermaid processing failed warning?** This usually indicates a parsing error in your Mermaid diagrams.

To diagnose the issue:
```bash
# Use verbose mode to see the actual error
dk-md2pdf -v input.md output.html
```

Common issue: **"Lexical error" or "Unrecognized text" errors**

If you see errors like `Lexical error on line X. Unrecognized text`, especially with `<br/>` tags, the issue is that Mermaid requires node labels containing special characters to be quoted.

**Solution**: Wrap all node labels containing `<br/>` or other special characters in double quotes:

```diff
# ❌ This will fail:
- NodeName[Label with<br/>line break]
+ # ✅ This will work:
+ NodeName["Label with<br/>line break"]

# ❌ This will fail for database nodes:
- DB[(Database<br/>PostgreSQL)]
+ # ✅ This will work:
+ DB[("Database<br/>PostgreSQL")]
```

**Missing text in diagrams?** Run the font fix:
```bash
./native/fix-fonts.sh
```

For other mermaid issues:

- Ensure diagrams are in proper mermaid code blocks
- Check mermaid syntax at https://mermaid.live
- Use `--no-mermaid` flag to skip diagram processing

## Project Structure

```
dataknobs-md-tools/
├── bin/                    # User-facing scripts
│   ├── dk-md2pdf          # Main converter
│   └── dk-md2html         # HTML converter alias
├── docs/                  # Documentation
│   └── mermaid-authoring-guide.md
├── native/                # Native installation
│   ├── dk-md2pdf          # Core conversion script
│   └── install.sh         # Dependency installer
├── docker/                # Docker implementation
│   ├── Dockerfile         # Container definition
│   └── docker-entrypoint.sh
├── src/                   # Core resources
│   ├── python/            # Python modules
│   ├── templates/         # HTML templates
│   │   └── styles/        # CSS themes
│   └── config/            # Configuration files
├── examples/              # Sample documents
└── tests/                 # Test files
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Built with:
- [Pandoc](https://pandoc.org/) - Universal document converter
- [Mermaid](https://mermaid-js.github.io/) - Diagram and chart generation
- [WeasyPrint](https://weasyprint.org/) - HTML/CSS to PDF converter

Part of the [DataKnobs](https://github.com/KBS-Labs) ecosystem.

## Support

- 📧 Email: support@kbs-labs.com
- 🐛 Issues: [GitHub Issues](https://github.com/KBS-Labs/dataknobs-md-tools/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/KBS-Labs/dataknobs-md-tools/discussions)
