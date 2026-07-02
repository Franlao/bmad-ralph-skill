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
3. If **not**: create it from the base branch (NOT from wherever HEAD happens to be —
   a leftover checkout would silently base the sprint on the wrong commit):
   ```bash
   git checkout <base_branch> && git checkout -b bmad/sprint-<current>
   ```
4. If **yes**: switch to it:
   ```bash
   git checkout bmad/sprint-<current>
   ```
5. All story commits happen on this sprint branch

## Phase 1: Load Sprint Context

1. Read `.bmad-ralph/sprints/sprint-<current>.md` for all stories
2. Read `.bmad-ralph/docs/architecture.md` for reference
3. Read `.bmad-ralph/docs/prd.md` to understand the intent behind each story
4. Read git log to detect already-completed stories (by commit message pattern `feat(sprint-X): STORY-X.Y`)
5. **Scan the existing codebase** — understand what's already there before writing anything new
6. **Read the dependency manifest** (`package.json`, `cargo.toml`, `pyproject.toml`, etc.) — know what libraries are actually available
7. Build a TODO list of remaining stories using **TodoWrite** — one todo per story, update each as `in_progress` / `completed` in real time

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

Library APIs: your memory is stale by definition. Read the exact installed
version from the lockfile, then look up the docs FOR THAT VERSION before
using any API you're not 100% certain of — context7 MCP if available, else
WebFetch on official docs, else the library's own types/source in
node_modules (ground truth). Framework routers, ORM syntax, and config
formats are the classic silent breakers between majors.

Before writing any helper: Grep the codebase for an existing one.
```

### Step C — Verify
```
1. Run the Verification Command from the story.
2. Run lint and typecheck (detect commands from package.json scripts or project config).
   Fix any errors before moving on — do not skip or suppress.
```

### Step D — Evaluate Result

**If verification PASSES:**
1. **Self-critique before committing** — read your own `git diff` as if reviewing a stranger's PR, against the br-developer Quality Bar: boundaries handled (null/empty/error, input validation)? no N+1, no unbounded fetch-all, no `await`-in-loop on independent calls? resources closed? nothing clever without a requirement? Then ask: Did I implement ALL acceptance criteria? Did I respect the architecture? Did I only touch the files listed in the story (or have a clear reason for any extra files)? If the story has a perf criterion, did I MEASURE it?
2. Git commit: `git add <files> && git commit -m "feat(sprint-<N>): STORY-<N.M> <title>"`
3. Log success to `.bmad-ralph/logs/sprint-<N>.log`:
   ```
   [<timestamp>] STORY-<N.M> ✓ PASS (iteration <i>)
   ```
4. Update `.bmad-ralph/state.json`:
   - Increment `metrics.stories_completed`
   - Add story ID to `deliverables.implementations`
   - Reset `ralph.current_attempt` to 0
5. Move to next story

**If verification FAILS:**
1. **Step back — reason before touching code:**
   - Is the root cause in the code I just wrote?
   - Is it a missing dependency, a wrong import, or a type mismatch?
   - Did I miss reading a file that defines something I'm using?
   - Is this an environment issue (missing env var, missing package) vs a code issue?
2. Read the FULL error output — do not skim
3. Log the error to `.bmad-ralph/logs/sprint-<N>.log`:
   ```
   [<timestamp>] STORY-<N.M> ✗ FAIL (iteration <i>): <error summary>
   ```
4. **Circuit Breaker Check (state file is the source of truth, NOT memory):**
   - Read `ralph.current_story`, `ralph.current_attempt`, and `ralph.circuit_breaker_threshold` from `.bmad-ralph/state.json` — the threshold is configurable via `/br-config circuit-breaker <N>`, never hardcode it
   - If `ralph.current_story` ≠ this story ID → set it to this story and set `ralph.current_attempt` to 0
   - Increment `ralph.current_attempt` and write it back to the state file
   - Never count failures from conversation memory — after context compaction the count would be lost; the state file survives
   - If `ralph.current_attempt` < `circuit_breaker_threshold` → fix the root cause (not a patch), retry from Step B
   - If `ralph.current_attempt` ≥ `circuit_breaker_threshold` → **ESCALATE** (see Escalation Protocol), then reset `ralph.current_attempt` to 0
   - Hard cap: if total attempts on this story reach `ralph.max_iterations_per_story`, escalate regardless (this cap only matters when the user raises the circuit breaker above it)

### Step E — Between Stories
After each story (pass or fail), update the state file:
- Increment `ralph.total_iterations` and `metrics.ralph_iterations_total` by the number of implement+verify cycles this story took (these counters feed `/br-status` and `/br-metrics` — if you skip this, the dashboards show 0 forever)
- Update this sprint's entry in the `sprints` array: `stories_completed`, and `status: "IN_PROGRESS"` if not already
- Update `last_updated_at`
- If `ralph.total_iterations` gained more than `ralph.max_iterations_per_sprint` during this sprint → pause and report to the user

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
   - Update state: set phase to `REVIEW`, set this sprint's entry to `status: "COMPLETE"`
   - **Do NOT increment `current_sprint` here** — the review reads `sprint-<current>` to know what to review, and `/br-review` increments it after the quality gate PASSES. Incrementing in both places made the review analyze the wrong sprint and skip one entirely.
   - Say: "Sprint <N> complete! Run `/br-review` for quality gate."
3. If some stories were ESCALATED:
   - Still merge what was completed (partial merge is OK)
   - List the escalated stories
   - Say: "Sprint <N> partially complete. <X> stories escalated. Run `/br-review` to assess, or `/br-build story STORY-X.Y` to retry specific stories."

## Escalation Protocol

When a story fails `circuit_breaker_threshold` times (circuit breaker triggered):

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
2. Launch one **subagent per parallel group** simultaneously — always use the
   `br-developer` agent (it carries the Ralph protocol, quality rules, and
   `permissionMode: bypassPermissions` in its definition), with worktree isolation:
   ```
   Agent({
     subagent_type: "br-developer",
     isolation: "worktree",
     prompt: "<sprint file path> + <story IDs for this group> + <architecture doc path>"
   })
   ```
   Send all group launches in ONE message so they run concurrently.
3. Each subagent follows the same Ralph loop for its stories and reports back:
   its worktree branch name, completed story IDs, and any escalations
4. After all subagents complete, merge each worktree branch into the sprint
   branch **sequentially** (one at a time, so conflicts surface against an
   up-to-date base):
   ```bash
   git checkout bmad/sprint-<N>
   git merge <worktree-branch-1> --no-ff
   git merge <worktree-branch-2> --no-ff
   ```
   If a merge conflicts → resolve it yourself when the resolution is obvious
   (imports, adjacent additions); otherwise report and ask the user
5. Run Sprint Verification on the merged result — parallel groups were verified
   in isolation, so integration failures show up HERE; treat a failure like a
   story failure (root-cause it, fix on the sprint branch)

## Permissions & Autonomy

Autonomy comes from the **agent definitions**, not from per-call parameters: the
Agent tool has no `mode`/`bypassPermissions` argument. `br-developer` declares
`permissionMode: bypassPermissions` in its frontmatter, so any work delegated to
it runs without user prompts. Always delegate implementation work to
`br-developer` (never `general-purpose`, which would prompt for permissions and
lacks the Ralph protocol).

The guard hook (`br-guard.sh`) is a best-effort safety net that blocks common
destructive operations (recursive deletes on broad targets, force pushes, hard
resets, piping remote scripts into a shell, ...). It is NOT a sandbox — treat it
as the last line of defense, not a license to run anything.

## Safety Guardrails

All limits come from `state.json` (`ralph.*`) — they are user-configurable via `/br-config`, so read them, never assume the defaults:

1. **Circuit breaker** (`circuit_breaker_threshold`, default 3): consecutive failures on the same story → escalate. This is the limit that normally fires.
2. **Max iterations per story** (`max_iterations_per_story`, default 5): hard cap on implement+verify cycles for one story — a backstop in case the circuit breaker is configured above it.
3. **Max total iterations per sprint** (`max_iterations_per_sprint`, default 40): if reached, pause and report to user.
4. **Never modify**: `.bmad-ralph/state.json` structure (only update values), `.env` files, migration files unless explicitly in story
5. **Always commit**: after each successful story — this is your checkpoint
6. **Log everything**: every action, every error, every decision goes to the sprint log
