// hubstaff-watcher.mjs
// Connects to the Playwright MCP Chrome browser via CDP and checks the Labelbox
// page every 3 minutes for the Hubstaff timer popup. If found, refreshes the page.
//
// Usage:  node hubstaff-watcher.mjs

import { chromium } from 'playwright';

const CDP_PORT = 61235;
const CHECK_INTERVAL_MS = 3 * 60 * 1000; // 3 minutes
const LABELBOX_URL_PATTERNS = ['app.labelbox.com', 'editor.labelbox.com'];
const EDITOR_FRAME_PATTERN = 'editor.labelbox.com';

async function connectBrowser() {
  try {
    const browser = await chromium.connectOverCDP(`http://127.0.0.1:${CDP_PORT}`);
    console.log(`[HubstaffWatcher] Connected to browser on port ${CDP_PORT}.`);
    return browser;
  } catch (e) {
    console.error(`[HubstaffWatcher] Could not connect on port ${CDP_PORT}.`);
    console.error(e.message);
    process.exit(1);
  }
}

async function findLabelboxPage(browser) {
  const contexts = browser.contexts();
  for (const ctx of contexts) {
    for (const page of ctx.pages()) {
      if (LABELBOX_URL_PATTERNS.some(p => page.url().includes(p))) {
        return page;
      }
    }
  }
  return null;
}

const HUBSTAFF_KEYWORDS = ['hubstaff', 'start timer', 'waiting for user to start'];

function checkDialogInContext(ctx) {
  const dialog = document.querySelector('dialog, [role="dialog"]');
  if (!dialog) return false;
  const text = (dialog.textContent || '').toLowerCase();
  return ['hubstaff', 'start timer', 'waiting for user to start'].some(kw => text.includes(kw));
}

async function checkForHubstaffPopup(page) {
  // Check main page first (handles editor.labelbox.com loaded directly)
  try {
    const hasPopup = await page.evaluate(checkDialogInContext);
    if (hasPopup) return true;
  } catch (e) {
    console.log('[HubstaffWatcher] Error checking main page:', e.message);
  }

  // Also check inside the editor iframe (handles app.labelbox.com with iframe)
  const frames = page.frames();
  const editorFrame = frames.find(f => f.url().includes(EDITOR_FRAME_PATTERN));
  if (!editorFrame) return false;

  try {
    return await editorFrame.evaluate(checkDialogInContext);
  } catch (e) {
    console.log('[HubstaffWatcher] Error checking editor frame:', e.message);
    return false;
  }
}

async function main() {
  const browser = await connectBrowser();

  console.log(`[HubstaffWatcher] Checking every ${CHECK_INTERVAL_MS / 1000}s for Hubstaff popup...`);

  async function check() {
    const timestamp = new Date().toLocaleTimeString();
    const page = await findLabelboxPage(browser);

    if (!page) {
      console.log(`[${timestamp}] No Labelbox tab found.`);
      return;
    }

    const hasPopup = await checkForHubstaffPopup(page);

    if (hasPopup) {
      console.log(`[${timestamp}] Hubstaff popup detected! Refreshing page...`);
      await page.reload({ waitUntil: 'domcontentloaded' });
      console.log(`[${timestamp}] Page refreshed.`);
    } else {
      console.log(`[${timestamp}] No popup. All clear.`);
    }
  }

  // Run immediately, then every 3 minutes
  await check();
  setInterval(check, CHECK_INTERVAL_MS);
}

main();
