---
name: br-logs
description: "View BMAD-Ralph logs — monitor, errors, sprint activity"
---

# BMAD-Ralph Log Viewer

View and analyze logs from the BMAD-Ralph project.

## Arguments

- `$ARGUMENTS` = empty or "all" → show summary of all logs
- `$ARGUMENTS` = "monitor" → show real-time monitor log (last 30 lines)
- `$ARGUMENTS` = "errors" → show only errors across all logs
- `$ARGUMENTS` = "sprint N" → show sprint N log
- `$ARGUMENTS` = "review N" → show sprint N review report
- `$ARGUMENTS` = "escalations" → show all escalation reports
- `$ARGUMENTS` = "tail" → show last 10 lines of monitor log (quick check)

## Implementation

### "all" — Log Summary
Read all files in `.bmad-ralph/logs/` and display:

```
BMAD-RALPH LOGS
───────────────────────────────────────────

Monitor Log (last activity):
  Last entry: [2026-03-12T14:32:00Z] BASH: npx vitest run
  Total entries: 87
  Errors detected: 3

Sprint Logs:
  sprint-1.log: 7 entries (6 PASS, 1 FAIL → resolved)
  sprint-2.log: 4 entries (3 PASS, 1 in progress)

Error Log:
  3 errors found:
  [14:20:00] npx tsc --noEmit → exit 1
  [14:22:00] npx tsc --noEmit → exit 1
  [14:25:00] npx vitest run → exit 1

Escalations: 1
  STORY-1.4 — see .bmad-ralph/logs/escalation-STORY-1.4.md

Reviews: 1
  Sprint 1: Score B, PASS
```

### "errors" — Error Focus
Read `.bmad-ralph/logs/errors.log` and all sprint logs.
Group errors by:
1. **By story** — which story caused the most errors?
2. **By type** — TypeScript errors? Test failures? Runtime errors?
3. **By time** — when did errors cluster? (detects Ralph loops struggling)

Display:
```
ERRORS BY STORY
  STORY-1.4: 5 errors (circuit breaker triggered)
  STORY-1.6: 2 errors (resolved on 2nd attempt)
  STORY-1.7: 1 error (resolved on 1st retry)

ERRORS BY TYPE
  TypeScript (tsc): 3
  Test failure (vitest): 4
  Runtime: 1

ERROR TIMELINE
  14:20-14:25  ███ 3 errors (STORY-1.4 struggling)
  14:30-14:35  █ 1 error (STORY-1.6 retry)
  14:40-14:42  █ 1 error (STORY-1.7 test fix)
  14:45+       No errors
```

### "monitor" — Live Activity
Read last 30 lines of `.bmad-ralph/logs/monitor.log` and display with coloring:
- BASH lines → show command
- EDIT/WRITE lines → show file path
- AGENT lines → show description
- !! FAIL lines → highlight in red

### "tail" — Quick Check
Read last 10 lines of `.bmad-ralph/logs/monitor.log`.
Show them as-is. Quick way to see "what is Ralph doing right now?"

### "sprint N"
Read `.bmad-ralph/logs/sprint-<N>.log` and display all entries with:
- PASS/FAIL coloring
- Story names
- Error summaries for failures
- Duration between entries (to spot slow stories)

### "escalations"
Read all `escalation-STORY-*.md` files and display:
- Story name and description
- Number of attempts
- Root cause
- Recommendation
- Whether it was fixed or still pending
