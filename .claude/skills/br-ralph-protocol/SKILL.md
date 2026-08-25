---
name: br-ralph-protocol
description: "The Ralph loop contract — how one story gets implemented, verified, counted and escalated. Shared by /br-build, /br-resume, /br-fix and the br-developer agent."
user-invocable: false
---

# The Ralph Protocol

The rules that govern **one story**, from picking it up to committing it or escalating it.
This is the single source of truth: `/br-build` orchestrates it, `br-developer` executes it,
`/br-resume` and `/br-fix` re-enter it. If you are reading this, it applies to you.

Anything specific to one caller — sprint branches, merges, quality gates, state bookkeeping
of the sprint — stays with that caller and is NOT repeated here.

## The loop

**A — Pre-flight.** Read the story from the sprint file, including its **Interface
Contract** if present: the exported names and signatures it declares are commitments other
stories are built against, implement them EXACTLY as written. Check that every dependency
story is committed (`git log`); if not, skip and come back later.

**B — Gather context before writing any code.**

1. Read `.bmad-ralph/docs/architecture.md` — patterns, types, conventions. Section 1.1
   (Decision Records): the "Rejected" alternatives are OFF LIMITS, never reintroduce them.
   Section 7b (Configuration & Environment) is the only source of truth for env vars.
2. Read every file the story will touch, and the committed code of its dependency stories.
3. Check the dependency manifest (`package.json`, `cargo.toml`, `pyproject.toml`, ...)
   before planning to use ANY library — never assume one is available, even a famous one.
4. Before proceeding, answer: do I know every file to create or modify? the exact
   types/interfaces? how this connects to the rest? are all libraries actually installed?
   Any "no" means keep reading code.

**C — Library & API currency** (before writing code that touches any library).

Your memory of library APIs is stale by definition — training data ages, libraries don't.

1. Read the exact installed version from the **lockfile** (`package-lock.json`,
   `poetry.lock`, `Cargo.lock`, ...), not the manifest range.
2. Look up the docs FOR THAT VERSION for any API you are not 100% certain of: context7 MCP
   if available, else WebFetch on the official docs, else the library's own `.d.ts`/source
   in `node_modules` — ground truth, always available.
3. Where memory fails silently: framework/router APIs across majors (Next.js, React
   Router), ORM query syntax (Prisma, Drizzle, SQLAlchemy 1→2), config file formats,
   defaults that flipped between versions.
4. If the API you remember no longer exists, use the current one. Do NOT pin an older
   version to match your memory — that is a dependency decision the architecture never
   made. Escalate if genuinely blocked.

**D — Implement** exactly as the story's instructions specify. Follow the existing
patterns (imports, naming, error handling) instead of inventing new ones. Before writing
any helper, Grep the codebase for an existing one *by concept, not just by name* —
duplicating a helper is a bug, not a style issue, because the copies will diverge.

**E — Verify.** Run the story's Verification Command. For lint and typecheck, use the
commands recorded in `state.json` under `toolchain` — they were verified by running them,
your memory of the project's conventions was not. Run them **even
if it passed**, detecting the commands from `package.json` scripts or project config
(`ruff`, `cargo clippy`, `mypy`, ...). Fix what they report; never skip or suppress.

**F — Self-critique.** Read your own `git diff` as if reviewing a stranger's PR — you catch
different bugs reading than writing — and check it against the Quality Bar below. Then:
did I implement ALL acceptance criteria, not just some? did I touch a file outside the
story's list without a reason? does this follow the architecture doc? if the story has a
performance criterion, did I MEASURE it and report the number?

## Quality Bar

**Correctness at the boundaries.** Input validation where user or external data enters;
explicit behavior for null/empty/error, not just the happy path; errors handled per the
architecture's error strategy and never swallowed silently.

**Performance — verifiable rules, not vibes.**
- No N+1: anything fetching in a loop gets batched, joined or preloaded.
- No O(n²) or worse on data that grows with usage — fine on a small fixed set, a time bomb
  on user data.
- Queries on filtered/sorted fields use the indexes the architecture defined; SELECT only
  the needed fields on large tables.
- Lists that can grow are paginated or limited — never "fetch all" on user data.
- No blocking I/O in hot paths; no `await` in a loop when the calls are independent.
- Resources closed and disposed (connections, file handles, subscriptions, listeners).
- **But no premature optimization**: no cache, memoization or clever data structure without
  a requirement or a measurement. An unjustified cache is a bug factory (invalidation),
  not a speedup.

**Simplicity.** The straightforward implementation first; abstractions only when the story
or the architecture calls for them. No dead code, no unused imports, no "just in case"
parameters. No comments unless the logic is genuinely non-obvious and renaming can't fix
it. Never import from a higher layer than the dependency graph allows.

## When verification fails

**Step back before patching.** The root cause is almost always the implementation, not the
test or the verification command.

1. Read the FULL error output — do not skim.
2. Reason about the root cause before touching anything: is the error in the file just
   written, or somewhere unexpected? was a defining file never read? is it a type error, a
   logic error, or an environment problem (missing package, missing env var)?
3. Fix ONLY what is broken, re-reading the relevant code first.
4. Re-run the verification.

## Counting failures — the state file, never memory

`.bmad-ralph/state.json` is the source of truth for how many times a story has failed.
Conversation memory is not: it does not survive a context compaction, and a lost count
means a story retries forever.

- Read `ralph.current_story`, `ralph.current_attempt` and `ralph.circuit_breaker_threshold`
  from the state file. The threshold is user-configurable via
  `/br-config circuit-breaker <N>` — **never hardcode it**, not even as "3".
- If `ralph.current_story` is not this story, set it and reset `ralph.current_attempt` to 0.
- Increment `ralph.current_attempt` and write it back **before** retrying.
- `current_attempt` < threshold → fix the root cause (not a patch) and retry from step D.
- `current_attempt` ≥ threshold → escalate, then reset `ralph.current_attempt` to 0.
- Hard cap: if total attempts on this story reach `ralph.max_iterations_per_story`,
  escalate regardless. This only bites when the threshold was raised above the cap.

## Escalation

When the circuit breaker trips, write `.bmad-ralph/logs/escalation-STORY-<N.M>.md`:

```markdown
# Escalation: STORY-<N.M>

## Story Description
<from the sprint file>

## Attempt <i>
- Action taken: <what was implemented or changed>
- Error: <exact error output>
<one block per attempt>

## Root Cause Analysis
<why this keeps failing>

## Recommendation
<what must change in the architecture or in the story for this to work>
```

Then increment `metrics.escalations_to_architect` and **move on to the next story**. Do not
keep retrying: the escalation is triaged at the quality gate, which decides between an
architecture amendment, rewritten stories, or fix stories.

An agent that cannot write state files reports the same thing to its caller instead:

```
ESCALATE: STORY-X.Y
Root cause: <analysis>
Attempts: <what was tried>
Recommendation: <what needs to change>
```

## Committing

One story that passes = one commit, and nothing else in it:

```bash
git add <the story's files> && git commit -m "feat(sprint-<N>): STORY-<N.M> <title>"
```

That commit is the checkpoint the whole pipeline relies on — `/br-resume`, `/br-status`,
`/br-rollback` and the pre-flight check all detect completed stories by this message
pattern. A story whose work is left uncommitted is a story that will be redone.

## Never

- Modify a test to make it pass — fix the implementation.
- Use `any`, `@ts-ignore` or an equivalent silencer.
- Add a dependency the architecture didn't specify.
- Invent an env var: if a config value isn't in architecture section 7b, that's an
  architecture gap → escalate, don't hardcode.
- Change the architecture to fit the implementation → escalate.
- Deviate from a story's Interface Contract — dependent stories are built against it.
- Touch files outside the story's list without a stated reason.
