---
name: br-review
description: "Quality Gate Review — Validate sprint implementation against specs"
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

Execute in order:
1. **Build check**: Run the project build command
2. **Type check**: Run typecheck (tsc, mypy, etc.)
3. **Lint check**: Run linter
4. **Test suite**: Run all tests
5. **Coverage check**: Check test coverage if configured

Log all results.

## Step 3: Code Review (4 Parallel Subagents)

Launch 4 review subagents simultaneously (in ONE message), using `subagent_type: "br-qa"` — it is read-only and declares `permissionMode: bypassPermissions` in its frontmatter, so reviews run without prompts:

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
Check for:
- SQL injection vulnerabilities
- XSS possibilities
- Authentication/authorization gaps
- Secrets in code
- Input validation gaps
- OWASP Top 10 issues
Write findings to .bmad-ralph/logs/review-security-sprint-<N>.md
```

### Agent 3: Performance Review
```
Review all files changed in this sprint.
Check for:
- N+1 query patterns
- Missing database indexes
- Memory leaks (unclosed resources)
- Unnecessary re-renders (React)
- Missing caching opportunities
- Large payload sizes
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

## Critical Issues (must fix before next sprint)
<file:line — what happens — which story>

## Warnings (should fix)
<file:line — what happens>

## Suggestions (nice to have)
<improvements for later>

## Escalated Stories
<stories that failed circuit breaker — need architect attention>

## Quality Gate Decision: PASS / FAIL / CONDITIONAL_PASS
```

## Step 5: Quality Gate Decision

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
1. Generate fix stories, append them to the current sprint file (continue the
   story numbering: STORY-<N>.<last+1>, with files, instructions, acceptance
   criteria, and a verification command — same format as regular stories)
2. Update state:
   - Set phase back to `EXECUTE` (same sprint, do NOT increment `current_sprint`)
   - Set this sprint's entry to `quality_gate: "CONDITIONAL"` and `status: "IN_PROGRESS"`
   - Add the new stories to `metrics.stories_total` and the sprint's `stories_total`
3. Say: "Conditional pass. <X> minor issues to fix. Run `/br-build` to fix them."

### FAIL (Score D or F, critical issues)
1. Increment `metrics.quality_gate_failures` and set this sprint's entry to
   `quality_gate: "FAIL"` and `status: "IN_PROGRESS"`
2. Analyze if the failure is:
   - **Implementation issue** → Generate fix stories (same bookkeeping as
     CONDITIONAL_PASS), stay in EXECUTE for same sprint
   - **Architecture issue** → Set phase to `ARCHITECT` with a note about what needs redesigning
   - **Story issue** → Set phase to `SPRINT_PREP` to rewrite problematic stories
3. Say: "Quality gate FAILED. <reason>. Recommended action: <what to do>."

## Step 6: Handle Escalations

For each escalated story:
1. Read the escalation file
2. Determine if it's an architecture problem or implementation problem
3. If architecture → write a note to `.bmad-ralph/docs/architecture-amendments.md`
4. Create a fix story for the next sprint or the current sprint retry
