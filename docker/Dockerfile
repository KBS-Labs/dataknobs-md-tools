# Use Node 22 LTS for latest npm and better performance
# Version pinning: Node 22.x (LTS), updated 2025-01
FROM node:22-slim

# Install system dependencies (except Pandoc - we'll install that separately)
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-cffi \
    python3-brotli \
    python3-venv \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libpangocairo-1.0-0 \
    chromium \
    fontconfig \
    fonts-liberation \
    fonts-liberation2 \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-mono \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    fonts-roboto \
    fonts-roboto-unhinted \
    curl \
    wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Refresh font cache
RUN fc-cache -f -v

# Install Pandoc 3.x from GitHub releases
# Debian's apt repo has old Pandoc 2.x, so we download directly
# Version pinning: Pandoc 3.x (latest stable)
# Supports both amd64 (x86_64) and arm64 (Apple Silicon) architectures
ENV PANDOC_VERSION=3.1.11
RUN ARCH=$(dpkg --print-architecture) && \
    wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-${ARCH}.deb \
    && dpkg -i pandoc-${PANDOC_VERSION}-1-${ARCH}.deb \
    && rm pandoc-${PANDOC_VERSION}-1-${ARCH}.deb

# Install uv for Python package management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Set environment for Puppeteer/Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Update npm to latest version first
RUN npm install -g npm@latest

# Install mermaid-cli globally
# Version pinning: Using @latest to stay current with Mermaid diagram features
# The deprecation warning doesn't affect functionality
RUN npm install -g @mermaid-js/mermaid-cli@latest

# Create app directory
WORKDIR /app

# Copy Python project files first (for better layer caching)
COPY .python-version pyproject.toml /app/
COPY src/python/ /app/src/python/

# Install Python dependencies using uv
# Version pinning: Python version specified in .python-version (3.11.9)
# WeasyPrint and other dependencies specified in pyproject.toml
RUN uv sync

# Copy rest of application files
COPY src/ /app/src/
COPY native/dk-md2pdf /app/dk-md2pdf
COPY bin/dk-fonts /app/dk-fonts
COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY docker/puppeteer-config.json /app/src/config/puppeteer-config.json
COPY docker/.puppeteerrc.cjs /app/.puppeteerrc.cjs

# Also copy to root for mmdc to find it
COPY docker/.puppeteerrc.cjs /.puppeteerrc.cjs

# Make scripts executable and entire /app directory accessible to all users
# Also make uv's Python installation accessible (it's installed in /root/.local/share/uv)
# (needed when running with --user on Linux)
RUN chmod +x /app/dk-md2pdf /app/dk-fonts /app/docker-entrypoint.sh && \
    chmod -R a+rX /app && \
    chmod a+x /root /root/.local /root/.local/share && \
    chmod -R a+rX /root/.local/share/uv

# Add dk-fonts to PATH (via symlink in /usr/local/bin)
RUN ln -s /app/dk-fonts /usr/local/bin/dk-fonts

# Create workspace directory
WORKDIR /workspace

# Create .dockerenv to indicate we're in Docker
RUN touch /.dockerenv

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]