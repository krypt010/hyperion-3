#!/bin/bash
set -euo pipefail

# Configuration
PORT=3000
URL="http://localhost:${PORT}/animals"

# Cleanup
cleanup() {
    if [ -n "${SERVER_PID:-}" ]; then kill "$SERVER_PID" 2>/dev/null || true; fi
    rm -f screenshot.js dev.log
}
trap cleanup EXIT

# Install Puppeteer if needed (in container)
if ! npm list puppeteer &>/dev/null; then
    echo "Installing Puppeteer..."
    npm install puppeteer
fi

# Create screenshot script
cat > screenshot.js <<'EOF'
const puppeteer = require('puppeteer');
(async () => {
    const url = process.argv[2];
    if (!url) { console.error('No URL'); process.exit(1); }
    
    // Launch args for Docker environment
    const browser = await puppeteer.launch({ 
        headless: 'new', 
        executablePath: '/usr/bin/chromium',
        dumpio: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'] 
    });
    
    try {
        const page = await browser.newPage();
        await page.setViewport({ width: 1280, height: 720 });
        await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
        
        console.log('Waiting for content...');
        await page.waitForSelector('h1', { timeout: 10000 });
        // Wait a bit for potential hydration flash/error
        await new Promise(r => setTimeout(r, 1000));
        
        await page.screenshot({ path: 'verification_evidence/output_before.png', fullPage: true });
        console.log('Screenshot saved to verification_evidence/output_before.png');
    } catch (e) {
        console.error('Puppeteer failed:', e);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
EOF

# Start Server
echo "Starting Next.js..."
npm run dev >dev.log 2>&1 &
SERVER_PID=$!

# Wait for Server
echo "Waiting for $URL..."
TIMEOUT=60
elapsed=0
while ! curl -s --head "$URL" >/dev/null; do
    sleep 1
    elapsed=$((elapsed+1))
    if [ $elapsed -ge $TIMEOUT ]; then 
        echo "Timeout waiting for server"; 
        cat dev.log; 
        exit 1; 
    fi
done

# Run Screenshot
mkdir -p verification_evidence
node screenshot.js "$URL"
