---
name: br-discover
description: "BMAD Discovery Phase — parallel research with specialized subagents"
model: opus
---

# BMAD-Ralph Discovery Phase

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `DISCOVER`. If not, explain the current phase and what to do.

## Mission
Launch **4 parallel research subagents** to analyze the project from every angle. This is the BMAD Business Analyst role.

## Critical Rule
**NEVER guess or assume — every finding must be rooted in actual research.** If you cannot find information through codebase exploration or web search, state what is unknown rather than inventing an answer. Wrong assumptions in discovery propagate into wrong architecture, wrong stories, and failed sprints.

**Every claim in a discovery doc must be tagged:**
- `[FACT — source]` — verified via web search, docs, or the codebase (link/file the source)
- `[ASSUMPTION]` — plausible but unverified; the plan must not silently depend on these
- `[UNKNOWN]` — could not be determined; note what would resolve it

Numbers are the biggest fabrication risk: market sizes, user counts, adoption
stats. Never produce a number without a source. "No reliable figure found" is a
valid — and better — answer than an invented one.

## Scale Discovery to the Project Type

Not every project needs market research. Before launching agents, classify the
project from state.json and the brief:

- **Commercial / user-facing product** → all 4 agents
- **Internal tool, personal project, or technical utility** → skip Agent 1
  (market) and Agent 2 (competitive); replace them with a single "Prior Art"
  agent (does an existing library/tool already solve this? build vs. reuse),
  then run Agents 3 and 4
- **Feature added to an existing product** → skip Agent 1; run 2, 3, 4 with the
  feature (not the whole product) as the subject

State which mode you chose and why, in one line. Running a market analysis on
someone's internal CLI wastes tokens and produces fiction.

## Execute the Research Streams in Parallel

**MAXIMIZE EFFICIENCY**: Launch the selected agents **simultaneously** in a single message. Never make sequential agent calls when they can be batched.

**IMPORTANT**: Research subagents only need read-only tools (Read, Glob, Grep, WebSearch, WebFetch), so they run without permission prompts — the Agent tool has no per-call permission parameter anyway.

### Agent 1: Market & Problem Analysis
```
Analyze the project described in .bmad-ralph/state.json and .bmad-ralph/docs/brief-template.md.
Research (use WebSearch — do not answer from memory):
- What problem does this solve?
- Who are the target users? Create 2-3 user personas grounded in what you found.
- Market opportunity: cite sources, or write "no reliable figure found" — NEVER invent numbers.
- What are the key user pain points? (forums, reviews, comparable-product complaints)
Tag every claim [FACT — source] / [ASSUMPTION] / [UNKNOWN].
Write your findings to .bmad-ralph/docs/discovery-market.md
```

### Agent 2: Competitive Analysis
```
Based on the project in .bmad-ralph/state.json:
- Identify 3-5 competing products or solutions (verify they exist via WebSearch — no invented competitors)
- List their strengths and weaknesses, with sources (their sites, docs, reviews)
- Identify gaps and opportunities for differentiation
- Note pricing models and monetization strategies (from their actual pricing pages)
Tag every claim [FACT — source] / [ASSUMPTION] / [UNKNOWN].
Write your findings to .bmad-ralph/docs/discovery-competitive.md
```

### Agent 3: Technical Feasibility
```
Analyze the project in .bmad-ralph/state.json and the existing codebase:
- What is the current tech stack? Is it appropriate?
- What external APIs/services are needed?
- What are the technical risks and unknowns?
- Estimate complexity (simple/medium/complex/very complex)
- Identify potential performance bottlenecks
- List required third-party dependencies
- Read package.json/cargo.toml/pyproject.toml to know EXACTLY what is already installed
- Use web search if you need current API docs or latest versions — never assume from memory
Write your findings to .bmad-ralph/docs/discovery-technical.md
```

### Agent 4: Existing Codebase Analysis (skip entirely on a greenfield project — an empty repo needs no codebase agent)
```
Explore the existing codebase thoroughly:
- Map the directory structure and architecture patterns
- Identify existing patterns (repo pattern, service layer, etc.)
- Find existing tests and testing patterns
- Note code conventions (naming, imports, error handling)
- Identify reusable components/modules
- Find potential integration points for new features
Write your findings to .bmad-ralph/docs/discovery-codebase.md
```

## After All Agents Complete

1. Read all discovery documents produced
2. Write a consolidated `.bmad-ralph/docs/business-brief.md` that synthesizes all findings into:
   - **Executive Summary** (3-5 sentences)
   - **Problem Statement**
   - **User Personas** (from market research)
   - **Competitive Landscape** (from competitive analysis)
   - **Technical Assessment** (from feasibility study)
   - **Codebase Integration Points** (from codebase analysis)
   - **Risks & Mitigations**
   - **Recommended Approach**

3. Update `.bmad-ralph/state.json`:
   - Set `phase` to `PLAN`
   - Add `"DISCOVER"` to `phases_completed`
   - Set `deliverables.business_brief` to `.bmad-ralph/docs/business-brief.md`

4. Present the business brief summary to the user and say:
   "Discovery complete. Review the brief above. When ready, run `/br-plan` to generate the PRD."
