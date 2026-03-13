---
name: br-auto
description: "Run all BMAD planning phases automatically, then pause before Ralph execution"
---

# BMAD-Ralph Auto Mode — Full Pipeline

Run ALL BMAD planning phases automatically with **zero human intervention**, then pause before launching Ralph execution.

**IMPORTANT**: Use `mode: "bypassPermissions"` on ALL Agent tool calls throughout this pipeline. The user should NOT need to approve anything — the guard hook provides safety.

If `$ARGUMENTS` is provided, use it as the project description for initialization.

## The Pipeline

Execute these phases in sequence. After each phase, briefly show the key output (3-5 lines summary), then immediately proceed to the next.

### Phase 1: Init (if not already initialized)
If `.bmad-ralph/state.json` doesn't exist:
- Run the br-init flow with `$ARGUMENTS` as the project description
- Auto-detect everything possible (stack, conventions, patterns)
- Use sensible defaults — don't ask questions unless critical info is missing

### Phase 2: Discovery
- Launch 4 parallel research subagents (market, competitive, technical, codebase)
- Wait for all to complete
- Synthesize into business brief
- **Show**: 3-line summary of key findings
- Proceed immediately

### Phase 3: Planning (PRD)
- Generate full PRD from business brief
- **Show**: Feature count, story count by priority, sprint estimate
- Proceed immediately

### Phase 4: Architecture
- Design complete architecture from PRD
- **Show**: Tech stack chosen, key files to create, data model entities
- Proceed immediately

### Phase 5: Sprint Preparation
- Break architecture into sprint stories
- Generate Ralph prompts for each sprint
- **Show**: Number of sprints, stories per sprint, parallel groups

### STOP HERE — Human Checkpoint

Display:

```
═══════════════════════════════════════════════════
  BMAD PLANNING COMPLETE — READY FOR RALPH BUILD
═══════════════════════════════════════════════════

  Deliverables created:
  [x] Business Brief    .bmad-ralph/docs/business-brief.md
  [x] PRD               .bmad-ralph/docs/prd.md
  [x] Architecture      .bmad-ralph/docs/architecture.md
  [x] Sprint Stories    .bmad-ralph/sprints/

  Sprint Plan:
  - <N> sprints with <M> total stories
  - Estimated Ralph iterations: <X>

  Review the deliverables above before launching Ralph.

  When ready:
  /project:br-build           → Run Sprint 1
  /project:br-build auto      → Run ALL sprints sequentially
  /project:br-build parallel  → Use parallel subagents

═══════════════════════════════════════════════════
```

## Error Handling

If any phase fails:
1. Log the error
2. Show what went wrong
3. Suggest: "Run `/project:br-status` to see where we are, then retry the failed phase manually"
4. Do NOT proceed to the next phase
