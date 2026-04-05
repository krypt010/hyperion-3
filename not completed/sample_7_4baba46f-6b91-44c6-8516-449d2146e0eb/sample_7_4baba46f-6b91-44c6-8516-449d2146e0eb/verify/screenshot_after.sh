#!/bin/bash
set -euo pipefail

PORT=8080
SERVER_PID=""

# Cleanup function to kill the server on script exit
cleanup() {
    echo ">>> Cleaning up..."
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        echo "--- Server with PID $SERVER_PID killed."
    fi
    # Remove temporary script
    rm -f screenshot.js
}

# Register the cleanup function to be called on script exit, error, or interrupt
trap cleanup EXIT SIGINT SIGTERM

echo ">>> Starting screenshot script (after changes)..."

# --- 1. Start a web server ---
# The Dockerfile provides node and http-server globally.
if [ -d "env" ]; then
    echo ">>> Found env directory, starting http-server on port $PORT..."
    pushd env >/dev/null
    python3 -m http.server $PORT >/dev/null 2>&1 &
    SERVER_PID=$!
    popd >/dev/null
    echo "--- Server started with PID: $SERVER_PID"
else
    echo "!!! Error: No index.html found. Cannot start server." >&2
    exit 1
fi

# --- 2. Wait for server to be ready ---
echo ">>> Waiting for server to become available..."
timeout 30s bash -c 'until curl -s --head http://localhost:'"$PORT"' > /dev/null; do echo "--- Waiting..."; sleep 1; done'
if [ $? -ne 0 ]; then
    echo "!!! Error: Server did not start within 30 seconds." >&2
    exit 1
fi
echo ">>> Server is up and running."

# --- 3. Create Puppeteer script ---
echo ">>> Creating screenshot.js..."
cat <<'EOF' > screenshot.js
const puppeteer = require('puppeteer');

(async () => {
    const url = process.argv[2];
    if (!url) {
        console.error('Error: Please provide a URL as the first argument.');
        process.exit(1);
    }
    console.log(`--- Taking screenshot of ${url}`);

    let browser;
    try {
        browser = await puppeteer.launch({
            executablePath: '/snap/bin/chromium',
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
        });

        const page = await browser.newPage();
        
        // Set a mobile viewport to demonstrate the fix
        await page.setViewport({
            width: 375, // iPhone X width
            height: 812, // iPhone X height
            isMobile: true,
            hasTouch: true,
            deviceScaleFactor: 2
        });
        
        await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
        
        // Extra wait for any animations or dynamic content to settle
        await new Promise(resolve => setTimeout(resolve, 1000));

        await page.screenshot({ path: 'output.png', fullPage: true });

        console.log('--- Screenshot saved as output.png');

    } catch (error) {
        console.error('!!! Error during screenshot generation:', error);
        process.exit(1);
    } finally {
        if (browser) {
            await browser.close();
        }
    }
})();
EOF

# --- 4. Run Puppeteer script ---
echo ">>> Running Puppeteer to take screenshot..."
# Ensure NODE_PATH is set as puppeteer is installed globally in the container
export NODE_PATH="/usr/local/lib/node_modules:${NODE_PATH:-}"
URL="http://localhost:$PORT"
node screenshot.js "$URL"

# --- 5. Verify screenshot ---
if [ -f "output.png" ] && [ $(stat -c%s "output.png") -gt 1024 ]; then
    echo ">>> Screenshot 'output.png' created successfully."
else
    echo "!!! Error: Screenshot file 'output.png' was not created or is too small." >&2
    exit 1
fi

echo ">>> Screenshot script finished successfully."
