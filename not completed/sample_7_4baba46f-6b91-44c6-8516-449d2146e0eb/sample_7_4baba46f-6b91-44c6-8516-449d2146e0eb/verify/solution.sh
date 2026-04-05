#!/bin/bash
set -euo pipefail

echo ">>> Starting solution script to implement a responsive mobile header."

# Define file paths
HTML_FILE="/app/index.html"
CSS_FILE="/app/styles.css"

# Check if files exist
if [ ! -f "$HTML_FILE" ]; then
    echo "!!! Error: index.html not found at $HTML_FILE." >&2
    exit 1
fi
if [ ! -f "$CSS_FILE" ]; then
    echo "!!! Error: styles.css not found at $CSS_FILE." >&2
    exit 1
fi
echo ">>> Files located successfully."

# --- 1. Modify index.html ---
echo ">>> Preparing to insert mobile header HTML into $HTML_FILE."

# Check for idempotency to prevent duplicate insertions
if grep -q 'class="mobile-header"' "$HTML_FILE"; then
    echo "--- Notice: Mobile header already seems to exist. Skipping HTML modification."
else
    # Use awk for a more robust insertion before the wrapper div's comment.
    # This method is safer than complex sed commands and avoids shell quoting issues.
    # The emoji '🔎' is replaced with its HTML entity '&#128269;' to prevent potential encoding problems.
    awk '
      /<!-- Wrapper: Sidebar ve Ana/ && !inserted {
        print "  <!-- Mobile Header -->"
        print "  <div class=\"mobile-header\">"
        print "    <img id=\"mobile-logo-img\" src=\"logo1.png\" alt=\"Logo\" height=\"40\" />"
        print "    <div class=\"mobile-header-right\">"
        print "      <span id=\"mobile-search-icon\" role=\"button\" aria-label=\"Search\">&#128269;</span>"
        print "      <span id=\"mobile-add-channel-button\" role=\"button\" aria-label=\"Add Channel\">+</span>"
        print "      <span id=\"mobile-dots-menu\" role=\"button\" aria-label=\"More options\">...</span>"
        print "    </div>"
        print "  </div>"
        print ""
        inserted=1
      }
      { print }
    ' "$HTML_FILE" > "$HTML_FILE.tmp" && mv "$HTML_FILE.tmp" "$HTML_FILE"
    echo ">>> Mobile header HTML inserted successfully."
fi

# --- 2. Modify styles.css ---
echo ">>> Appending mobile header CSS to $CSS_FILE"

# Check for idempotency using a unique comment from the CSS block
if grep -q "/\* --- Mobile Header Styles --- \*/" "$CSS_FILE"; then
    echo "--- Notice: Mobile header styles seem to exist. Skipping CSS modification."
else
    # Appending with a heredoc is the safest way to add new CSS rules.
    cat <<'EOF' >> "$CSS_FILE"

/* --- Mobile Header Styles --- */
.mobile-header {
  display: none; /* Hidden on desktop by default */
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  height: 45px;
  position: relative;
  gap: 16px;
  box-sizing: border-box;
}

/* Theme support for mobile header */
body.dark-theme .mobile-header {
    background: var(--yt-dark-header);
    color: var(--yt-dark-text);
}

body.light-theme .mobile-header {
    background: var(--yt-light-header);
    color: var(--yt-light-text);
}

.mobile-header #mobile-logo-img {
  height: 55px;
  vertical-align: middle;
  margin-left: 10px;
}

.mobile-header-right {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-right: 10px;
}

.mobile-header-right span {
  font-size: 24px;
  cursor: pointer;
  user-select: none;
}

/* Media query to show mobile header and hide desktop header on small screens */
@media (max-width: 768px) {
  .header {
    display: none !important; /* Force hide the original header */
  }

  .mobile-header {
    display: flex; /* Show the new mobile-friendly header */
  }
}
EOF
    echo ">>> CSS for mobile header appended successfully."
fi

echo ">>> Solution script finished successfully."