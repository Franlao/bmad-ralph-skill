# Project Conventions (BMAD-Ralph)

## State Management
- State file: `.bmad-ralph/state.json` — source of truth for project phase and progress
- Never modify state.json manually — use `/project:br-*` commands
- Update `last_updated_at` after every state change

## Development Rules
- ALWAYS read and understand code BEFORE modifying it
- ALWAYS run tests after implementing a story
- Follow the architecture doc at `.bmad-ralph/docs/architecture.md`
- Respect the file dependency graph — implement dependencies first
- Write clean, minimal code — no over-engineering

## Git Conventions
- Branch per sprint: `bmad/sprint-N`
- One commit per completed story: `feat(sprint-N): STORY-N.M <title>`
- Never force-push or reset --hard
- Merge sprint branches back to base with `--no-ff`

## Testing
- Run verification commands from sprint stories before committing
- Never modify test files to make tests pass — fix the implementation
- Run full sprint verification after all stories complete

## Safety
- Never modify `.env`, credential, or key files
- The br-guard.sh hook blocks dangerous operations automatically
- Circuit breaker: 3 failures on same story triggers escalation
- Max 40 iterations per sprint — pause and report if reached

## File Structure
- `.bmad-ralph/docs/` — planning documents (brief, PRD, architecture)
- `.bmad-ralph/sprints/` — sprint story files with implementation instructions
- `.bmad-ralph/prompts/` — Ralph execution prompts (auto-generated)
- `.bmad-ralph/logs/` — execution logs, reviews, escalations (gitignored)

## Agent Permissions
- All agents run with `bypassPermissions` for fully autonomous execution
- Guard hook provides safety layer — no need for manual approval
- QA agents are read-only — they report issues but never modify code
