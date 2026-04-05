#!/bin/bash
set -euo pipefail

# --- Configuration ---
PORT=3000
URL="http://localhost:${PORT}/admin/review-queue"

# --- Cleanup Function ---
cleanup() {
    echo "Cleaning up..."
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
    if [ -f "src/hooks/use-user-data.tsx.bak" ]; then
        mv src/hooks/use-user-data.tsx.bak src/hooks/use-user-data.tsx
    fi
    if [ -f "next.config.js" ] && [ -f "next.config.ts.bak" ]; then
        mv next.config.ts.bak next.config.ts
    fi
    rm -f screenshot.js dev.log
}
trap cleanup EXIT

# --- Script Start ---
echo "Starting screenshot_before.sh script."

# 1. FIX: Rename next.config.ts to next.config.js to allow server to start
if [ -f "next.config.ts" ]; then
    echo "Renaming next.config.ts to next.config.js to support the Next.js dev server."
    cp next.config.ts next.config.ts.bak # create a backup for cleanup
    mv next.config.ts next.config.js
fi

# 2. Backup original hook file before overwriting
echo "Backing up original user-data hook..."
cp src/hooks/use-user-data.tsx src/hooks/use-user-data.tsx.bak

# 3. Create mock data hook that fixes the compilation error for the 'before' state
echo "Creating mock data for useUserData hook to allow compilation..."
cat > src/hooks/use-user-data.tsx <<'EOF'
'use client';
import { createContext, useContext } from 'react';

export interface ReviewQueueItem {
    id: string;
    company_id: string;
    user_email: string;
    type: string;
    status: 'pending' | 'approved' | 'rejected' | 'withdrawn' | 'reviewed';
    created_at: string;
    reviewed_at?: string;
    reviewer_id?: string;
    change_details: any;
    original_change_details?: any; // <-- FIX: Add optional property to solve TS error
    rejection_reason?: string;
}
export type MasterTask = any;
export type MasterTip = any;

export const useUserData = () => {
  return {
    reviewQueue: [
        {
            id: '1',
            company_id: 'comp-1',
            user_email: 'hr@example.com',
            type: 'question_edit_suggestion',
            status: 'pending',
            created_at: '2025-09-01T10:00:00.000Z',
            original_change_details: null,
            change_details: {
                questionId: 'q1',
                questionLabel: 'What is your preferred work location?',
                optionsToAdd: [{ option: 'Remote', guidance: 'Fully remote work is allowed.' }],
                optionsToRemove: ['In-Office'],
                guidanceOverrides: {},
            },
        },
        {
            id: '2',
            company_id: 'comp-1',
            user_email: 'hr@example.com',
            type: 'question_edit_suggestion',
            status: 'approved',
            created_at: '2025-08-15T14:30:00.000Z',
            reviewed_at: '2025-08-16T09:00:00.000Z',
            reviewer_id: 'admin-1',
            change_details: {
                questionId: 'q2',
                questionLabel: 'What department are you in?',
                optionsToAdd: [{ option: 'AI Research' }],
                optionsToRemove: [],
                guidanceOverrides: {},
            },
        },
    ],
    masterQuestions: {
        q1: { id: 'q1', label: 'What is your preferred work location?', section: 'General', type: 'radio', options: ['Hybrid', 'In-Office'] },
        q2: { id: 'q2', label: 'What department are you in?', section: 'General', type: 'radio', options: ['Engineering', 'Sales', 'Marketing'] },
    },
    masterProfileQuestions: {},
    platformUsers: [
        { id: 'admin-1', email: 'admin@platform.com', role: 'admin' },
    ],
    companyAssignmentForHr: {
         companyId: 'comp-1',
         companyName: 'Test Inc.',
         hrManagers: [],
         version: 'pro',
         maxUsers: 100,
    },
    updateReviewQueueItemStatus: () => console.log('Withdraw clicked'),
  };
};
EOF

# 4. Install Puppeteer
echo "Installing Puppeteer..."
npm list puppeteer &>/dev/null || npm install puppeteer

# 5. Create Puppeteer screenshot script
echo "Creating screenshot.js..."
cat > screenshot.js <<'EOF'
const puppeteer = require('puppeteer');
(async () => {
    const url = process.argv[2];
    if (!url) {
        console.error('URL argument is missing!');
        process.exit(1);
    }
    console.log(`Navigating to ${url}...`);
    let browser;
    try {
        browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'] });
        const page = await browser.newPage();
        await page.setViewport({ width: 1280, height: 720 });
        await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
        console.log('Waiting for content to render...');
        await page.waitForSelector('h1', { timeout: 15000 });
        await page.waitForSelector('table', { timeout: 15000 });
        await new Promise(resolve => setTimeout(resolve, 2000));
        console.log('Taking screenshot...');
        await page.screenshot({ path: 'output.png', fullPage: true });
        console.log('Screenshot saved to output.png');
    } catch (err) {
        console.error('Puppeteer script failed:', err);
        process.exit(1);
    } finally {
        if (browser) { await browser.close(); }
    }
})();
EOF

# 6. Start the server, logging errors for debugging
echo "Starting Next.js development server..."
npm run dev >dev.log 2>&1 &
SERVER_PID=$!

# 7. Wait for the server to be ready by checking the target URL
echo "Waiting for server to respond at ${URL}..."
TIMEOUT=90
ELAPSED=0
# FIX: Wait for ANY response from the server, not just 200 OK. This handles slow compile times.
while ! curl --silent --output /dev/null --head "$URL"; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Error: Server failed to start or is not responding at ${URL} within ${TIMEOUT} seconds." >&2
        echo "--- Server Log (dev.log) ---"
        cat dev.log
        echo "--------------------------"
        exit 1
    fi
done
echo "Server is ready."

# 8. Run the screenshot script
node screenshot.js "$URL"

# 9. Validate the output
if [ -f "output.png" ] && [ "$(stat -c%s output.png)" -gt 1024 ]; then
    echo "Screenshot 'output.png' created successfully."
else
    echo "Error: Screenshot generation failed or file is too small." >&2
    exit 1
fi

exit 0
