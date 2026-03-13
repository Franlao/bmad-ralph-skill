---
name: br-rollback
description: "Rollback a sprint or story — git revert + state update, safe and traceable"
---

# BMAD-Ralph Rollback

Safely rollback stories or sprints using `git revert` (never `git reset --hard`).

## Arguments

- `$ARGUMENTS` = `story STORY-X.Y` → revert a specific story
- `$ARGUMENTS` = `sprint N` → revert all stories from sprint N
- `$ARGUMENTS` = `last` → revert the most recently completed story
- `$ARGUMENTS` empty → show what can be rolled back

## Pre-check

Read `.bmad-ralph/state.json`. If phase is before `EXECUTE`, say "Nothing to rollback yet."

## Show Rollback Options (no arguments)

List all completed stories with their commit hashes:

```bash
git log --oneline --grep="feat(sprint-"
```

Display:
```
AVAILABLE ROLLBACKS
─────────────────────────────────
  [1] STORY-2.5 "Frontend integration"     (latest)
  [2] STORY-2.4 "API routes"
  [3] STORY-2.3 "Auth middleware"
  ... (all completed stories)

  [sprint 2] Rollback entire Sprint 2 (5 stories)
  [sprint 1] Rollback entire Sprint 1 (6 stories)

Usage:
  /project:br-rollback last
  /project:br-rollback story STORY-2.3
  /project:br-rollback sprint 2
```

## Story Rollback

1. Find the commit matching `feat(sprint-N): STORY-X.Y` in git log
2. Show what will be reverted (files changed):
   ```bash
   git show --stat <commit-hash>
   ```
3. **Ask the user to confirm** before proceeding
4. Revert the commit:
   ```bash
   git revert <commit-hash> --no-edit
   ```
5. Update `.bmad-ralph/state.json`:
   - Remove story ID from `deliverables.implementations`
   - Decrement `metrics.stories_completed`
   - Update the sprint's `stories_completed` count
   - If this was the last story of a completed sprint, set sprint status back to `IN_PROGRESS`
6. Log to `.bmad-ralph/logs/sprint-<N>.log`:
   ```
   [<timestamp>] ROLLBACK: STORY-X.Y reverted
   ```
7. Display:
   ```
   ROLLBACK COMPLETE
   ─────────────────────────────────
   Reverted: STORY-X.Y "<title>"
   Commit:   <hash> → reverted by <new-hash>
   Files:    3 files restored

   The story is now available for re-execution.
   Run /project:br-build story STORY-X.Y to re-implement it.
   ```

## Sprint Rollback

1. Find ALL commits matching `feat(sprint-N): STORY-N.*` in git log
2. Show summary of all stories and files that will be reverted
3. **Ask the user to confirm** before proceeding
4. Revert commits in **reverse chronological order** (most recent first):
   ```bash
   git revert <hash-5> --no-edit
   git revert <hash-4> --no-edit
   git revert <hash-3> --no-edit
   ...
   ```
5. Update `.bmad-ralph/state.json`:
   - Remove all sprint N story IDs from `deliverables.implementations`
   - Reset sprint status to `PENDING`
   - Set `current_sprint` to N
   - Set `phase` to `EXECUTE`
   - Adjust `metrics.stories_completed`
6. If a `bmad/sprint-N` branch exists, note it but don't delete it
7. Display summary with count of reverted stories and files

## Safety Rules

1. **NEVER use `git reset --hard`** — always `git revert` for traceability
2. **ALWAYS confirm with the user** before reverting
3. **NEVER rollback past already-reviewed sprints** without warning that the review is now invalid
4. If there are uncommitted changes, warn and ask to stash first
5. After rollback, the reverted stories become available for re-execution
