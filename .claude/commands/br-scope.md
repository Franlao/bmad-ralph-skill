---
name: br-scope
description: "Change project scope — add/remove features, regenerate affected sprints"
---

# BMAD-Ralph Scope Management

Change the project scope mid-project without breaking what's already built.

**IMPORTANT**: For autonomous execution, delegate any file-writing work to the `br-developer` agent (its frontmatter declares `permissionMode: bypassPermissions`) — the Agent tool has no per-call permission parameter.

## Arguments

- `$ARGUMENTS` = `add "<feature description>"` → add a new feature
- `$ARGUMENTS` = `remove "<feature or STORY-X.Y>"` → remove a feature or story
- `$ARGUMENTS` = `list` → list current scope
- `$ARGUMENTS` empty → interactive scope review

## List Current Scope

Read `.bmad-ralph/docs/prd.md` and `.bmad-ralph/state.json`.

Display:
```
PROJECT SCOPE
═══════════════════════════════════════════

  P0 Features (must-have):
    [x] User authentication          (Sprint 1, DONE)
    [x] Invoice CRUD                 (Sprint 2, IN PROGRESS)
    [ ] PDF export                   (Sprint 3, PENDING)
    [ ] Stripe payments              (Sprint 3, PENDING)

  P1 Features (should-have):
    [ ] Dashboard with charts        (Sprint 4, PENDING)
    [ ] Email notifications          (Sprint 4, PENDING)

  P2 Features (nice-to-have):
    [ ] Multi-language               (not scheduled)
    [ ] Dark mode                    (not scheduled)

  Stories: 11 done / 28 total

  Change scope:
    /br-scope add "Export to CSV"
    /br-scope remove "Dark mode"
    /br-scope remove STORY-4.3
```

## Add Feature

When `$ARGUMENTS` = `add "<description>"`:

### Step 0: Size the Request — the rigor must match the feature

Adding a feature through br-scope must NOT become a way to bypass the
discovery/architecture rigor of the main pipeline. Classify first:

**SMALL** — ALL of these hold: fits in existing components, no new entity/table,
no new external dependency or service, no new auth/permission surface,
≤ 3 stories. → Go directly to Step 1 (lightweight flow).

**SIGNIFICANT** — anything else (new component, schema change, new dependency,
new integration, security surface, > 3 stories). → Run the **mini-pipeline**
below BEFORE Step 2. Tell the user which classification you chose and why,
in one line.

**RE-ARCHITECTURE** — the feature *invalidates* existing architecture decisions
(not just extends them): say so, and recommend setting phase back to `ARCHITECT`
via `/br-fix` instead of squeezing it through scope-add. Do not proceed alone.

### Mini-Pipeline for SIGNIFICANT features (scoped versions of the real phases)

1. **Scoped discovery** — launch 2 parallel read-only subagents on the FEATURE
   (not the whole product):
   - *Technical feasibility*: current APIs/libs needed (WebSearch, never from
     memory), risks, what the dependency manifest already provides
   - *Codebase integration*: where it plugs in, which existing patterns/utilities
     to reuse, what it must not break
   Both tag claims `[FACT — source] / [ASSUMPTION] / [UNKNOWN]` (same rules as
   `/br-discover`). Write to `.bmad-ralph/docs/discovery-feature-<slug>.md`.
2. **Architecture amendment** — in `architecture-amendments.md`, using the SAME
   standards as `/br-architect`: a Decision Record for any new tech choice
   (candidates, criteria, rejected-because), env vars added to the section 7b
   inventory, right-sizing rule applies (no requirement-free complexity).
3. **Mini expert panel** — 2 personas in parallel (staff engineer + agentic
   expert; add the security expert if the feature touches auth/user data),
   reviewing the amendment. Integrate or overrule findings in writing.
4. Then continue to Step 2 — stories get the FULL `/br-sprint` format
   (runnable verification commands, interface contracts, dependencies).

### Step 1: Analyze Impact
1. Read current PRD, architecture (+ amendments), and sprint files
2. Analyze the new feature against existing architecture:
   - What new components/endpoints are needed?
   - What existing code needs to change?
   - What dependencies are required?

### Step 2: Generate New Stories
1. Create user stories for the new feature (same format and quality bar as
   existing stories: exact files, step-by-step instructions, runnable
   verification command, acceptance criteria, interface contract if other
   stories will depend on them)
2. Assign priority (ask user or infer from description)
3. Determine dependencies on existing stories

### Step 3: Place in Sprints
Decide where the new stories go:
- If they fit in a **pending sprint** → append to that sprint file
- If pending sprints are full (8+ stories) → create a new sprint file
- **NEVER modify completed sprints**

### Step 4: Update Documents
1. Append feature to PRD (`prd.md`) in the appropriate priority section
2. If architecture changes needed → write to `.bmad-ralph/docs/architecture-amendments.md`
3. Update state.json:
   - Increment `total_sprints` if a new sprint was created, and add its entry to
     the `sprints` array (`{id, theme, stories_total, stories_completed: 0, status: "PENDING", quality_gate: null}`)
   - If stories were appended to an existing pending sprint → update that
     sprint entry's `stories_total`
   - Update `metrics.stories_total`

### Step 5: Display Summary
```
FEATURE ADDED
═══════════════════════════════════════════
  Feature: "Export to CSV"
  Priority: P1

  New stories:
    STORY-4.5 "Add CSV export service"
    STORY-4.6 "Add export button to UI"

  Added to: Sprint 4
  Architecture amendment: Yes (new export service)

  Total stories: 28 → 30
```

## Remove Feature / Story

When `$ARGUMENTS` = `remove "<feature>"` or `remove STORY-X.Y`:

### Remove by Story ID
1. Find the story in sprint files
2. If **already completed** (has commit):
   - Warn: "This story is already implemented. Use `/br-rollback story STORY-X.Y` to revert the code."
   - Do NOT auto-rollback — let the user decide
3. If **pending** (not implemented):
   - Mark as `SKIPPED` in the sprint file (add `**Status: SKIPPED**` to the story)
   - Decrement `metrics.stories_total` in state.json
   - Log the removal

### Remove by Feature Name
1. Search PRD for the feature
2. Find all related stories across sprint files
3. For each story: apply the same logic as "Remove by Story ID"
4. Mark the feature as "REMOVED" in the PRD
5. Display summary of affected stories

### Safety Rules
- **NEVER delete content** from sprint files — mark as SKIPPED
- **NEVER modify completed sprints** — warn and suggest rollback
- **NEVER auto-rollback** — always let the user decide
- Show a preview of what will change before applying

## Interactive Scope Review (no arguments)

1. Display the full scope list (same as `list`)
2. Ask: "What would you like to change?"
3. Guide the user through add/remove operations
