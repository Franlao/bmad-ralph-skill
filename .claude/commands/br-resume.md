---
name: br-resume
description: "Intelligently resume a BMAD-Ralph project from where it left off"
---

# BMAD-Ralph Smart Resume

Resume the project from exactly where it was left off. This is designed for:
- Coming back after closing the terminal
- Starting a new Claude Code session on the same project
- Recovering from a crash or rate limit

## Step 0: Check Working Tree

Before anything, check for uncommitted changes:
```bash
git status --porcelain
```
If there are uncommitted changes:
- Show the user what files are modified
- Ask: "There are uncommitted changes. Should I stash them (`git stash`), commit them, or continue as-is?"
- Wait for confirmation before proceeding

## Step 1: Load State

Read `.bmad-ralph/state.json`. If it doesn't exist, say "No project found. Run `/project:br-init`."

## Step 2: Analyze Current State

Based on the `phase` field:

### If DISCOVER
- Check if any discovery docs already exist in `.bmad-ralph/docs/discovery-*.md`
- If some exist but not all → re-run only the missing ones
- If business-brief.md exists → advance to PLAN

### If PLAN
- Check if `.bmad-ralph/docs/prd.md` exists
- If complete → advance to ARCHITECT
- If incomplete → regenerate

### If ARCHITECT
- Check if `.bmad-ralph/docs/architecture.md` exists
- If complete → advance to SPRINT_PREP
- If incomplete → regenerate

### If SPRINT_PREP
- Check if `.bmad-ralph/sprints/sprint-*.md` files exist
- If complete → advance to EXECUTE
- If incomplete → regenerate missing sprints

### If EXECUTE
This is the most common resume case. Smart detection:

1. Read git log for `feat(sprint-X): STORY-X.Y` commit messages
2. Compare against `.bmad-ralph/sprints/sprint-<current>.md` story list
3. Identify:
   - Completed stories (have commits)
   - Partially implemented stories (files modified but no commit)
   - Pending stories (untouched)
4. Read `.bmad-ralph/logs/sprint-<current>.log` for recent errors

Resume action:
- If partially implemented story → attempt to verify it, commit if passing
- If pending stories remain → continue Ralph loop from next pending story
- If all stories done → advance to REVIEW

### If REVIEW
- Check if review reports exist in `.bmad-ralph/logs/review-sprint-<N>.md`
- If exists → show results and recommended action
- If not → run the review

### If DONE
- Congratulate! Show final stats.

## Step 3: Display Resume Summary

```
BMAD-Ralph Resuming...

  Last phase:    EXECUTE
  Last activity: STORY-2.3 committed successfully

  Sprint 2 progress:
  [x] STORY-2.1 — Database schema setup
  [x] STORY-2.2 — Repository layer
  [x] STORY-2.3 — Auth middleware
  [ ] STORY-2.4 — API routes (NEXT)
  [ ] STORY-2.5 — Frontend integration

  Resuming from STORY-2.4...
```

Then automatically continue the appropriate phase.

## Step 4: Context Reload

Before resuming execution, re-read key files to rebuild context:
1. `.bmad-ralph/docs/architecture.md` (patterns and conventions)
2. Current sprint file (stories and instructions)
3. Last 20 git log entries (recent progress)
4. Sprint log (recent errors to avoid repeating)

This ensures Claude has full context even in a fresh session.
