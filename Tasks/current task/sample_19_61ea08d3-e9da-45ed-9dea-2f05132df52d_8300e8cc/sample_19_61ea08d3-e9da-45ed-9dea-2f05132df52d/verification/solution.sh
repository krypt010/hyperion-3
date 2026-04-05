#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting solution script..."

# 1. Robust file detection
JS_FILE=$(find . -name "section_selector.js" | head -n 1)
API_FILE=$(find . -name "interactive_selector_api.py" | head -n 1)

if [[ -z "$JS_FILE" ]]; then
    log "Error: section_selector.js not found"
    exit 1
fi

if [[ -z "$API_FILE" ]]; then
    log "Error: interactive_selector_api.py not found"
    exit 1
fi

log "Found JS file at: $JS_FILE"
log "Found API file at: $API_FILE"

# 2. Fix frontend event listener and coordinate calculation
log "Applying frontend fixes..."

# Change event listener target from screenshotImage to drawingCanvas
sed -i "s/this.screenshotImage.addEventListener('click'/this.drawingCanvas.addEventListener('click'/g" "$JS_FILE"

# Change bounding client rect calculation to use drawingCanvas
sed -i "s/this.screenshotImage.getBoundingClientRect()/this.drawingCanvas.getBoundingClientRect()/g" "$JS_FILE"

# 3. Fix backend coordinate transformation
log "Applying backend fixes..."

cat <<'EOF' > patch_api.py
import sys
import os

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# We need to transform page-wide coordinates to viewport coordinates before calling elementFromPoint
# We insert the scroll detection and transformation logic into the _async_identify_pdf_link_at_point method

old_snippet = """        element_info = await page.evaluate(js_code, {'x': x, 'y': y})"""

new_snippet = """
        # Coordinate Transformation: Convert full-page Y to viewport-relative Y
        try:
            scroll_info = await page.evaluate('() => ({ y: window.pageYOffset || document.documentElement.scrollTop })')
            viewport_y = y - scroll_info['y']
        except:
            viewport_y = y

        element_info = await page.evaluate(js_code, {'x': x, 'y': viewport_y})"""

if old_snippet in content:
    content = content.replace(old_snippet, new_snippet)
    log_msg = "Patched evaluate call with coordinate transformation."
else:
    log_msg = "Could not find the target evaluate call snippet. The file might already be changed or structure is different."

with open(path, 'w') as f:
    f.write(content)
print(log_msg)
EOF

python3 patch_api.py "$API_FILE"
rm patch_api.py

log "Solution applied successfully."
exit 0
