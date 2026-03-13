---
name: br-debug
description: "Diagnose BMAD-Ralph issues — find what went wrong, where, and why"
---

# BMAD-Ralph Debug & Diagnostic Tool

This command analyzes the entire project state to find problems.

If `$ARGUMENTS` is provided, focus on that specific area:
- `$ARGUMENTS` = "story STORY-X.Y" → debug a specific story
- `$ARGUMENTS` = "sprint" → debug current sprint
- `$ARGUMENTS` = "phase" → debug current phase
- `$ARGUMENTS` = "all" or empty → full diagnostic

## Step 1: Health Check

Read `.bmad-ralph/state.json` and verify:

```
HEALTH CHECK
─────────────────────────────────────────────
[PASS/FAIL] state.json exists and is valid JSON
[PASS/FAIL] phase is a valid phase name
[PASS/FAIL] current_sprint <= total_sprints
[PASS/FAIL] stories_completed <= stories_total
[PASS/FAIL] All deliverable files actually exist on disk
[PASS/FAIL] Sprint files exist for all declared sprints
[PASS/FAIL] Git repo is clean (no uncommitted changes from failed story)
─────────────────────────────────────────────
```

For each check, use Glob/Read/Bash to verify the file exists and is valid.

## Step 2: Log Analysis

Read all log files in `.bmad-ralph/logs/`:

### Sprint Logs
For each `sprint-<N>.log`:
- Count PASS vs FAIL entries
- Find the LAST entry (most recent action)
- List all FAIL entries with their error summaries
- Detect patterns: same error repeated? same file failing?

### Escalation Files
For each `escalation-STORY-*.md`:
- Show the story that was escalated
- Show the root cause analysis
- Show the recommendation

### Review Reports
For each `review-sprint-*.md`:
- Show the overall score
- List critical issues
- Show the quality gate decision

## Step 3: Git State Analysis

```bash
# Check for uncommitted changes (sign of interrupted Ralph loop)
git status --porcelain

# Check last 10 commits for sprint pattern
git log --oneline -10

# Check if there are files modified but not committed
git diff --stat
```

Analyze:
- Are there uncommitted changes? → Ralph was interrupted mid-story
- Do commit messages follow the pattern? → Any missing stories?
- Is the git state consistent with state.json? → Detect desync

## Step 4: Consistency Check

Cross-reference:
1. **state.json `implementations`** vs **git log commits** → Find stories that state says are done but have no commit (or vice versa)
2. **Sprint file stories** vs **implemented stories** → Find stories that were skipped
3. **Architecture file paths** vs **actual file system** → Find missing or extra files
4. **state.json phase** vs **actual progress** → Detect if phase is stuck or wrong

## Step 5: Display Diagnostic Report

```
╔═══════════════════════════════════════════════════════════╗
║              BMAD-RALPH DIAGNOSTIC REPORT                 ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  HEALTH:  3/7 checks passed                               ║
║                                                           ║
║  PROBLEMS FOUND:                                          ║
║                                                           ║
║  1. [CRITICAL] Uncommitted changes detected               ║
║     → Ralph was interrupted during STORY-1.4              ║
║     → Files changed: src/routes/notes.ts, src/app.ts      ║
║     → Fix: run /project:br-build story STORY-1.4          ║
║              or git checkout . to revert                   ║
║                                                           ║
║  2. [WARNING] state.json says 5 stories done,             ║
║     but git log shows only 4 commits                      ║
║     → STORY-1.3 may have been counted but not committed   ║
║     → Fix: verify STORY-1.3 manually, then re-run         ║
║                                                           ║
║  3. [INFO] 2 escalation files found                       ║
║     → STORY-1.4: "WebSocket handler"                      ║
║       Root cause: missing dependency ws                    ║
║     → STORY-1.6: "Auth middleware"                         ║
║       Root cause: architecture missing JWT secret config   ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  SUGGESTED FIXES:                                         ║
║                                                           ║
║  1. /project:br-build story STORY-1.4                     ║
║  2. /project:br-fix (auto-fix detected issues)            ║
║  3. Edit .bmad-ralph/docs/architecture.md to add           ║
║     JWT_SECRET to config section                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

## Step 6: If debugging a specific story

When `$ARGUMENTS` = "story STORY-X.Y":

1. Read the story from the sprint file
2. Read the sprint log for all entries about this story
3. Read the escalation file if it exists
4. Check if the story's files exist on disk
5. Run the story's verification command
6. Report:
   - Story status (implemented/partial/failed/not started)
   - Verification result (pass/fail + exact error)
   - Previous attempts and errors
   - Suggested fix

## Step 7: Auto-Fix Offer

After the diagnostic, if there are fixable issues, offer:

```
Auto-fixable issues found:

  1. Reset state.json stories_completed to match git log (4 → 4)
  2. Clean uncommitted changes and retry STORY-1.4
  3. Re-run verification on STORY-1.3 and commit if passing

Run /project:br-fix to apply all auto-fixes, or fix manually.
```
