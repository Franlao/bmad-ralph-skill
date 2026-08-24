---
name: br-config
description: "Configure BMAD-Ralph settings — model, iterations, circuit breaker, and more"
argument-hint: '[model <role> <model> | circuit-breaker N | max-iterations N | guard add "<pattern>" | reset]'
---

# BMAD-Ralph Configuration

View and modify BMAD-Ralph settings without editing files manually.

## Arguments

- `$ARGUMENTS` empty → show current config
- `$ARGUMENTS` = `model <role> <model>` → change the model for one role (see Model Matrix)
- `$ARGUMENTS` = `model <model>` → change the model for ALL roles at once
- `$ARGUMENTS` = `model best` → apply the "best available" profile (fable on the highest-leverage phases — see Model Profiles)
- `$ARGUMENTS` = `max-iterations <N>` → max retries per story (default: 5)
- `$ARGUMENTS` = `max-sprint-iterations <N>` → max total iterations per sprint (default: 40)
- `$ARGUMENTS` = `circuit-breaker <N>` → failures before escalation (default: 3)
- `$ARGUMENTS` = `guard add "<pattern>"` → add a protected file pattern
- `$ARGUMENTS` = `guard list` → show protected patterns
- `$ARGUMENTS` = `reset` → reset all settings to defaults

## Step 0 — Locate the install root (do this BEFORE any edit)

BMAD-Ralph installs either into the project (`.claude/`) or globally
(`~/.claude/`). Every path below is relative to the install root, so resolve it
first — editing `.claude/commands/…` from a global install silently writes to a
directory that doesn't exist, or creates a shadow copy that never runs:

1. `.claude/commands/br-config.md` exists → `ROOT=.claude` (project install)
2. else `~/.claude/commands/br-config.md` exists → `ROOT=~/.claude` (global install)
3. both exist → ask the user which one to change (project shadows global)
4. neither → tell the user to re-run `install.sh`

## Model Matrix — which model runs what

Every role's model lives in a frontmatter `model:` field. Reasoning-heavy
phases default to `opus`; execution defaults to `sonnet` (cheaper, and story
implementation is spec-following, not open-ended design):

| Role | File whose frontmatter to edit | Default |
|------|-------------------------------|---------|
| `discover` | `$ROOT/commands/br-discover.md` | opus |
| `plan` | `$ROOT/commands/br-plan.md` | opus |
| `architect` | `$ROOT/commands/br-architect.md` | opus |
| `sprint` | `$ROOT/commands/br-sprint.md` | opus |
| `review` | `$ROOT/commands/br-review.md` | opus |
| `auto` | `$ROOT/commands/br-auto.md` | opus |
| `scope` | `$ROOT/commands/br-scope.md` | opus |
| `build` | `$ROOT/commands/br-build.md` | sonnet |
| `resume` | `$ROOT/commands/br-resume.md` | sonnet |
| `fix` | `$ROOT/commands/br-fix.md` | sonnet |
| `test` | `$ROOT/commands/br-test.md` | sonnet |
| `dev` | `$ROOT/agents/br-developer.md` | sonnet |
| `qa` | `$ROOT/agents/br-qa.md` | sonnet |

The remaining commands (`br`, `br-init`, `br-status`, `br-logs`, `br-metrics`,
`br-debug`, `br-rollback`, `br-deploy`, `br-mcp`, `br-update`, `br-config`)
declare **no** `model:` on purpose: they read state and print, so they run on
whatever model the session is using. They are not roles — `/br-config model …`
does not target them.

Subagents launched inline by a phase (discovery researchers, the architect's
expert panel) are expected to inherit that phase's model, but Claude Code does
not document what `inherit` resolves to inside a turn that overrode the model.
Treat it as unverified and check it with the `[model:]` tags below rather than
assuming it.

## Model Profiles

### `model best` — maximum quality where reasoning compounds

Applies in one shot:

| Roles | Model | Rationale |
|-------|-------|-----------|
| `architect`, `review` | `fable` | The two highest-leverage judgment points: a design error costs whole sprints; the quality gate is the last line of defense |
| `discover`, `plan`, `sprint`, `auto`, `scope` | `opus` | Thinking-heavy, but the fable premium pays less here |
| `build`, `resume`, `fix`, `test`, `dev`, `qa` | `sonnet` | Spec-following execution — stories are deliberately written to be implementable by an economical model |

Procedure:
1. Edit each file's `model:` frontmatter per the table above
2. Warn: "fable requires access to the Fable/Mythos tier — if `/br-architect`
   errors with 'model not available', run `/br-config model architect opus`
   and `/br-config model review opus` to fall back."
3. Remind: verify with
   `grep -o '\[model:[^]]*\]' .bmad-ralph/logs/monitor.log | sort | uniq -c`

### `reset` — back to defaults
The Model Matrix defaults (opus planning / sonnet execution) — see Reset to Defaults.

## Show Current Config (no arguments)

Read `.bmad-ralph/state.json` plus the `model:` frontmatter of the files in the
Model Matrix.

Display:
```
BMAD-RALPH CONFIGURATION
═══════════════════════════════════════════

  Models
    discover/plan/architect/sprint/review/auto/scope:  opus
    build/resume/fix/test:                            sonnet
    dev agent / qa agent:                             sonnet
    (other commands: no override — session model)

  Max iterations/story:   5
  Max iterations/sprint:  40
  Circuit breaker:        3 failures

  Guard protected patterns (matched on the BASENAME, not the path):
    .env, .env.*, *.env   — except *.example/*.sample/*.template/*.dist
    *.key, *.pem, *.crt, *.cert, *.p12, *.pfx, *.keystore, id_rsa*
    credential*, secret*  — only outside source extensions,
                            so src/config/secrets.ts stays editable

  Auto-format hook:       enabled
  Monitor hook:           enabled

  Change settings:
    /br-config model architect fable
    /br-config model dev sonnet
    /br-config model opus            (all roles)
    /br-config max-iterations 8
```
(Group roles that share a model on one line, as above.)

## Change Model

When `$ARGUMENTS` = `model <role> <value>` or `model <value>`:

1. Validate `<value>`: one of `opus`, `sonnet`, `haiku`, `fable`, `inherit`,
   or a full model ID (`claude-*`). `inherit` removes the override — the role
   then follows whatever model the user's session runs.
2. Validate `<role>` against the Model Matrix (no role = apply to ALL rows).
3. Edit the `model:` line in the target file's frontmatter (add it if absent,
   remove it for `inherit`).
4. Display what changed, plus the relevant caveats:
   ```
   Model updated: architect  opus → fable

   Notes:
   - Higher-tier models cost more per token — /br-metrics estimates spend.
   - fable/opus availability depends on your subscription; if a phase
     errors with "model not available", set that role back:
     /br-config model architect sonnet
   - Command-level model changes apply to NEW invocations of that phase.
   ```

### Verifying the routing actually applies

The `model:` frontmatter is enforced by Claude Code itself (not by the model
"choosing"), but trust is verified, not assumed: `br-monitor.sh` stamps every
logged action with the model observed in the session transcript. To audit:

```bash
grep -o '\[model:[^]]*\]' .bmad-ralph/logs/monitor.log | sort | uniq -c
```

During a planning phase you should see an opus ID; during `/br-build`, a
sonnet ID. If the tags don't match the matrix, the phase was launched before
the frontmatter change (restart it) or the model isn't available on your plan.

## Change Iteration Limits

When `$ARGUMENTS` = `max-iterations <N>` or `max-sprint-iterations <N>` or `circuit-breaker <N>`:

1. Validate: N must be a positive integer
2. Read `.bmad-ralph/state.json`
3. Update the corresponding field:
   - `max-iterations` → `ralph.max_iterations_per_story`
   - `max-sprint-iterations` → `ralph.max_iterations_per_sprint`
   - `circuit-breaker` → `ralph.circuit_breaker_threshold`
4. Write updated state.json
5. Display the change

## Guard Patterns

When `$ARGUMENTS` = `guard add "<pattern>"`:

1. Read `$ROOT/hooks/br-guard.sh`
2. Add the pattern to the `is_protected()` function
3. Display confirmation

When `$ARGUMENTS` = `guard list`:

1. Read `$ROOT/hooks/br-guard.sh`
2. Parse the `is_protected()` function patterns
3. Display them as a list

## Reset to Defaults

When `$ARGUMENTS` = `reset`:

1. Update `.bmad-ralph/state.json`:
   - `ralph.max_iterations_per_story` = 5
   - `ralph.max_iterations_per_sprint` = 40
   - `ralph.circuit_breaker_threshold` = 3
2. Reset models to the Model Matrix defaults (opus for the planning/judgment
   phases, sonnet for execution, no override anywhere else)
3. Display: "All settings reset to defaults."
