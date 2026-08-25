---
name: br-sprint
description: "BMAD Sprint Prep — Break architecture into hyper-detailed stories for Ralph"
model: opus
---

# BMAD-Ralph Sprint Preparation (Scrum Master Agent)

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `SPRINT_PREP`.

## Mission
You are now the **BMAD Scrum Master**. Your job is CRITICAL: you must break the architecture into stories so detailed that **Ralph Wiggum can implement them autonomously without any human guidance**.

## Input
Read:
- `.bmad-ralph/docs/architecture.md` (especially the Implementation Order and File Dependency Graph)
- `.bmad-ralph/docs/prd.md` (user stories and acceptance criteria)
- `.bmad-ralph/state.json`

## The Golden Rule
> Each story must be a **self-contained, independently testable unit of work** that Ralph can implement in a single loop iteration (typically 1-5 tool calls).

## Story Format

For each story, write:

```markdown
## STORY-<sprint>.<number>: <title>

**Priority**: P0 | P1 | P2
**Depends on**: STORY-X.Y (or "none")
**Estimated Ralph iterations**: <1-5>

### Context
<Brief explanation of what this story is about and where it fits in the architecture>

### Files to Create/Modify
- `<exact file path>` — <what to do: create | modify | test>

### Implementation Instructions
Step-by-step, explicit instructions:
1. <exact action — e.g., "Create file src/db/schema.ts with the Prisma schema from architecture.md section 3.2">
2. <exact action>
3. <exact action>

### Acceptance Criteria
- [ ] <specific, testable criterion>
- [ ] <specific, testable criterion>
- [ ] Tests pass: `<exact test command>`

### Verification Command
```bash
<the exact command(s) Ralph should run to verify this story is complete>
```
The command must be RUNNABLE AS WRITTEN — no placeholders, no "adapt as
needed". It must be able to FAIL: `echo done` or a command that passes on an
empty repo verifies nothing. Prefer the project's real test/build commands
scoped to the story's files.

### Interface Contract (if other stories depend on this one)
<the EXACT exported names/signatures/types this story provides — dependent
stories will import these; if they're not written down, parallel stories
will each invent their own and the merge will break>

### Rollback
If this story trips the circuit breaker (`ralph.circuit_breaker_threshold` failures):
- <what to revert>
- <escalation note for architect>
```

## Sprint Organization

### Sprint Sizing Rules
- **Max 8 stories per sprint** (Ralph works better with focused sprints)
- **Stories within a sprint are ordered by dependency** (independent ones first)
- **Each sprint should produce a testable increment**
- **Sprint 1 is a walking skeleton**: the thinnest end-to-end slice that runs —
  project boots, config loads (`.env.example` from architecture section 7b),
  one trivial route/page/command works, tests and lint run in CI-fashion.
  Every later sprint then builds on something that demonstrably runs, and
  environment problems surface in Sprint 1 instead of poisoning Sprint 3.

### Sprint Structure
Write each sprint to `.bmad-ralph/sprints/sprint-<N>.md`:

```markdown
# Sprint <N>: <theme>

## Goal
<What this sprint delivers as a testable increment>

## Stories
<all stories in dependency order>

## Sprint Verification
After all stories complete, run:
```bash
<comprehensive verification command — build + lint + test, plus every check command
listed in architecture section 8b (Structural Constraints)>
```
The 8b checks belong here, not at the review: a structural constraint verified only at the
quality gate is verified a whole sprint too late, once a dozen stories have already drifted
away from it.

## Sprint Completion Criteria
- [ ] All stories implemented
- [ ] All tests pass
- [ ] No TypeScript/linting errors
- [ ] Git committed with clean history
```

## Parallel Story Detection

Mark stories that have NO dependencies on each other with:
```
**Parallel Group**: A
```

Stories in the same parallel group can be executed simultaneously by Ralph using multiple subagents.

## After Completion

1. Update `.bmad-ralph/state.json`:
   - Set `phase` to `EXECUTE`
   - Add `"SPRINT_PREP"` to `phases_completed`
   - Set `current_sprint` to `1`
   - Set `total_sprints` to the number of sprints created
   - Create one entry per sprint in the `sprints` array — `/br-build`, `/br-review`,
     and `/br-rollback` all read and update these:
     ```json
     { "id": <N>, "theme": "<theme>", "stories_total": <count>,
       "stories_completed": 0, "status": "PENDING", "quality_gate": null,
       "gate_cycles": 0, "defect_classes": [] }
     ```
   - Update `deliverables.sprint_stories` with file paths
   - Set `metrics.stories_total` to the total number of implementation stories
     (this intentionally replaces the PRD user-story count — from here on,
     "stories" means Ralph stories)

2. Present: number of sprints, stories per sprint, estimated total Ralph iterations.

3. Say: "Sprint stories ready. Run `/br-build` to launch Ralph Wiggum autonomous execution for Sprint 1. You can also run `/br-build auto` to run all sprints sequentially."
