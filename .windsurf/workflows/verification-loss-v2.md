---
description: Verification Loss V2 - Perfect Webgen workflow for verifying model loss on samples
---

# Verification Loss V2 - Perfect Webgen

## Goal
Verify that the model actually has a loss when given the prompt and the `prompt.txt` found in the sample folder. Samples have already been worked on by an alignerr using only screenshots of model output.

## Environment Setup
Before beginning, ensure your workstation is configured:
1. **Docker** — Must be running. This project uses a **remote Docker host** since the Windows VM can't run Linux containers natively.
   - **Remote host:** `129.212.180.213` (DigitalOcean Ubuntu 24.04)
   - **DOCKER_HOST:** `tcp://129.212.180.213:2375` (should already be a machine-level env var)
   - Verify env var: `$env:DOCKER_HOST`
   - If empty, set it: `$env:DOCKER_HOST = "tcp://129.212.180.213:2375"`
   - Verify connectivity: `docker info`
   - Make sure Docker context is **"default"** (not "desktop-linux"): `docker context use default`
2. **Antigravity** — Open and authenticated.
3. **Shared Drive** — Ensure you have "Editor" access to the designated Google Drive link provided in the task metadata.

## Key Drive Links
- **Files to analyze:** https://drive.google.com/drive/folders/19UcF4p8lZbcKcbv4zvrm3NZ_lcmAbVpP
- **Submissions:** https://drive.google.com/drive/folders/1JfFFGlXTX6MgrjoOYVxIPsn5uPh0axou
- **Instructions doc:** https://docs.google.com/document/d/1OtpVt7acxgQqwFym6XoNDk2dQ-vfGWct0-WCvcNEKho/edit?tab=t.0#heading=h.7t3x7cadl7fo

## Quick Reference Table (Sample Folder Structure)
| File/Directory | Purpose |
|---|---|
| `env/` | Source code (Read-only for the model) |
| `verification/solution.sh` | Script containing the MODEL's fixes/commands (what we judge) |
| `verify/solution.sh` | Ground-truth fix (reference only) |
| `verification_evidence/` | Destination for baseline and final screenshots |
| `prompt.txt` | The specific task instructions |

## Step-by-Step Workflow

### 1. Preparation
1. Download the sample folder assigned to your current DataRow from the shared Drive. Find the `sample_id` from the `global_key` of the DataRow.
2. Unzip the sample folder.
3. Open the sample folder within the Antigravity interface.

### 2. Docker Initialization (Prompt 1 — use `gemini-3.0-flash`)
Send this first to initialize the container:
```
Initialize docker container. Please don't do anything else, I'll give you new task once the docker container is initialized.
```
Wait for container initialization to complete before proceeding.

### 3. Execution (Prompt 2 — use `gemini-3-pro`)
- **Expected Time Per Label:** 25 minutes.
- **Max Gemini Work Time:** 15 minutes.
- If you run out of quota for `gemini-3-pro`, use `gemini-3.0-flash`. **DO NOT USE ANY OTHER MODEL.**

Input the following prompt into Antigravity:

```
Role: You are a Front-End Web Development Engineer. Task is in prompt.txt, codebase in env/.

Rules:
Never manually edit env/ files—all changes must be written into verification/solution.sh.

All execution happens inside the Docker container.

Do not use user_model_trace.txt during stages 2–3.

Workflow:
1. Baseline: Run verify/screenshot_before.sh in the container → Verify the issue is visible → Copy result to verification_evidence/output_before.png.

2. Implementation: Analyze prompt.txt → Create verification/solution.sh using sed, echo, or patch commands (do not execute yet).

3. Validation: Run solution.sh in the container → Run verify/screenshot_after.sh → Copy result to verification_evidence/output_after.png.

4. create a lossy_patch.txt which is a patch file for all the changes that were made
```

#### Critical Monitoring
- **Refocusing:** If Gemini enters a loop (e.g., repeating the same terminal command or stuck in a logic cycle), intervene immediately to refocus the model.
- **Time Cap:** If the model has not completed the workflow within 15 minutes, stop the process.
- If you run out of quota for `gemini-3-pro`, use `gemini-3.0-flash`. **DO NOT USE ANY OTHER MODEL.**

### 4. Submission
1. Save all changes to the local folder and upload to the Shared Drive (Submissions folder).
2. Clear your Docker environment before the next sample.

## Verified Loss Criteria
Mark the DataRow as **YES (Verified Loss)** if any of the following occur:
- **Task Failure:** The model outputs code/commands that do not resolve the issue described in `prompt.txt`.
- **Timeout:** The model exceeds the 15-minute work limit without finishing.
- **Looping:** The model becomes stuck in a recursive error or logic cycle that cannot be resolved through refocusing.
- **Constraint Violation:** The model manually edits `env/` instead of using `solution.sh`.

## Important Notes & Gotchas
- **Screenshots can be misleading** — mock data may not populate tables. Always do **code-level analysis**.
- **`String.replace()` bugs** — only replaces the first match. Check for duplicate patterns in the source file.
- **File structure distinction:** `verification/solution.sh` = MODEL's solution (what we judge). `verify/solution.sh` = ground-truth fix (reference).
- **Manual Docker verification command sequence:**
  ```
  docker run -d --name verify node:20-slim tail -f /dev/null
  docker cp env/. container:/app
  docker exec sh solution.sh
  # inspect modified files
  # cleanup
  ```
