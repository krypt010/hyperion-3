#!/bin/bash
set -euo pipefail

# Change to the project root directory
cd "$(dirname "$0")/.."

# --- Modify index.html ---
# We use a temporary Python script to handle multi-line string replacement reliably.
cat <<EOF > modify_html.py
import sys
import os

file_path = 'env/index.html'
if not os.path.exists(file_path):
    print(f"Error: {file_path} not found")
    sys.exit(1)

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# exact formatting based on view_file output
target_block = '''  <div class="header">
    <img id="logo-img" src="logo1.png" alt="Logo" height="40" />
    <form id="search-formi" class="search-form" aria-label="Canlı yayın arama formu" style="margin-right:16px;">
      <input type="text" id="search-input" placeholder="Kanal adıyla canlı yayın ara..." />
      <button type="submit">Ara</button>
    </form>
  </div>'''

replacement_block = '''  <div class="header">
    <img id="logo-img" src="logo1.png" alt="Logo" height="40" />
    <div class="header-right">
      <form id="search-formi" class="search-form" aria-label="Canlı yayın arama formu">
        <input type="text" id="search-input" placeholder="Kanal adıyla canlı yayın ara..." />
        <button type="submit">Ara</button>
      </form>
      <button id="add-channel-btn" class="extra-btn" title="Add Channel">+</button>
      <button id="menu-btn" class="extra-btn" title="Menu">⋮</button>
    </div>
  </div>'''

if target_block in content:
    new_content = content.replace(target_block, replacement_block)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully modified index.html")
else:
    # Fallback: try whitespace-insensitive matching if exact match fails
    # This is a basic normalize but usually 'target_block' copy-pasted from view_file works best.
    print("Warning: Exact target block match failed. Attempting flexible replacement...")
    # For now, let's fail to avoid corrupting if we are unsure. 
    # The view_file output is our source of truth.
    print("Target block not found in index.html. Exiting.")
    sys.exit(1)
EOF

python3 modify_html.py
rm modify_html.py

# --- Modify styles.css ---
# Append the new mobile styles to the end of the file.
cat <<EOF >> env/styles.css

/* --- Mobile Top Bar Fixes --- */

/* Wrapper for right-aligned items */
.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Extra buttons (Add Channel, Menu) default styling */
.extra-btn {
  background: none;
  border: none;
  font-size: 24px;
  line-height: 1;
  padding: 4px 8px;
  cursor: pointer;
  color: inherit; /* inherit from header color */
}

/* Mobile responsive styles */
@media (max-width: 600px) {
  .header {
    justify-content: space-between !important;
    padding-left: 10px;
    padding-right: 10px;
  }
  
  /* Ensure header right section is pushed to end */
  .header-right {
    margin-left: auto;
    gap: 8px; /* Slightly tighter gap on mobile */
  }

  /* Search Bar Transformation */
  #search-formi {
    margin-right: 0 !important;
  }
  
  /* Hide the text input on mobile */
  #search-input {
    display: none !important;
  }
  
  /* Transform the search button */
  #search-formi button {
    background: transparent !important;
    border: none !important;
    padding: 0 4px !important;
    font-size: 0 !important; /* Hide original text "Ara" */
    width: auto !important;
    margin: 0 !important;
    color: inherit !important;
  }
  
  /* Inject Magnifying Glass Emoji */
  #search-formi button::after {
    content: '🔍';
    font-size: 22px;
    display: inline-block;
    visibility: visible;
  }

  /* Ensure extra buttons are visible and sized correctly */
  .extra-btn {
    display: block;
    font-size: 26px; /* Make them easily tappable and visible */
  }
  
  /* Adjust specific button weights/styles */
  #add-channel-btn {
    font-weight: 400; 
  }
}
EOF

echo "Applied changes to index.html and styles.css"
