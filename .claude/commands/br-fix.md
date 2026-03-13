---
name: br-fix
description: "Auto-fix detected issues — repair state, retry failed stories, clean up"
---

# BMAD-Ralph Auto-Fix

Automatically repair common issues detected by `/project:br-debug`.

If `$ARGUMENTS` is provided:
- "state" → fix only state.json inconsistencies
- "retry STORY-X.Y" → clean up and retry a specific failed story
- "clean" → revert uncommitted changes and reset to last good state
- "rewrite STORY-X.Y" → rewrite a story's instructions based on escalation analysis, then retry
- empty → run full diagnostic first, then fix everything fixable

## Fix Procedures

### Fix 1: State Desync
When state.json doesn't match reality:

1. Read git log for all `feat(sprint-X): STORY-X.Y` commits
2. Build the real list of completed stories
3. Update state.json:
   - `deliverables.implementations` = actual committed stories
   - `metrics.stories_completed` = count of committed stories
   - Correct `current_sprint` based on completed stories
   - Correct `phase` based on what's actually done
4. Log: `[FIX] State resynced with git history`

### Fix 2: Uncommitted Changes (Interrupted Ralph)
When there are uncommitted changes from an interrupted loop:

1. `git status --porcelain` to list changed files
2. Try to identify which story was in progress (match files to story file lists)
3. Run that story's verification command
4. If it passes → commit it as that story
5. If it fails → `git checkout .` to revert, log the failure
6. Log: `[FIX] Interrupted story <X.Y> recovered/reverted`

### Fix 3: Retry a Failed/Escalated Story
When a story was escalated or failed:

1. Read the escalation file for root cause analysis
2. Read the architecture doc for context
3. Check if the root cause is:
   - **Missing dependency** → install it, retry
   - **Wrong file path** → fix the story instructions, retry
   - **Architecture gap** → amend architecture, then retry
   - **Impossible with current stack** → rewrite story, ask user
4. If auto-fixable: apply the fix, re-run the story implementation, verify
5. If not auto-fixable: explain what needs human decision

### Fix 4: Rewrite a Story
When a story's instructions are wrong or incomplete:

1. Read the escalation file
2. Read the architecture doc
3. Read the actual codebase state (what exists now)
4. Rewrite the story in the sprint file with:
   - Updated file paths
   - Updated implementation instructions
   - Added missing context (e.g., new dependencies)
   - Fixed verification command if needed
5. Log: `[FIX] STORY-X.Y rewritten based on escalation analysis`
6. Then retry the story

### Fix 5: Phase Reset
When a phase is stuck or the user wants to redo it:

1. Ask which phase to reset to
2. Update state.json:
   - Set `phase` to the target phase
   - Remove all phases after it from `phases_completed`
   - If resetting to before EXECUTE: clear sprint implementations
3. Log: `[FIX] Phase reset to <phase>`

## After Fixes

1. Run a quick health check (same as br-debug Step 1)
2. Display what was fixed:
   ```
   FIXES APPLIED:
     [x] State resynced: stories_completed 5 → 4
     [x] Uncommitted changes reverted (STORY-1.4 was partial)
     [x] STORY-1.4 rewritten with correct import paths

   REMAINING ISSUES:
     [ ] STORY-1.6 needs architecture amendment (human decision)

   NEXT: Run /project:br-build story STORY-1.4 to retry
   ```
3. Update state.json with fix log
