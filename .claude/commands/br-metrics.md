---
name: br-metrics
description: "Ralph performance analytics — success rate, iterations, cost estimate"
---

# BMAD-Ralph Metrics & Analytics

Analyze Ralph's performance across the project.

## Pre-check

Read `.bmad-ralph/state.json`. If no stories have been executed, say "No execution data yet. Run `/project:br-build` first."

## Data Sources

Read:
- `.bmad-ralph/state.json` → metrics object
- `.bmad-ralph/logs/sprint-*.log` → parse PASS/FAIL entries with timestamps
- `.bmad-ralph/logs/escalation-*.md` → count and analyze escalations
- `.bmad-ralph/logs/review-sprint-*.md` → quality scores
- `git log --grep="feat(sprint-"` → commit timestamps for velocity

## Display

```
BMAD-RALPH METRICS
═══════════════════════════════════════════════════

COMPLETION
  Stories:       11 / 28  [████████░░░░░░░░░░░░] 39%
  Sprints:       1 / 4    [█████░░░░░░░░░░░░░░░] 25%
  Escalations:   1

RALPH EFFICIENCY
  Total iterations:       34
  Avg iterations/story:   3.1
  First-try success:      7 / 11 (64%)  ████████████░░░░░░░░
  Retry success:          3 / 11 (27%)  █████░░░░░░░░░░░░░░░
  Circuit breaker:        1 / 11 (9%)   ██░░░░░░░░░░░░░░░░░░

QUALITY GATE
  Passes:    1
  Failures:  0
  Avg score: B

COST ESTIMATE (rough)
  ┌──────────┬────────────┬────────────┬──────────┐
  │  Model   │ Input ~tok │ Output ~tok│ Est. cost│
  ├──────────┼────────────┼────────────┼──────────┤
  │ Sonnet   │ ~170K      │ ~85K       │ ~$2.50   │
  │ Opus     │ ~170K      │ ~85K       │ ~$18.00  │
  │ Haiku    │ ~170K      │ ~85K       │ ~$0.50   │
  └──────────┴────────────┴────────────┴──────────┘
  Based on ~5K input + 2.5K output per iteration × 34 iterations.
  This is a rough estimate — actual costs vary.

VELOCITY
  Stories/sprint (avg):    6.0
  Avg time per story:      ~3 min
  Sprint duration (avg):   ~22 min
  Projected remaining:     ~66 min (17 stories × 3 sprints)

PROBLEM AREAS
  Most retried:    STORY-1.4 (3 attempts → escalated)
  Error patterns:  TypeScript type errors (5×), test failures (3×)
  Slowest story:   STORY-2.1 (~8 min)

═══════════════════════════════════════════════════
```

## Cost Estimation Logic

Rough heuristics per iteration:
- ~5,000 input tokens (reading story + architecture + existing code)
- ~2,500 output tokens (code generation + tool calls)

Per model pricing (estimates):
- **Sonnet**: $3/M input, $15/M output → ~$0.05/iteration
- **Opus**: $15/M input, $75/M output → ~$0.25/iteration
- **Haiku**: $0.25/M input, $1.25/M output → ~$0.005/iteration

Total = iterations × cost per iteration. Clearly label as estimates.

## Velocity Calculation

Parse git log timestamps for sprint commits:
```bash
git log --format="%ai %s" --grep="feat(sprint-"
```

Calculate time between first and last commit per sprint = sprint duration.
Calculate time between consecutive commits = time per story.
Project remaining time = remaining stories × avg time per story.

## Arguments

- `$ARGUMENTS` empty → full metrics dashboard
- `$ARGUMENTS` = `cost` → cost estimate only
- `$ARGUMENTS` = `velocity` → velocity and time projection only
- `$ARGUMENTS` = `errors` → error pattern analysis only
