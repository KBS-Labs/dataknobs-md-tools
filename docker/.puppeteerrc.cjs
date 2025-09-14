module.exports = {
  // Configuration for Puppeteer in Docker environment
  executablePath: '/usr/bin/chromium',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--no-first-run',
    '--no-zygote',
    '--disable-accelerated-2d-canvas'
  ]
};