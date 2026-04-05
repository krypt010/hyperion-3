#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 1. Identify files
VIEWER_FILE=$(find . -name "interactive_selector_viewer.py" | head -n 1)

# 2. Fix Playwright environment
log "Updating Playwright binaries..."
playwright install chromium > /dev/null 2>&1

# 3. Start server
log "Starting server..."
export PYTHONPATH=.
python3 "$VIEWER_FILE" > server.log 2>&1 &
SERVER_PID=$!

cleanup() {
    log "Cleaning up..."
    kill $SERVER_PID || true
}
trap cleanup EXIT

# 4. Wait for server
log "Waiting for server..."
TIMEOUT=30
READY=0
while [ $TIMEOUT -gt 0 ]; do
    if curl -s -I http://127.0.0.1:5000/configure-sections/1 | grep "200 OK" > /dev/null; then
        READY=1
        break
    fi
    sleep 1
    TIMEOUT=$((TIMEOUT-1))
done

if [ $READY -eq 0 ]; then exit 1; fi

# 5. Capture screenshot
log "Capturing screenshot..."
python3 - <<'EOF'
import asyncio
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch(args=['--no-sandbox', '--disable-setuid-sandbox'])
        page = await browser.new_page()
        await page.set_viewport_size({"width": 1280, "height": 800})

        try:
            await page.goto('http://127.0.0.1:5000/configure-sections/1', wait_until='networkidle')
            await page.wait_for_selector('#urlSelect')
            await page.select_option('#urlSelect', 'https://example.com')
            
            await page.wait_for_function("document.getElementById('screenshotImage').src.length > 100", timeout=15000)
            await asyncio.sleep(2)

            # Enter PDF mode
            await page.click('#addPdfLinksBtn')
            await asyncio.sleep(1)

            # In AFTER state, clicking on the drawingCanvas triggers the identify-pdf-link-at-point call
            # And the backend correctly translates the coordinates to find the element
            canvas = await page.query_selector('#drawingCanvas')
            box = await canvas.bounding_box()
            # Click a point likely to have content (e.g. top quadrant)
            await page.mouse.click(box['x'] + box['width']/2, box['y'] + box['height']/4)

            await asyncio.sleep(3)
            await page.screenshot(path='output.png')
        finally:
            await browser.close()

asyncio.run(run())
EOF

if [ -f output.png ] && [ $(stat -c%s output.png) -gt 1024 ]; then
    log "Screenshot captured successfully."
    exit 0
else
    log "Screenshot failed."
    exit 1
fi