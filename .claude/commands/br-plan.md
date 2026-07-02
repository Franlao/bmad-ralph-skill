---
name: br-plan
description: "BMAD Planning Phase — Generate PRD from discovery findings"
model: opus
---

# BMAD-Ralph Planning Phase (Product Manager Agent)

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `PLAN`. If not, explain what to do.

## Mission
You are now the **BMAD Product Manager**. Generate a comprehensive PRD from the discovery findings.

## First: Restate the User's Intent

Before writing anything, **restate in one paragraph what the user is ACTUALLY asking for** — not what you think they might want, not an expanded version. Base this on the original project description in `state.json` and the business brief. If the scope seems unclear, flag it and keep the PRD focused on what was explicitly requested. Do not add features the user didn't ask for.

## Input
Read these files:
- `.bmad-ralph/docs/business-brief.md`
- `.bmad-ralph/state.json`
- Any existing CLAUDE.md or project docs

## Generate PRD

Write `.bmad-ralph/docs/prd.md` with this structure:

```markdown
# Product Requirements Document: <project_name>

## 1. Overview
### 1.1 Product Vision
### 1.2 Problem Statement
### 1.3 Target Audience

## 2. Goals & Success Metrics
### 2.1 Business Goals
### 2.2 User Goals
### 2.3 Key Metrics (KPIs)
### 2.4 Definition of Done

## 3. User Stories
For each feature, write user stories in format:
**US-<number>**: As a <persona>, I want to <action>, so that <benefit>.
- Acceptance Criteria:
  - [ ] AC1
  - [ ] AC2
- Priority: P0 (must-have) | P1 (should-have) | P2 (nice-to-have)
- Estimated Complexity: S | M | L | XL

## 4. Functional Requirements
### 4.1 Core Features (P0)
### 4.2 Secondary Features (P1)
### 4.3 Future Features (P2 — out of scope for v1)

## 5. Non-Functional Requirements
### 5.1 Performance
### 5.2 Security
### 5.3 Accessibility
### 5.4 Scalability

## 6. Data Model (High Level)
- Key entities and relationships
- Data flow overview

## 7. API Surface (High Level)
- Key endpoints or interfaces needed

## 8. UI/UX Requirements
- Key screens/pages
- User flows (happy path)
- Error states

## 9. Dependencies & Risks
### 9.1 External Dependencies
### 9.2 Technical Risks
### 9.3 Mitigation Strategies

## 10. Release Plan
### 10.1 MVP Scope (Sprint 1-2)
### 10.2 V1.0 Scope (Sprint 3-4)
### 10.3 Future Roadmap
```

## Prioritization Intelligence

When writing user stories:
- **P0**: Features without which the product is useless
- **P1**: Features that make the product competitive
- **P2**: Features that delight but aren't essential
- Sort stories by dependency order within each priority

**P0 discipline:** P0 is the set without which you would NOT ship — if more
than ~40% of stories are P0, you are not prioritizing, you are labeling.
Re-challenge each P0: "would we really hold the release for this?" Demote until
the answer is yes for every remaining one.

## Quality Rules for the PRD Content

- **Traceability**: every user story must trace to a problem or persona in the
  business brief. A story that traces to nothing is invented scope — cut it or
  flag it to the user.
- **KPIs must be measurable as written**: "page loads in <2s on 3G" is a KPI;
  "fast and responsive" is not. Same for NFRs — give numbers or drop the claim.
- **Acceptance criteria must be checkable by a program or a test** — prefer
  Given/When/Then. "Works correctly" is not a criterion.
- **Assumptions carried from discovery**: if the brief tagged something
  [ASSUMPTION] and the PRD depends on it, restate it in section 9 (Risks) —
  don't silently launder an assumption into a requirement.

## Sprint Estimation

At the bottom of the PRD, add a rough sprint estimate:
```markdown
## Sprint Estimate
- Total User Stories: <count>
- P0 Stories: <count> → Sprint 1-2
- P1 Stories: <count> → Sprint 3-4
- Estimated Total Sprints: <number>
- Estimated Ralph Iterations per Sprint: <number>
```

## After Completion

1. Update `.bmad-ralph/state.json`:
   - Set `phase` to `ARCHITECT`
   - Add `"PLAN"` to `phases_completed`
   - Set `deliverables.prd` to `.bmad-ralph/docs/prd.md`
   - Do NOT touch `metrics.stories_total` — it counts implementation stories
     and is owned by `/br-sprint` (PRD user stories live in the PRD itself)

2. Present a summary: story count by priority, sprint estimate, key features.

3. Say: "PRD complete. Review it above. When ready, run `/br-architect` to design the system architecture."
