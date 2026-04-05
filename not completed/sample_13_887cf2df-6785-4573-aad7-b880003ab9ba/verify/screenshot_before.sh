set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

log "Setting up environment for 'before' screenshot..."

# 1. Install Puppeteer
npm install puppeteer --no-save

# 2. Mock missing entry points to avoid 404
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

# 3. Mock Assets and Services
mkdir -p resources/assets
echo '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"></svg>' > resources/assets/add.svg

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

# 4. Start Vite Server
log "Starting Vite server..."
npm run dev -- --host 0.0.0.0 --port 5173 &
SERVER_PID=$!

trap "kill $SERVER_PID || true" EXIT

# Wait for server
TIMEOUT=30
while ! curl -s http://localhost:5173 > /dev/null; do
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
    if [ $TIMEOUT -le 0 ]; then
        log "Timeout waiting for server"
        exit 1
    fi
done

# 5. Capture Screenshot
log "Capturing 'before' screenshot (expecting empty data due to parsing bug)..."
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
    await new Promise(r => setTimeout(r, 2000)); // Extra wait for rendering
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

log "Before script finished."