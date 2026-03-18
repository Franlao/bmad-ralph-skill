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

Launch 4 review subagents simultaneously. **Set `mode: "bypassPermissions"` on ALL Agent calls** for fully autonomous execution:

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

After all agents complete, read all 4 review documents and create:

`.bmad-ralph/logs/review-sprint-<N>.md`:

```markdown
# Sprint <N> Review Report

## Overall Score: <A|B|C|D|F>

## Verification Results
- Build: PASS/FAIL
- Types: PASS/FAIL
- Lint: PASS/FAIL
- Tests: PASS/FAIL (<X>/<Y> passing)
- Coverage: <X>%

## Critical Issues (must fix before next sprint)
<issues that block progress>

## Warnings (should fix)
<issues that degrade quality but don't block>

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
   - If more sprints remain: set `phase` to `EXECUTE`, increment `current_sprint`
   - If last sprint: set `phase` to `DONE`
2. Say: "Quality gate PASSED. Sprint <N> is done."
   - If more sprints: "Run `/project:br-build` for Sprint <N+1>"
   - If last sprint: "PROJECT COMPLETE! All sprints implemented and reviewed."

### CONDITIONAL_PASS (Score C, minor issues)
1. Generate fix stories and append to current sprint
2. Update state: set phase back to `EXECUTE` (same sprint)
3. Say: "Conditional pass. <X> minor issues to fix. Run `/project:br-build` to fix them."

### FAIL (Score D or F, critical issues)
1. Increment `metrics.quality_gate_failures`
2. Analyze if the failure is:
   - **Implementation issue** → Generate fix stories, stay in EXECUTE for same sprint
   - **Architecture issue** → Set phase to `ARCHITECT` with a note about what needs redesigning
   - **Story issue** → Set phase to `SPRINT_PREP` to rewrite problematic stories
3. Say: "Quality gate FAILED. <reason>. Recommended action: <what to do>."

## Step 6: Handle Escalations

For each escalated story:
1. Read the escalation file
2. Determine if it's an architecture problem or implementation problem
3. If architecture → write a note to `.bmad-ralph/docs/architecture-amendments.md`
4. Create a fix story for the next sprint or the current sprint retry
