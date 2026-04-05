// kill-hubstaff-popup.js
// Paste this into the browser console on the Labelbox page.
// It checks every 3 minutes for a Hubstaff timer popup.
// If found, it refreshes the page to dismiss it.

(function () {
  if (window.__hubstaffKillerActive) {
    console.log('[HubstaffKiller] Already running.');
    return;
  }
  window.__hubstaffKillerActive = true;

  const SELECTORS = [
    '[class*="dialog"]', '[class*="Dialog"]',
    '[class*="modal"]', '[class*="Modal"]',
    '[class*="overlay"]', '[class*="Overlay"]',
    '[role="dialog"]', '[role="alertdialog"]',
    '[class*="hubstaff"]', '[class*="Hubstaff"]',
    '[class*="timer-dialog"]', '[class*="TimerDialog"]',
    '[class*="backdrop"]', '[class*="Backdrop"]',
  ];

  const KEYWORDS = ['hubstaff', 'timer', 'tracking', 'start timer', 'time track'];

  function isHubstaffPopup(el) {
    const text = (el.textContent || '').toLowerCase();
    return KEYWORDS.some(kw => text.includes(kw));
  }

  function checkAndRefresh() {
    for (const sel of SELECTORS) {
      for (const el of document.querySelectorAll(sel)) {
        if (isHubstaffPopup(el)) {
          console.log('[HubstaffKiller] Hubstaff popup detected — refreshing page...');
          location.reload();
          return;
        }
      }
    }
  }

  // Run immediately
  checkAndRefresh();

  // Check every 3 minutes
  setInterval(checkAndRefresh, 3 * 60 * 1000);

  console.log('[HubstaffKiller] Active! Checking every 3 min — will refresh if popup found.');
})();
