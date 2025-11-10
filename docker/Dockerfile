# Use Node 22 for latest npm and better performance
FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pandoc \
    python3-pip \
    python3-cffi \
    python3-brotli \
    python3-venv \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libpangocairo-1.0-0 \
    chromium \
    fonts-liberation \
    fonts-liberation2 \
    fonts-noto \
    fonts-noto-cjk \
    fonts-dejavu \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install uv for Python package management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Set environment for Puppeteer/Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Update npm to latest version first
RUN npm install -g npm@latest

# Install mermaid-cli globally the simple way
# The deprecation warning doesn't affect functionality
RUN npm install -g @mermaid-js/mermaid-cli@latest

# Create app directory
WORKDIR /app

# Copy Python project files first (for better layer caching)
COPY .python-version pyproject.toml /app/
COPY src/python/ /app/src/python/

# Install Python dependencies using uv
RUN uv sync

# Copy rest of application files
COPY src/ /app/src/
COPY native/dk-md2pdf /app/dk-md2pdf
COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY docker/puppeteer-config.json /app/src/config/puppeteer-config.json
COPY docker/.puppeteerrc.cjs /app/.puppeteerrc.cjs

# Also copy to root for mmdc to find it
COPY docker/.puppeteerrc.cjs /.puppeteerrc.cjs

# Make scripts executable
RUN chmod +x /app/dk-md2pdf /app/docker-entrypoint.sh

# Create workspace directory
WORKDIR /workspace

# Create .dockerenv to indicate we're in Docker
RUN touch /.dockerenv

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]