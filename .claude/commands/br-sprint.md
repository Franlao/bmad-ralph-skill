---
name: br-sprint
description: "BMAD Sprint Prep — Break architecture into hyper-detailed stories for Ralph"
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

### Rollback
If this story fails after 3 attempts:
- <what to revert>
- <escalation note for architect>
```

## Sprint Organization

### Sprint Sizing Rules
- **Max 8 stories per sprint** (Ralph works better with focused sprints)
- **Stories within a sprint are ordered by dependency** (independent ones first)
- **Each sprint should produce a testable increment**

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
<comprehensive verification command — build + lint + test>
```

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

## Ralph Prompt Generation

For EACH sprint, also generate `.bmad-ralph/prompts/ralph-sprint-<N>.md`:

```markdown
# Ralph Prompt — Sprint <N>

## Your Mission
You are implementing Sprint <N> of the <project_name> project.
Read `.bmad-ralph/sprints/sprint-<N>.md` for the full story list.

## Permissions
All Agent tool calls use `mode: "bypassPermissions"` — you run fully autonomously.

## Rules
1. Implement stories IN ORDER (respect dependencies)
2. For each story:
   a. Read the story instructions carefully
   b. Implement exactly as specified
   c. Run the verification command
   d. If verification passes → git commit with message "feat(sprint-<N>): STORY-<N.M> <title>"
   e. If verification fails → read the error, fix it, retry (max 3 times per story)
3. If a story fails 3 times → write "ESCALATE: STORY-<N.M>" and move to the next story
4. After ALL stories → run the Sprint Verification command
5. When sprint is fully complete and verified → write "SPRINT_<N>_COMPLETE"

## Progress Tracking
Check git log to see which stories are already committed.
Skip stories that already have a commit message matching their ID.

## Current Project State
- Tech stack: <from state.json>
- Architecture: read .bmad-ralph/docs/architecture.md
- Previous sprints: <list of completed sprints>
```

## After Completion

1. Update `.bmad-ralph/state.json`:
   - Set `phase` to `EXECUTE`
   - Add `"SPRINT_PREP"` to `phases_completed`
   - Set `current_sprint` to `1`
   - Set `total_sprints` to the number of sprints created
   - Update `deliverables.sprint_stories` with file paths
   - Update `metrics.stories_total`

2. Present: number of sprints, stories per sprint, estimated total Ralph iterations.

3. Say: "Sprint stories ready. Run `/project:br-build` to launch Ralph Wiggum autonomous execution for Sprint 1. You can also run `/project:br-build auto` to run all sprints sequentially."
