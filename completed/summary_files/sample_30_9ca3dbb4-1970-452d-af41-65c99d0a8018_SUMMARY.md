# Summary: sample_30_9ca3dbb4-1970-452d-af41-65c99d0a8018

## Identity
- **Sample Number:** 30
- **UUID:** 9ca3dbb4-1970-452d-af41-65c99d0a8018
- **Language:** ja
- **Status:** Completed

## Tech Stack
- **Has Dockerfile:** True
- **Has package.json:** True
- **Detected Stack:** N/A
- **Env Files Count:** 4398

## Prompt
### Original Prompt
å—é¨“é«˜æ ¡:ã€€ã§é¸ã°ã‚ŒãŸå­¦æ ¡ã®ãƒœã‚¿ãƒ³ã‚’è‡ªå‹•ã§é¸æŠžã—ã€ãã‚Œä»¥å¤–ã®ãƒœã‚¿ãƒ³ãŒé¸æŠžå‡ºæ¥ãªã„ã‚ˆã†ã«ã—ã¦ã€‚

### Generated Prompt
In the student information form, there is a dropdown menu for 'Exam High School' (`#studentHighSchool`). Below the form, there is a grid of buttons representing various schools (`.school-btn`). 

Your task is to implement interaction logic in `app.js` so that:
1. When a user selects a specific school from the dropdown, the corresponding button in the school list is automatically 'clicked' (to trigger its existing display logic for sub-categories or question generation) and visually highlighted.
2. When a school is selected via the dropdown, all other school buttons in the list should be disabled (`disabled = true`) so that the user is forced to follow the path associated with their chosen high school.
3. If the dropdown selection is changed, the previously selected button should reset, and the new corresponding button should be enabled and clicked, while all others remain disabled.

Ensure that the 'selected' CSS class is correctly applied to the active button and that the `disabled` state is handled appropriately for all other buttons to provide clear visual feedback.

### Translated Prompt
Automatically select the button for the school chosen in 'Entrance Exam High School' and make it so that other buttons cannot be selected.

## Evaluation Rubrics (4 criteria)
The button corresponding to the school specified in the 'å—é¨“é«˜æ ¡' (Exam High School) data must be automatically highlighted or marked as selected.
All school buttons other than the one matching the 'å—é¨“é«˜æ ¡' must be disabled and non-interactive.
The disabled buttons must have a visual style indicating they are inactive (e.g., greyed out or reduced opacity).
The user should be unable to manually change the selection of the school buttons on this view.

## Patch Info
- **Has Lossy Patch:** True
- **Files Touched:** env/app.js	2026-02-20 17:48:10.047745900 +0000, env/app.js.orig	2026-02-20 17:43:14.091834400 +0000

## Verification
- **Has Verification Evidence:** True
