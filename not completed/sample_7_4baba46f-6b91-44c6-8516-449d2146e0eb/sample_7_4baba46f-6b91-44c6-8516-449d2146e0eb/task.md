# Task Checklist - Verification Loss V2

- [/] Initialize Task Environment <!-- id: 0 -->
    - [x] Set working directory to `not completed/sample 7` folder <!-- id: 1 -->
    - [ ] Verify environment (Docker running) <!-- id: 2 -->
- [ ] Understand Task and Baseline <!-- id: 3 -->
    - [ ] Read `prompt.txt` <!-- id: 4 -->
    - [ ] Run baseline verification (`verify/screenshot_before.sh`) <!-- id: 5 -->
    - [ ] Verify issue is visible in `verification_evidence/output_before.png` <!-- id: 6 -->
- [ ] Implementation <!-- id: 7 -->
    - [ ] Analyze `prompt.txt` and codebase <!-- id: 8 -->
    - [ ] Create `verification/solution.sh` <!-- id: 9 -->
- [ ] Validation <!-- id: 10 -->
    - [ ] Run `verification/solution.sh` <!-- id: 11 -->
    - [ ] Run `verify/screenshot_after.sh` <!-- id: 12 -->
    - [ ] Verify fix is visible in `verification_evidence/output_after.png` <!-- id: 13 -->
- [ ] Final Submission <!-- id: 14 -->
    - [ ] Create `lossy_patch.txt` <!-- id: 15 -->
    - [ ] Ensure all criteria are met <!-- id: 16 -->
