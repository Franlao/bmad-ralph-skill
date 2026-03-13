---
name: br-scope
description: "Change project scope — add/remove features, regenerate affected sprints"
---

# BMAD-Ralph Scope Management

Change the project scope mid-project without breaking what's already built.

**IMPORTANT**: Use `mode: "bypassPermissions"` on all Agent tool calls for autonomous execution.

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
    /project:br-scope add "Export to CSV"
    /project:br-scope remove "Dark mode"
    /project:br-scope remove STORY-4.3
```

## Add Feature

When `$ARGUMENTS` = `add "<description>"`:

### Step 1: Analyze Impact
1. Read current PRD, architecture, and sprint files
2. Analyze the new feature against existing architecture:
   - What new components/endpoints are needed?
   - What existing code needs to change?
   - What dependencies are required?

### Step 2: Generate New Stories
1. Create user stories for the new feature (same format as existing stories)
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
   - Increment `total_sprints` if new sprint created
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
   - Warn: "This story is already implemented. Use `/project:br-rollback story STORY-X.Y` to revert the code."
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
