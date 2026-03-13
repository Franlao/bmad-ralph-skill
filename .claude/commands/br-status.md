---
name: br-status
description: "Show BMAD-Ralph project status dashboard"
---

# BMAD-Ralph Status Dashboard

Read `.bmad-ralph/state.json` and display the project status.

If the file doesn't exist, say: "No BMAD-Ralph project initialized. Run `/project:br-init <description>` to start."

## Display Format

```
╔═══════════════════════════════════════════════════════════╗
║                   BMAD-RALPH STATUS                       ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  Project:  <name>                                         ║
║  Type:     <new|feature|refactor>                         ║
║  Stack:    <tech_stack>                                   ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  PHASE PROGRESS                                           ║
║                                                           ║
║  [x] DISCOVER  — Business & technical analysis            ║
║  [x] PLAN      — Product requirements (PRD)              ║
║  [ ] ARCHITECT — System architecture          <── CURRENT ║
║  [ ] SPRINT    — Story breakdown                          ║
║  [ ] EXECUTE   — Ralph autonomous build                   ║
║  [ ] REVIEW    — Quality gate                             ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  SPRINT PROGRESS                                          ║
║                                                           ║
║  Sprint:     <current> / <total>                          ║
║  Stories:    <done> / <total>  [████████░░] 80%           ║
║  Ralph runs: <iterations_total>                           ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  QUALITY METRICS                                          ║
║                                                           ║
║  QA Passes:     <passes>                                  ║
║  QA Failures:   <failures>                                ║
║  Escalations:   <escalations>                             ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  DELIVERABLES                                             ║
║                                                           ║
║  [x] Business Brief  .bmad-ralph/docs/business-brief.md  ║
║  [x] PRD             .bmad-ralph/docs/prd.md              ║
║  [ ] Architecture    —                                    ║
║  [ ] Sprint Stories  —                                    ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  NEXT ACTION                                              ║
║                                                           ║
║  Run: /project:br-architect                               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

Mark completed phases with [x], current phase with `<── CURRENT`, pending with [ ].
Show the progress bar for stories based on completion percentage.

## If in EXECUTE phase, also show:

```
║  RALPH LOOP STATUS                                        ║
║                                                           ║
║  Current Story:  STORY-2.3 "Add auth middleware"          ║
║  Attempt:        2 / 5                                    ║
║  Last Error:     TypeError: cannot read 'token'           ║
║  Circuit Breaker: OK (1/3 failures)                       ║
```

## Also list any escalated stories:

```
║  ESCALATED STORIES (need attention)                       ║
║                                                           ║
║  ! STORY-1.4 — "WebSocket handler" — 3 failures          ║
║    See: .bmad-ralph/logs/escalation-STORY-1.4.md          ║
```
