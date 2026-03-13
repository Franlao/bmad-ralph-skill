---
name: br-config
description: "Configure BMAD-Ralph settings — model, iterations, circuit breaker, and more"
---

# BMAD-Ralph Configuration

View and modify BMAD-Ralph settings without editing files manually.

## Arguments

- `$ARGUMENTS` empty → show current config
- `$ARGUMENTS` = `model <opus|sonnet|haiku>` → change the AI model for agents
- `$ARGUMENTS` = `max-iterations <N>` → max retries per story (default: 5)
- `$ARGUMENTS` = `max-sprint-iterations <N>` → max total iterations per sprint (default: 40)
- `$ARGUMENTS` = `circuit-breaker <N>` → failures before escalation (default: 3)
- `$ARGUMENTS` = `guard add "<pattern>"` → add a protected file pattern
- `$ARGUMENTS` = `guard list` → show protected patterns
- `$ARGUMENTS` = `reset` → reset all settings to defaults

## Show Current Config (no arguments)

Read `.bmad-ralph/state.json` and `.claude/agents/br-developer.md` and `.claude/agents/br-qa.md`.

Display:
```
BMAD-RALPH CONFIGURATION
═══════════════════════════════════════════

  Model (developer):      sonnet
  Model (QA):             sonnet
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
    /project:br-config model opus
    /project:br-config max-iterations 8
    /project:br-config circuit-breaker 5
```

## Change Model

When `$ARGUMENTS` = `model <value>`:

1. Validate: must be `opus`, `sonnet`, or `haiku`
2. Edit `.claude/agents/br-developer.md`: change the `model:` line in frontmatter
3. Edit `.claude/agents/br-qa.md`: change the `model:` line in frontmatter
4. Display:
   ```
   Model updated: sonnet → opus
   Both br-developer and br-qa agents will now use opus.
   Note: opus is more capable but costs ~6x more per token.
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
2. Reset model to `sonnet` in both agent files
3. Display: "All settings reset to defaults."
