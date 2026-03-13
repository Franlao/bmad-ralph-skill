---
name: br-init
description: "Initialize a BMAD-Ralph project — sets up state, directories, and config"
---

# BMAD-Ralph Initialization

Initialize a new BMAD-Ralph project for: **$ARGUMENTS**

## Step 1: Create Directory Structure

Create the following directories and files:

```bash
mkdir -p .bmad-ralph/{docs,sprints,prompts,logs}
```

## Step 1b: Create .gitignore for BMAD logs

Append to `.gitignore` (create if needed):
```
# BMAD-Ralph logs (regeneratable)
.bmad-ralph/logs/
```

## Step 2: Analyze Existing Project

Before creating state, analyze the current project:

1. Read `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or equivalent to detect the tech stack
2. Read `CLAUDE.md` if it exists for existing conventions
3. Check git history for project maturity (new vs existing)
4. Scan the directory structure to understand the architecture
5. Check for existing tests, CI/CD, linting config

## Step 3: Create State File

Write `.bmad-ralph/state.json` with this structure:

```json
{
  "project": {
    "name": "<detected or from $ARGUMENTS>",
    "description": "$ARGUMENTS",
    "created_at": "<ISO timestamp>",
    "tech_stack": "<detected>",
    "type": "new|existing_feature|refactor"
  },
  "phase": "DISCOVER",
  "phases_completed": [],
  "current_sprint": 0,
  "total_sprints": 0,
  "sprints": [],
  "last_updated_at": "<ISO timestamp>",
  "ralph": {
    "total_iterations": 0,
    "max_iterations_per_story": 5,
    "max_iterations_per_sprint": 40,
    "circuit_breaker_threshold": 3,
    "completion_promise": "STORY_COMPLETE"
  },
  "deliverables": {
    "business_brief": null,
    "prd": null,
    "architecture": null,
    "sprint_stories": [],
    "implementations": [],
    "reviews": []
  },
  "metrics": {
    "stories_completed": 0,
    "stories_total": 0,
    "ralph_iterations_total": 0,
    "quality_gate_passes": 0,
    "quality_gate_failures": 0,
    "escalations_to_architect": 0
  }
}
```

## Step 4: Create Project Brief Template

Write `.bmad-ralph/docs/brief-template.md`:

```markdown
# Project Brief: <name>

## Vision
<What is this project? What problem does it solve?>

## Target Users
<Who will use this? What are their pain points?>

## Core Features (MVP)
<List the must-have features for v1>

## Success Criteria
<How do we know this is done and working?>

## Constraints
<Budget, timeline, tech constraints, etc.>

## Out of Scope
<What are we explicitly NOT building?>
```

## Step 5: Update CLAUDE.md

If CLAUDE.md exists, append the BMAD-Ralph section. If not, create it with:

```markdown
# BMAD-Ralph Configuration

## State
- State file: .bmad-ralph/state.json
- Docs: .bmad-ralph/docs/
- Sprint stories: .bmad-ralph/sprints/

## Development Rules
- ALWAYS read and understand code BEFORE modifying it
- ALWAYS run tests after implementing a story
- NEVER modify .bmad-ralph/state.json manually — use br commands
- Commit after each completed story with conventional commits
```

## Step 6: Confirm Initialization

Display the detected project info and ask the user to:
1. Confirm or correct the tech stack
2. Fill in the project brief (or provide a description)
3. Decide if this is a new project, new feature, or refactor

Then tell them: "Run `/project:br-discover` to start the discovery phase, or `/project:br auto` to run all planning phases automatically."
