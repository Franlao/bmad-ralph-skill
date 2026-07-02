---
name: br-config
description: "Configure BMAD-Ralph settings — model, iterations, circuit breaker, and more"
---

# BMAD-Ralph Configuration

View and modify BMAD-Ralph settings without editing files manually.

## Arguments

- `$ARGUMENTS` empty → show current config
- `$ARGUMENTS` = `model <role> <model>` → change the model for one role (see Model Matrix)
- `$ARGUMENTS` = `model <model>` → change the model for ALL roles at once
- `$ARGUMENTS` = `max-iterations <N>` → max retries per story (default: 5)
- `$ARGUMENTS` = `max-sprint-iterations <N>` → max total iterations per sprint (default: 40)
- `$ARGUMENTS` = `circuit-breaker <N>` → failures before escalation (default: 3)
- `$ARGUMENTS` = `guard add "<pattern>"` → add a protected file pattern
- `$ARGUMENTS` = `guard list` → show protected patterns
- `$ARGUMENTS` = `reset` → reset all settings to defaults

## Model Matrix — which model runs what

Every role's model lives in a frontmatter `model:` field. Reasoning-heavy
phases default to `opus`; execution defaults to `sonnet` (cheaper, and story
implementation is spec-following, not open-ended design):

| Role | File whose frontmatter to edit | Default |
|------|-------------------------------|---------|
| `discover` | `.claude/commands/br-discover.md` | opus |
| `plan` | `.claude/commands/br-plan.md` | opus |
| `architect` | `.claude/commands/br-architect.md` | opus |
| `sprint` | `.claude/commands/br-sprint.md` | opus |
| `review` | `.claude/commands/br-review.md` | opus |
| `auto` | `.claude/commands/br-auto.md` | opus |
| `build` | `.claude/commands/br-build.md` | sonnet |
| `dev` | `.claude/agents/br-developer.md` | sonnet |
| `qa` | `.claude/agents/br-qa.md` | sonnet |

Subagents launched inline by a phase (discovery researchers, the architect's
expert panel) inherit that phase's model automatically.

## Show Current Config (no arguments)

Read `.bmad-ralph/state.json` plus the `model:` frontmatter of the files in the
Model Matrix.

Display:
```
BMAD-RALPH CONFIGURATION
═══════════════════════════════════════════

  Models
    discover/plan/architect/sprint/review:  opus
    build (Ralph loop):                     sonnet
    dev agent / qa agent:                   sonnet

  Max iterations/story:   5
  Max iterations/sprint:  40
  Circuit breaker:        3 failures

  Guard protected patterns:
    *.env, *.env.local, *.env.production, *.env.staging
    *.key, *.pem, *.cert, *.p12, *.pfx
    *credentials*, *secret*

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

1. Read `.claude/hooks/br-guard.sh`
2. Add the pattern to the `is_protected()` function
3. Display confirmation

When `$ARGUMENTS` = `guard list`:

1. Read `.claude/hooks/br-guard.sh`
2. Parse the `is_protected()` function patterns
3. Display them as a list

## Reset to Defaults

When `$ARGUMENTS` = `reset`:

1. Update `.bmad-ralph/state.json`:
   - `ralph.max_iterations_per_story` = 5
   - `ralph.max_iterations_per_sprint` = 40
   - `ralph.circuit_breaker_threshold` = 3
2. Reset models to the Model Matrix defaults (opus for planning phases,
   sonnet for build/dev/qa)
3. Display: "All settings reset to defaults."
