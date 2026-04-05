set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

log "Setting up environment for 'after' screenshot..."

# 1. Install Puppeteer
npm install puppeteer --no-save

# 2. Ensure infrastructure exists (same as before script)
cat <<EOF > resources/App.tsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import KeywordsPage from './pages/keywords/KeywordsPage';

const App = () => (
  <Router>
    <Routes>
      <Route path="/keywords" element={<KeywordsPage />} />
      <Route path="/" element={<Navigate to="/keywords" />} />
    </Routes>
  </Router>
);
export default App;
EOF

cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head><title>Test App</title></head>
<body>
    <div id="root"></div>
    <script type="module" src="/resources/main.tsx"></script>
</body>
</html>
EOF

mkdir -p resources/assets
echo '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"></svg>' > resources/assets/add.svg

# Keep service mock consistent
cat <<EOF > resources/services/dashboardKeywords.ts
export const getDashboardKeywords = async () => {
  return {
    items: [
      {
        campaignId: "22444727910",
        campaignName: "Competitor Campaign",
        total: 2,
        items: [
          { campaignId: "22444727910", keywordId: "66973447", keywordText: "zillo", adGroupName: "Group 1", spend: 20.88, spendPercent: 68 },
          { campaignId: "22444727910", keywordId: "1366273456", keywordText: "zillow com", adGroupName: "Group 1", spend: 872.14, spendPercent: 74 }
        ]
      }
    ]
  };
};
EOF

# 3. Start Vite Server
log "Starting Vite server..."
npm run dev -- --host 0.0.0.0 --port 5173 &
SERVER_PID=$!

trap "kill $SERVER_PID || true" EXIT

TIMEOUT=30
while ! curl -s http://localhost:5173 > /dev/null; do
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
    if [ $TIMEOUT -le 0 ]; then
        log "Timeout waiting for server"
        exit 1
    fi
done

# 4. Capture Screenshot
log "Capturing 'after' screenshot (expecting fixed campaign grouping)..."
export NODE_PATH=$(npm root)
node <<'EOF'
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ 
    executablePath: '/usr/bin/chromium',
    args: ['--no-sandbox', '--disable-setuid-sandbox'] 
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 1080 });
  try {
    await page.goto('http://localhost:5173/keywords', { waitUntil: 'networkidle0' });
    await new Promise(r => setTimeout(r, 2000));
    await page.screenshot({ path: 'output.png', fullPage: true });
    console.log('Screenshot taken.');
  } catch (err) {
    console.error(err);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
EOF

log "After script finished."