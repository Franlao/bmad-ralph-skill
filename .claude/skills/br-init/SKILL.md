---
name: br-init
description: "Initialize a BMAD-Ralph project — sets up state, directories, and config"
argument-hint: "<description du projet entre guillemets>"
---

# BMAD-Ralph Initialization

Initialize a new BMAD-Ralph project for: **$ARGUMENTS**

## Step 1: Create Directory Structure

Create the following directories and files:

```bash
mkdir -p .bmad-ralph/{docs,sprints,logs}
```

## Step 1b: Create .gitignore for BMAD logs

Append to `.gitignore` (create if needed):
```
# BMAD-Ralph logs (regeneratable)
.bmad-ralph/logs/
```

## Step 1c: Initialize Git

Ensure the project is a git repository:
1. If `.git/` does not exist, run `git init` and create an initial commit
2. Record the current branch name in state.json as `project.base_branch`
3. This is the branch where all sprint branches will merge back to

## Step 2: Analyze Existing Project

Before creating state, analyze the current project:

1. Read `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or equivalent to detect the tech stack
2. Read `CLAUDE.md` if it exists for existing conventions
3. Check git history for project maturity (new vs existing)
4. Scan the directory structure to understand the architecture
5. Check for existing tests, CI/CD, linting config

## Step 2b: Verify the toolchain by RUNNING it

Detection is a guess; a command that exited 0 is a fact. Every later phase needs to know
how to test, lint and typecheck this project — today `/br-test`, `/br-build` and
`/br-review` each re-guess it, and each can guess differently.

**Run the candidates. Record what actually worked.**

1. Identify the interpreter or runtime that will actually execute the code, and resolve it
   (`python3 -c "import sys; print(sys.executable, sys.version)"`, `node -v`, `go version`).
2. For each of test / lint / typecheck / build, run the candidate and look at the exit code
   **and** the first lines of output.
3. **Prefer the form bound to that interpreter** over the one on the PATH:
   `python3 -m pytest` over `pytest`, `npx --no-install vitest` over a global `vitest`.
   A bare name on the PATH can resolve to another environment entirely — a real run of this
   pipeline found `which pytest` pointing at a different Python than `python3 -m pytest`,
   and nothing downstream would have noticed.
4. Write the verified commands into `state.json` under `toolchain`, with a `notes` line for
   anything surprising you had to work around.

**On an empty project there is nothing to run.** Leave the fields `null`, say so, and
record them at the end of Sprint 1 — the walking skeleton is exactly the story that makes
them real. Never write a command you have not seen exit.

## Step 3: Create State File

Write `.bmad-ralph/state.json` with this structure:

```json
{
  "project": {
    "name": "<detected or from $ARGUMENTS>",
    "description": "$ARGUMENTS",
    "created_at": "<ISO timestamp>",
    "tech_stack": "<detected>",
    "type": "new|existing_feature|refactor",
    "base_branch": "<current git branch name, e.g. main>"
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
    "max_gate_cycles": 3,
    "current_story": null,
    "current_attempt": 0
  },
  "toolchain": {
    "runtime": "<resolved interpreter + version, or null>",
    "test": "<verified command, or null>",
    "lint": "<verified command, or null>",
    "typecheck": "<verified command, or null>",
    "build": "<verified command, or null>",
    "verified_at": "<ISO timestamp, or null if nothing could be run yet>",
    "notes": "<anything surprising: PATH shadowing, venv, monorepo scoping>"
  },
  "deliverables": {
    "brief": ".bmad-ralph/docs/brief.md",
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

## Step 4: Write the Project Brief (filled in, not a blank template)

Write `.bmad-ralph/docs/brief.md` — **already filled** from `$ARGUMENTS`, the detected
stack, and the codebase scan of Step 2. An empty template helps nobody: `/br-discover`
reads this file, and placeholders read as facts to a research agent.

Fill what you can actually support, and tag every line the way discovery does:
`[FACT — source]` for anything you read from the repo or the description,
`[ASSUMPTION]` for a reasonable inference, `[UNKNOWN]` for what you cannot determine.
An `[UNKNOWN]` is a research question for `/br-discover`, and that is a useful output —
an invented answer is not.

```markdown
# Project Brief: <name>

## Vision
<derived from $ARGUMENTS — what this is and what problem it solves>

## Target Users
<[UNKNOWN] if the description doesn't say — do not invent personas here,
that is the discovery agent's job>

## Core Features (MVP)
<the features literally implied by $ARGUMENTS, nothing more>

## Success Criteria
<[UNKNOWN] unless stated>

## Constraints
<[FACT] the detected stack, existing conventions, CI, test setup from Step 2>

## Out of Scope
<[UNKNOWN] unless stated>
```

## Step 5: Install CLAUDE.md

If `.claude/templates/CLAUDE.md` exists (installed by the skill), use it as the base template.

- If `CLAUDE.md` already exists in the project root → append the BMAD-Ralph section from the template
- If `CLAUDE.md` does not exist → copy the template as `CLAUDE.md`

This gives Claude Code the project conventions for BMAD-Ralph (git workflow, safety rules, file structure).

## Step 6: Recommend MCP Servers (opt-in — do NOT auto-install)

Installing MCP servers modifies the user's Claude Code configuration and runs
third-party packages — that is the user's call, not the initializer's.

1. Detect which MCPs would help this project (stack-aware):
   - `context7` — live library documentation (useful for any stack)
   - `eslint` — if `package.json` has eslint
   - `vitest` — if `package.json` has vitest
   - `postgres` — if the project uses PostgreSQL
2. Display the recommendation and let the user decide:
   ```
   Recommended MCP servers for this project (not installed):
     - context7   — live library docs (prevents outdated-API errors during Ralph loops)
     - eslint     — JS/TS linting (detected in package.json)

   Install them with: /br-mcp add context7
   See the full catalog: /br-mcp list
   ```
3. Do not run `claude mcp add` or write `.mcp.json` during init. `/br-mcp`
   handles installation when the user asks for it.

## Step 7: Confirm Initialization

Display the detected project info and ask the user to:
1. Confirm or correct the tech stack
2. Answer whatever `brief.md` marked `[UNKNOWN]` (target users, success criteria,
   constraints, out of scope) — or say "skip", in which case those stay `[UNKNOWN]`
3. Decide if this is a new project, new feature, or refactor

**Write the answers back into `.bmad-ralph/docs/brief.md`**, replacing the matching
`[UNKNOWN]` lines and tagging them `[FACT — user]`. A brief that stays in the chat is a
brief that discovery never sees.

Then tell them: "Run `/br-discover` to start the discovery phase, or `/br-auto` to run all planning phases automatically."
