# Dependency Versions

This document tracks the versions of all key dependencies for DataKnobs Markdown Tools and provides guidance on updating them.

**Last Updated:** 2025-01-10

## Version Strategy

We use **major version pinning** for critical dependencies to balance stability with security updates:
- Get automatic patch releases (security fixes, bug fixes)
- Avoid breaking changes from major version bumps
- Manually review and test major version updates quarterly

## Core Dependencies

### Pandoc
- **Current Version:** 3.1.11
- **Update Strategy:** Pinned to 3.x
- **Location:**
  - Docker: `docker/Dockerfile` (ENV PANDOC_VERSION)
  - Native: Installed via system package manager
- **Security:** HIGH - Processes untrusted markdown input
- **How to Update:**
  - Check releases: https://github.com/jgm/pandoc/releases
  - Update `PANDOC_VERSION` in `docker/Dockerfile`
  - Test with sample documents before deploying
  - Update native installation if needed

### Node.js
- **Current Version:** 22.x LTS
- **Update Strategy:** Follow LTS releases
- **Location:**
  - Docker: `docker/Dockerfile` (FROM node:22-slim)
  - Native: `native/install.sh` (NODE_VERSION)
- **Security:** MEDIUM - Runs mermaid-cli for diagram generation
- **How to Update:**
  - Check LTS schedule: https://nodejs.org/en/about/previous-releases
  - Update base image version in `docker/Dockerfile`
  - Update NODE_VERSION in `native/install.sh`
  - Test mermaid-cli functionality

### Python
- **Current Version:** 3.11.9
- **Update Strategy:** Pinned to specific patch version
- **Location:** `.python-version` (used by uv)
- **Security:** MEDIUM - Runs WeasyPrint and SVG processing
- **How to Update:**
  - Update `.python-version` file
  - Run `uv sync` to update lock file
  - Test HTML/SVG processing and PDF generation
  - Ensure WeasyPrint compatibility

### Mermaid CLI
- **Current Version:** Latest (auto-updated)
- **Update Strategy:** Always use @latest
- **Location:**
  - Docker: `docker/Dockerfile` (npm install @mermaid-js/mermaid-cli@latest)
  - Native: `native/install.sh` (npm install @mermaid-js/mermaid-cli)
- **Security:** LOW - Generates diagrams from markdown
- **How to Update:**
  - Automatically updated on each Docker build
  - Native: `npm update -g @mermaid-js/mermaid-cli`
  - Test diagram rendering after updates

## Python Packages (via uv)

Managed in `pyproject.toml` and locked in `uv.lock`:

### WeasyPrint
- **Current Version:** 63.1 (via pyproject.toml)
- **Update Strategy:** Follow latest stable
- **Security:** HIGH - Renders HTML/CSS to PDF (potential XSS/injection)
- **How to Update:**
  - Update version in `pyproject.toml`
  - Run `uv sync` to update lock file
  - Test PDF generation thoroughly

### Other Python Dependencies
- **cffi, Pillow, pyphen, tinycss2, cssselect2:** Managed by WeasyPrint
- **Update Strategy:** Automatic via WeasyPrint dependencies
- **How to Update:** `uv sync --upgrade`

## System Libraries (Docker only)

These are installed via apt-get in the Docker image:

- **libpango, libharfbuzz, libpangocairo:** Font rendering for WeasyPrint
- **chromium:** Headless browser for Mermaid rendering
- **fonts-liberation, fonts-noto, fonts-dejavu:** Font families

**Update Strategy:** Automatically updated to latest versions in Debian repositories during Docker build.

## Package Manager Tools

### uv (Python package manager)
- **Current Version:** Latest from install script
- **Update Strategy:** Always use latest from official install script
- **Location:**
  - Docker: `docker/Dockerfile` (curl -LsSf https://astral.sh/uv/install.sh)
  - Native: `native/install.sh`
- **How to Update:** Re-run install script or `uv self update`

## Update Schedule

### Recommended Update Frequency

| Component | Frequency | Reason |
|-----------|-----------|--------|
| Pandoc | Quarterly | Security + features |
| Node.js | When new LTS | Stability |
| Python | Semi-annually | Security + compatibility |
| WeasyPrint | Quarterly | Security fixes |
| Mermaid CLI | Automatic | Feature updates |
| System libs | On rebuild | Security patches |

### Security Monitoring

Subscribe to security advisories for:
- **Pandoc:** Watch GitHub releases and security advisories
- **WeasyPrint:** https://github.com/Kozea/WeasyPrint/security
- **Node.js:** https://nodejs.org/en/blog/vulnerability/
- **Python:** https://www.python.org/news/security/

## Testing After Updates

After updating any dependency, test:

1. **Mermaid diagram rendering:**
   ```bash
   dk-md2pdf test/fixtures/sample-diagrams.md test-output.pdf
   ```

2. **SVG height constraints:**
   - Test with tall diagrams to ensure max-height works
   - Verify SVG IDs are unique

3. **HTML to PDF conversion:**
   - Check font rendering
   - Verify CSS styles applied correctly
   - Test with complex layouts

4. **Both Docker and native paths:**
   ```bash
   dk-md2pdf --use-docker sample.md docker-output.pdf
   dk-md2pdf --use-native sample.md native-output.pdf
   ```

5. **Compare outputs:**
   - Visual inspection of both PDFs
   - Verify identical rendering

## Version Checking Commands

Check installed versions:

```bash
# Pandoc
pandoc --version

# Node.js
node --version

# Python (via uv)
uv run python --version

# Mermaid CLI
mmdc --version

# WeasyPrint (via uv)
uv run python -m weasyprint --version

# uv
uv --version
```

## Rollback Procedure

If an update causes issues:

1. **Docker:**
   - Revert `PANDOC_VERSION` in `docker/Dockerfile`
   - Rebuild: `DOCKER_BUILDKIT=1 docker build -t dataknobs/md-tools -f docker/Dockerfile .`

2. **Python packages:**
   - Git revert changes to `pyproject.toml` and `uv.lock`
   - Run `uv sync`

3. **Native tools:**
   - Use system package manager to install specific version
   - Or download older release manually

## Notes

- **Version detection:** The conversion script automatically detects Pandoc version and uses appropriate flags (`--embed-resources` for 3.x, `--self-contained` for 2.x)
- **Reproducible builds:** Docker builds are reproducible within the same version of dependencies
- **Native flexibility:** Native installations may have different versions across systems, but compatibility code handles this
