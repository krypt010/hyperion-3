#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 1. More aggressive cleanup of port 3000
log "Cleaning up port 3000..."
PORT=3000
if command -v fuser >/dev/null 2>&1; then
    fuser -k $PORT/tcp || true
elif command -v lsof >/dev/null 2>&1; then
    lsof -ti :$PORT | xargs kill -9 || true
fi

# 2. Dependency check
log "Installing Puppeteer..."
npm install puppeteer --no-save

# 3. Start server with wait
log "Starting dev server on port $PORT..."
npm run dev -- -p $PORT &
SERVER_PID=$!

# Use a trap that is more reliable
trap "kill -9 $SERVER_PID || true" EXIT

log "Waiting for server to respond..."
MAX_RETRIES=60
COUNT=0
until curl -s http://localhost:$PORT > /dev/null; do
    sleep 2
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        log "Error: Server timed out."
        exit 1
    fi
done

# 4. Generate screenshot using Puppeteer
cat << 'EOF' > screenshot.js
const puppeteer = require('puppeteer');
(async () => {
    const browser = await puppeteer.launch({ 
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        executablePath: '/usr/bin/chromium'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });
    try {
        console.log("Navigating to deliveries page...");
        await page.goto('http://localhost:3000/deliveries', { waitUntil: 'networkidle0', timeout: 90000 });
        // Additional wait for potential client-side data fetching
        await new Promise(r => setTimeout(r, 3000));
        await page.screenshot({ path: 'output.png', fullPage: true });
        console.log("Screenshot captured.");
    } catch (e) {
        console.error("Screenshot capture failed:", e);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
EOF

log "Executing screenshot script..."
node screenshot.js
log "Done."