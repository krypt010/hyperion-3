# Implementation Plan - Mobile Header Fix

## User Review Required
> [!IMPORTANT]
> - Working in `sample_7` directory as requested.
> - Current verification scripts (`verify/screenshot_before.sh`) are Linux-specific and may fail on Windows.
> - Proposed Solution: Implement fix in `verification/solution.sh`.
> - Validation: Run solution in `node:20-slim` container as per user note.
> - **Assumption**: User has a way to run `screenshot_before.sh` or equivalent, or we will rely on code inspection and manual `docker run` validation.

## Proposed Changes

### [Verification]
#### [NEW] [verification/solution.sh](file:///c:/Users/Label/Documents/Label/Tasks/not%20completed/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/verification/solution.sh)
- Script to apply the fix to `env/index.html` and `env/styles.css`.
- Uses `sed`, `awk`, or `patch` to modify files in place without manual editing.

### [Environment]
#### [MODIFY] [env/index.html](file:///c:/Users/Label/Documents/Label/Tasks/not%20completed/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/env/index.html)
- Add `<div class="mobile-header">` structure.
- Include Logo, Search Icon (emoji), Add Channel (+), and Menu (...).

#### [MODIFY] [env/styles.css](file:///c:/Users/Label/Documents/Label/Tasks/not%20completed/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/sample_7_4baba46f-6b91-44c6-8516-449d2146e0eb/env/styles.css)
- Add CSS for `.mobile-header` (hidden by default).
- Add Media Query `@media (max-width: 768px)` to hide `.header` and show `.mobile-header`.
- Style mobile elements (right alignment, emoji search, etc.).

## Verification Plan

### Automated Tests
1. **Docker Validation**:
   ```bash
   # Start container
   docker run -d --name verify node:20-slim tail -f /dev/null
   # Copy files
   docker cp env/. verify:/app
   # Run solution
   docker exec verify sh solution.sh
   # Verify changes
   docker exec verify cat /app/index.html | grep "mobile-header"
   ```
2. **Visual Verification**:
   - If `screenshot_after.sh` works on host (or via WSL), run it.
   - Otherwise, inspect code changes for correctness against requirements.

### Manual Verification
- Review generated `lossy_patch.txt` to ensure it captures all changes.
