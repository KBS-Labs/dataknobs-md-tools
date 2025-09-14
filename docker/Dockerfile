FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pandoc \
    python3-pip \
    python3-cffi \
    python3-brotli \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libpangocairo-1.0-0 \
    chromium \
    fonts-liberation \
    fonts-noto \
    fonts-noto-cjk \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Set environment for Puppeteer/Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Install Python packages
RUN pip3 install --no-cache-dir --break-system-packages weasyprint

# Install Node packages
RUN npm install -g @mermaid-js/mermaid-cli

# Create app directory
WORKDIR /app

# Copy application files
COPY src/ /app/src/
COPY native/dk-md2pdf /app/dk-md2pdf
COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /app/dk-md2pdf /app/docker-entrypoint.sh

# Create workspace directory
WORKDIR /workspace

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]