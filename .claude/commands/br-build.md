---
name: br-build
description: "Ralph Wiggum Execution — Autonomous implementation loop with circuit breakers"
---

# BMAD-Ralph Build Phase (Ralph Wiggum Autonomous Loop)

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `EXECUTE`.
Read the current sprint number from `current_sprint`.

## Mode Selection

If `$ARGUMENTS` contains:
- `auto` → Run ALL remaining sprints sequentially (pause between sprints for review)
- `story STORY-X.Y` → Run only a specific story
- `parallel` → Run parallel-group stories simultaneously with subagents
- Nothing → Run the current sprint

## Phase 0: Sprint Branch

1. Read `project.base_branch` from `.bmad-ralph/state.json`
2. Check if branch `bmad/sprint-<current>` exists
3. If **not**: create it from current HEAD:
   ```bash
   git checkout -b bmad/sprint-<current>
   ```
4. If **yes**: switch to it:
   ```bash
   git checkout bmad/sprint-<current>
   ```
5. All story commits happen on this sprint branch

## Phase 1: Load Sprint Context

1. Read `.bmad-ralph/sprints/sprint-<current>.md` for all stories
2. Read `.bmad-ralph/docs/architecture.md` for reference
3. Read git log to detect already-completed stories (by commit message pattern `feat(sprint-X): STORY-X.Y`)
4. Build a TODO list of remaining stories

## Phase 2: Execute Stories (The Ralph Loop)

For EACH story in order:

### Step A — Pre-flight Check
```
Read STORY-X.Y from the sprint file.
Check: are all dependency stories committed? (check git log)
If dependencies not met → skip, will retry later
```

### Step B — Implement
```
Follow the Implementation Instructions step by step.
Create/modify the exact files listed.
Follow the architecture document for patterns and conventions.
```

### Step C — Verify
```
Run the Verification Command from the story.
```

### Step D — Evaluate Result

**If verification PASSES:**
1. Git commit: `git add <files> && git commit -m "feat(sprint-<N>): STORY-<N.M> <title>"`
2. Log success to `.bmad-ralph/logs/sprint-<N>.log`:
   ```
   [<timestamp>] STORY-<N.M> ✓ PASS (iteration <i>)
   ```
3. Update `.bmad-ralph/state.json`:
   - Increment `metrics.stories_completed`
   - Add story ID to `deliverables.implementations`
4. Move to next story

**If verification FAILS:**
1. Read the error output carefully
2. Log the error to `.bmad-ralph/logs/sprint-<N>.log`:
   ```
   [<timestamp>] STORY-<N.M> ✗ FAIL (iteration <i>): <error summary>
   ```
3. **Circuit Breaker Check:**
   - Count how many times this story has failed
   - If < 3 failures → analyze error, fix, retry from Step B
   - If = 3 failures → **ESCALATE** (see Escalation Protocol)

### Step E — Between Stories
After each story (pass or fail), update the state file with current progress.

## Phase 3: Sprint Completion

After all stories attempted:

1. Run the **Sprint Verification** command from the sprint file (full build + lint + test)
2. If ALL pass:
   - Log: `[<timestamp>] SPRINT-<N> ✓ COMPLETE`
   - **Merge sprint branch back to base:**
     ```bash
     git checkout <base_branch>
     git merge bmad/sprint-<N> --no-ff -m "merge: Sprint <N> complete — <sprint theme>"
     ```
   - If merge conflicts → report them and ask the user to resolve manually
   - Update state: increment `current_sprint`, set phase to `REVIEW`
   - Say: "Sprint <N> complete! Run `/project:br-review` for quality gate."
3. If some stories were ESCALATED:
   - Still merge what was completed (partial merge is OK)
   - List the escalated stories
   - Say: "Sprint <N> partially complete. <X> stories escalated. Run `/project:br-review` to assess, or `/project:br-build story STORY-X.Y` to retry specific stories."

## Escalation Protocol

When a story fails 3 times (circuit breaker triggered):

1. Write detailed error analysis to `.bmad-ralph/logs/escalation-STORY-<N.M>.md`:
   ```markdown
   # Escalation: STORY-<N.M>

   ## Story Description
   <from sprint file>

   ## Attempt 1
   - Action taken: <what was implemented>
   - Error: <exact error output>

   ## Attempt 2
   - Action taken: <what was changed>
   - Error: <exact error output>

   ## Attempt 3
   - Action taken: <what was changed>
   - Error: <exact error output>

   ## Root Cause Analysis
   <analysis of why this keeps failing>

   ## Recommendation
   <what needs to change in the architecture or story to make this work>
   ```

2. Update state: increment `metrics.escalations_to_architect`

3. **DO NOT** keep retrying. Move to the next story.

## Parallel Execution Mode

When `$ARGUMENTS` contains `parallel`:

1. Read the sprint file for stories with the same `Parallel Group`
2. Launch one **subagent per parallel group** simultaneously:
   ```
   Agent 1 → stories in Group A (in a worktree)
   Agent 2 → stories in Group B (in a worktree)
   Agent 3 → stories in Group C (in a worktree)
   ```
3. Each subagent follows the same Ralph loop for its stories
4. After all subagents complete → merge worktrees
5. Run Sprint Verification on merged result

## Permissions & Autonomy

**CRITICAL**: All Agent tool calls in this phase MUST use `mode: "bypassPermissions"` so Ralph runs fully autonomously without user prompts. The guard hook (`br-guard.sh`) provides safety — permissions bypass is safe here.

For parallel mode, also set `isolation: "worktree"` on each parallel Agent call:
```
Agent({
  mode: "bypassPermissions",
  isolation: "worktree",
  subagent_type: "general-purpose",
  ...
})
```

## Safety Guardrails

1. **Max iterations per story**: 5 (from state.json `ralph.max_iterations_per_story`)
2. **Circuit breaker**: 3 consecutive failures on same story → escalate
3. **Never modify**: `.bmad-ralph/state.json` structure (only update values), `.env` files, migration files unless explicitly in story
4. **Always commit**: after each successful story — this is your checkpoint
5. **Log everything**: every action, every error, every decision goes to the sprint log
6. **Max total iterations per sprint**: 40 — if reached, pause and report to user
