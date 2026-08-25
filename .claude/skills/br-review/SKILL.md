---
name: br-review
description: "Quality Gate Review — Validate sprint implementation against specs"
model: opus
---

# BMAD-Ralph Review Phase (QA Agent)

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `REVIEW`.

## Mission
You are the **QA Reviewer**. Your job is to ruthlessly validate the sprint implementation against the specifications. You are the quality gate between sprints.

## Step 1: Gather Context

Read:
- `.bmad-ralph/docs/architecture.md`
- `.bmad-ralph/sprints/sprint-<current>.md` (stories and acceptance criteria)
- `.bmad-ralph/logs/sprint-<current>.log` (implementation log)
- Any escalation files in `.bmad-ralph/logs/escalation-*.md`
- Git log for sprint commits

## Step 2: Run Verification Suite

Use the commands recorded in `state.json` under `toolchain` — verified by running them at
init, not guessed here. A gate that runs a different linter than the loop did is measuring
another project.

Execute in order:
1. **Build check**: `toolchain.build`
2. **Type check**: `toolchain.typecheck`
3. **Lint check**: `toolchain.lint`
4. **Test suite**: Run all tests
5. **Coverage check**: Check test coverage if configured

Log all results.

## Step 2.5: Right-size the review to this project

`/br-discover` and `/br-architect` already classify the project before working; the review
must too. A checklist written for a web application produces noise on a CLI — and, worse,
hides the checks that actually matter for it.

1. **Classify** from `state.json` (`project.tech_stack`, `project.type`) and the
   architecture: local CLI / library, web application, HTTP API / service, data or batch
   processing.
2. **Say which dimensions do not apply**, in one line. "Not applicable" is a valid and
   expected answer — the rest of the pipeline is allowed to say it, the review must be too.
   A reviewer hunting XSS in a local CLI is a reviewer not reading the error strategy.
3. **Derive the checkpoints from the architecture**: its error strategy (§7), its
   Configuration & Environment inventory (§7b), its NFRs. The architecture is what this
   project promised; that is what the review measures against. The table below is a
   starting point, not a ceiling.

| Project class | Security looks at | Performance looks at |
|---------------|-------------------|----------------------|
| CLI / library | file permissions, path traversal, unsafe deserialization, secrets in argv or env, hostile input reaching a parser | startup cost, memory on large inputs, O(n²) on user-grown data |
| Web application | XSS, CSRF, auth and authz on every route, session handling, input validation | N+1, missing indexes, payload size, unnecessary re-renders |
| HTTP API / service | authn/authz per endpoint, injection, rate limiting, error message leakage | N+1, indexes, connection pooling, serialization cost |
| Data / batch | injection into queries, PII handling, trust boundary of the input | streaming vs load-all, memory ceiling, per-row work |

## Step 3: Code Review (4 Parallel Subagents)

Launch 4 review subagents simultaneously (in ONE message), using `subagent_type: "br-qa"` — it declares `permissionMode: bypassPermissions` in its frontmatter, so reviews run without prompts.

`br-qa` may write **one** thing: its own report under `.bmad-ralph/logs/review-*.md`.
It must never touch source, tests, or config — not with `Write`, not with `Bash`.
Repeat that constraint in each of the 4 prompts below.

### Agent 1: Correctness Review
```
Read the sprint stories in .bmad-ralph/sprints/sprint-<N>.md.
For EACH story, verify:
- All acceptance criteria are met
- The implementation matches the architecture spec
- Edge cases are handled
- Error states are handled
Write findings to .bmad-ralph/logs/review-correctness-sprint-<N>.md
```

### Agent 2: Security Review
```
Review all files changed in this sprint (use git diff).

Check the dimensions selected in Step 2.5 for this project class — and write
"not applicable" for the ones that don't, instead of inventing a finding to fill a line.

Applicable whatever the class:
- secrets in code, in argv, or in logs
- input validation wherever external data enters the program
- the architecture's error strategy (§7) actually honored: an input the spec calls
  invalid must produce the specified error, not an uncaught exception
Then add the class-specific checks from the Step 2.5 table.
Write findings to .bmad-ralph/logs/review-security-sprint-<N>.md
```

### Agent 3: Performance Review
```
Review all files changed in this sprint.

Check the dimensions selected in Step 2.5 for this project class, and the NFRs the
architecture actually states. A performance finding with no number and no stated
requirement behind it is an opinion — leave it out.

Applicable whatever the class:
- resources closed and disposed
- no work that grows superlinearly with user-grown data
- no unbounded "fetch everything" on data that grows
Then add the class-specific checks from the Step 2.5 table.
Write findings to .bmad-ralph/logs/review-performance-sprint-<N>.md
```

### Agent 4: Architecture Compliance
```
Compare the implementation against .bmad-ralph/docs/architecture.md.
Check:
- File structure matches the architecture
- Dependencies flow in the right direction
- Naming conventions are consistent
- Patterns are used correctly (repository, service, etc.)
- No circular dependencies introduced
Write findings to .bmad-ralph/logs/review-architecture-sprint-<N>.md
```

## Step 3.5: Refactoring Assessment

Before synthesizing, assess whether the sprint's code needs refactoring:
- Are there duplicated patterns across stories that should be extracted into shared utilities?
- Are any files growing too large and should be split?
- Are there inconsistencies in naming, error handling, or patterns between stories?
If yes, add refactoring items as "Warning" level issues in the synthesis.

## Step 4: Synthesize Review

### Scoring Rubric — the score is COMPUTED, not felt

You are reviewing your own team's output; the pull toward "B, PASS" is real.
The score is therefore derived mechanically from the evidence:

| Score | Criteria (ALL must hold) |
|-------|--------------------------|
| A | Build+types+lint+tests all pass, every acceptance criterion of every story verified met, zero critical issues, ≤2 warnings |
| B | Build+types+lint+tests all pass, all acceptance criteria met, zero critical issues, warnings exist |
| C | Build+tests pass, but some acceptance criteria unverifiable or minor gaps; zero critical issues |
| D | Any verification step fails, OR any acceptance criterion clearly not met, OR ≥1 critical issue |
| F | Build/test suite broken, or a security-critical issue found |

**Issue severity is defined, not vibes:**
- **Critical** = wrong behavior a user would hit, a security hole, data loss, or a broken build — something that must not ship
- **Warning** = works but degrades quality (duplication, missing edge-case handling, pattern inconsistency)
- **Suggestion** = improvement with no current negative impact

**Every issue must carry evidence: `file:line` + one sentence of what happens.**
An issue without a location and a failure mode gets dropped, not reported.

### Every issue is a VIOLATION or a LACUNE — and they route differently

Severity says how bad an issue is. This says **who has to fix it**, and it is the whole
difference between closing a defect and chasing it.

One question per issue: **which line of the PRD or the architecture does this violate?**

- You can quote it → **VIOLATION**. The code broke a written requirement. It becomes a fix
  story and the sprint stays in `EXECUTE`.
- You cannot quote it → **LACUNE**. The code did what was specified; it is the
  specification that is missing or too vague. It becomes an **architecture amendment**,
  phase `ARCHITECT`. **Never a fix story.**

A fix story closes the instance you happened to see. A LACUNE dressed as a fix story is
how the same defect comes back wearing a new face at the next gate cycle — and the cycle
after that.

### Name the class, not the instance

For every issue, write the **class** it belongs to, not just where you found it:
"hostile input reaches a parser and raises instead of producing the specified error",
not "the amount 1e400 crashes the report".

Record the classes in `state.json`, in this sprint's entry:
`defect_classes: [{ "class": "<one line>", "cycles_seen": <n>, "status": "OPEN|CLOSED" }]`.
A class already listed gets `cycles_seen` incremented rather than a second entry.

**A class seen in two gate cycles stops producing fix stories.** It goes to `ARCHITECT`
with an explicit mandate: close the class, not today's instance. The report must then name
at least one form of that class that has **not** been observed yet and would still be open
if only today's findings were fixed. If you cannot name one, you have not found the class
yet — you are still looking at instances.

**Anti-rubber-stamp check:** if the four review agents collectively found zero
critical issues and fewer than 3 warnings, do not conclude "clean sprint" —
explicitly list what was checked and verify the two riskiest stories yourself
(read the diff, run their verification) before accepting that result.

After all agents complete, read all 4 review documents, apply the rubric, and create:

`.bmad-ralph/logs/review-sprint-<N>.md`:

```markdown
# Sprint <N> Review Report

## Overall Score: <A|B|C|D|F> — <one line citing which rubric row and why>

## Verification Results
- Build: PASS/FAIL
- Types: PASS/FAIL
- Lint: PASS/FAIL
- Tests: PASS/FAIL (<X>/<Y> passing)
- Coverage: <X>%

## Acceptance Criteria Coverage
- Stories fully verified: <X>/<Y>
- Criteria unverifiable (and why): <list or "none">

## Defect Classes (this cycle)
<class — VIOLATION or LACUNE — cycles seen — for a LACUNE, one form not yet observed>

## Critical Issues (must fix before next sprint)
<file:line — what happens — which story — VIOLATION (quote the requirement) or LACUNE>

## Warnings (should fix)
<file:line — what happens>

## Suggestions (nice to have)
<improvements for later>

## Escalated Stories
<stories that failed circuit breaker — need architect attention>

## Gate cycle: <n> / <max_gate_cycles>

## Quality Gate Decision: PASS / FAIL / CONDITIONAL_PASS / ESCALATED
```

## Step 5: Quality Gate Decision

### First: count this cycle

Increment this sprint's `gate_cycles` in `state.json`, and read `ralph.max_gate_cycles`
(default 3, configurable via `/br-config max-gate-cycles <N>`).

**If `gate_cycles` ≥ `max_gate_cycles`, stop here whatever the score.** There is a circuit
breaker per story; this is its counterpart at the gate, and it exists because four cycles
chasing four faces of one defect is a real observed failure, not a hypothesis.

Write `.bmad-ralph/logs/gate-escalation-sprint-<N>.md`: every open defect class, what was
attempted at each cycle, and which specification is missing. Set this sprint's
`quality_gate` to `"ESCALATED"`, leave `phase` at `REVIEW`, and hand back to the user with
the one decision that would unblock it. Never open cycle N+1 on your own.

### PASS (Score A or B, no critical issues)
1. Update state:
   - Add review to `deliverables.reviews`
   - Increment `metrics.quality_gate_passes`
   - Set this sprint's entry in the `sprints` array to `quality_gate: "PASS"`
   - If more sprints remain: set `phase` to `EXECUTE`, increment `current_sprint`
     (**this is the ONLY place `current_sprint` is incremented** — `/br-build`
     deliberately leaves it alone so the review targets the right sprint)
   - If last sprint: set `phase` to `DONE`
2. Say: "Quality gate PASSED. Sprint <N> is done."
   - If more sprints: "Run `/br-build` for Sprint <N+1>"
   - If last sprint: "PROJECT COMPLETE! All sprints implemented and reviewed."

### CONDITIONAL_PASS (Score C, minor issues)
0. **Split the issues first.** Only VIOLATIONs become fix stories. Any LACUNE — and any
   class already seen at a previous cycle — goes to `ARCHITECT` instead; if the sprint has
   both, route to `ARCHITECT` and let the amended architecture regenerate what it needs.
1. Generate fix stories for the VIOLATIONs, append them to the current sprint file
   (continue the story numbering: STORY-<N>.<last+1>, with files, instructions, acceptance
   criteria, and a verification command — same format as regular stories)
2. Update state:
   - Set phase back to `EXECUTE` (same sprint, do NOT increment `current_sprint`)
   - Set this sprint's entry to `quality_gate: "CONDITIONAL"` and `status: "IN_PROGRESS"`
   - Add the new stories to `metrics.stories_total` and the sprint's `stories_total`
3. Say: "Conditional pass. <X> minor issues to fix. Run `/br-build` to fix them."

### FAIL (Score D or F, critical issues)
1. Increment `metrics.quality_gate_failures` and set this sprint's entry to
   `quality_gate: "FAIL"` and `status: "IN_PROGRESS"`
2. Route by the nature of the issues, not by their number:
   - **Only VIOLATIONs** → fix stories (same bookkeeping as CONDITIONAL_PASS), stay in
     `EXECUTE` for the same sprint
   - **Any LACUNE, or any class at its second cycle** → `ARCHITECT`, with the mandate
     written out: which class to close, and which unobserved form of it must also be
     covered by the amendment
   - **The stories themselves are wrong** (instructions or verification command unable to
     express the requirement) → `SPRINT_PREP` to rewrite them
3. Say: "Quality gate FAILED. <reason>. Recommended action: <what to do>."

## Step 6: Handle Escalations

For each escalated story:
1. Read the escalation file
2. Determine if it's an architecture problem or implementation problem
3. If architecture → write a note to `.bmad-ralph/docs/architecture-amendments.md`
4. Create a fix story for the next sprint or the current sprint retry
