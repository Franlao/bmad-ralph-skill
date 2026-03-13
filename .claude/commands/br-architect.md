---
name: br-architect
description: "BMAD Architecture Phase — Design system architecture from PRD"
---

# BMAD-Ralph Architecture Phase (System Architect Agent)

## Pre-check
Read `.bmad-ralph/state.json`. Verify phase is `ARCHITECT`.

## Mission
You are now the **BMAD System Architect**. Design a complete, implementable architecture from the PRD.

## Input
Read:
- `.bmad-ralph/docs/prd.md`
- `.bmad-ralph/docs/business-brief.md`
- `.bmad-ralph/docs/discovery-technical.md`
- `.bmad-ralph/docs/discovery-codebase.md` (if exists)
- Existing codebase structure and patterns

## Critical Rule
**The architecture MUST be concrete enough for autonomous implementation.** Ralph Wiggum will execute this without human guidance. Every decision must be made here — no ambiguity.

## Generate Architecture Document

Write `.bmad-ralph/docs/architecture.md`:

```markdown
# System Architecture: <project_name>

## 1. Tech Stack Decision
| Layer | Technology | Justification |
|-------|-----------|---------------|
| Frontend | | |
| Backend | | |
| Database | | |
| Auth | | |
| Hosting | | |
| CI/CD | | |

## 2. Directory Structure
```
<exact directory tree that will be created>
```
Include EVERY file that needs to be created or modified.

## 3. Data Model
### 3.1 Entity Definitions
For each entity:
- Field name, type, constraints
- Relationships (1:1, 1:N, N:N)
- Indexes

### 3.2 Database Schema
Write the EXACT migration/schema code (Prisma, SQL, Drizzle, etc.)

## 4. API Design
For each endpoint:
- Method + Path
- Request body (with types)
- Response body (with types)
- Auth requirements
- Error responses
- Example request/response

## 5. Component Architecture
### 5.1 Backend Components
For each module/service:
- File path
- Responsibilities
- Dependencies (imports)
- Public interface (exported functions/classes)

### 5.2 Frontend Components (if applicable)
For each component:
- File path
- Props interface
- State management
- Child components

## 6. Authentication & Authorization
- Auth flow diagram (text)
- Token management strategy
- Permission model

## 7. Error Handling Strategy
- Error types and codes
- Global error handler pattern
- User-facing error messages

## 8. Testing Strategy
- Unit test patterns (example)
- Integration test patterns (example)
- E2E test approach
- Minimum coverage target

## 9. File Dependency Graph
Show which files import from which, so Ralph can implement them in the RIGHT ORDER (dependencies first).

```
Layer 1 (no deps):     config.ts, types.ts, constants.ts
Layer 2 (deps: L1):    db/schema.ts, lib/errors.ts
Layer 3 (deps: L1-2):  repositories/*.ts
Layer 4 (deps: L1-3):  services/*.ts
Layer 5 (deps: L1-4):  routes/*.ts, components/*.tsx
Layer 6 (deps: L1-5):  pages/*.tsx, app.ts
Layer 7 (integration):  tests/*.test.ts
```

## 10. Implementation Order
Explicit ordered list of what to build first:
1. <file/module> — because <reason>
2. <file/module> — depends on #1
...
```

## Architecture Validation

After writing the architecture, validate it by checking:
- [ ] Every user story from the PRD is covered
- [ ] Every API endpoint has a corresponding implementation file
- [ ] Every data entity has a schema definition
- [ ] The dependency graph has no circular dependencies
- [ ] The testing strategy covers all critical paths
- [ ] Auth is specified for every protected resource

## After Completion

1. Update `.bmad-ralph/state.json`:
   - Set `phase` to `SPRINT_PREP`
   - Add `"ARCHITECT"` to `phases_completed`
   - Set `deliverables.architecture` to `.bmad-ralph/docs/architecture.md`

2. Present: key architecture decisions, tech stack, estimated file count.

3. Say: "Architecture complete. Run `/project:br-sprint` to break this into implementable sprint stories."
