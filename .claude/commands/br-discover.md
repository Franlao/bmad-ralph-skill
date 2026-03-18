---
name: br-discover
description: "BMAD Discovery Phase — parallel research with specialized subagents"
---

# BMAD-Ralph Discovery Phase

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `DISCOVER`. If not, explain the current phase and what to do.

## Mission
Launch **4 parallel research subagents** to analyze the project from every angle. This is the BMAD Business Analyst role.

## Critical Rule
**NEVER guess or assume — every finding must be rooted in actual research.** If you cannot find information through codebase exploration or web search, state what is unknown rather than inventing an answer. Wrong assumptions in discovery propagate into wrong architecture, wrong stories, and failed sprints.

## Execute 4 Parallel Research Streams

**MAXIMIZE EFFICIENCY**: Launch all 4 agents **simultaneously** in a single message with 4 tool calls. Never make sequential agent calls when they can be batched.

**IMPORTANT**: Set `mode: "bypassPermissions"` on ALL Agent calls so they run fully autonomously without prompting the user.

### Agent 1: Market & Problem Analysis
```
Analyze the project described in .bmad-ralph/state.json and .bmad-ralph/docs/brief-template.md.
Research:
- What problem does this solve?
- Who are the target users? Create 2-3 user personas.
- What is the market size/opportunity?
- What are the key user pain points?
Write your findings to .bmad-ralph/docs/discovery-market.md
```

### Agent 2: Competitive Analysis
```
Based on the project in .bmad-ralph/state.json:
- Identify 3-5 competing products or solutions
- List their strengths and weaknesses
- Identify gaps and opportunities for differentiation
- Note pricing models and monetization strategies
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

### Agent 4: Existing Codebase Analysis (if applicable)
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

1. Read all 4 discovery documents
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
   "Discovery complete. Review the brief above. When ready, run `/project:br-plan` to generate the PRD."
