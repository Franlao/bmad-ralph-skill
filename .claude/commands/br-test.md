---
name: br-test
description: "Run tests — auto-detect framework, show results, track coverage"
argument-hint: "[coverage | watch | story STORY-X.Y | sprint N]"
model: sonnet
---

# BMAD-Ralph Test Runner

Run project tests with auto-detection of the test framework.

## Arguments

- `$ARGUMENTS` empty → run all tests
- `$ARGUMENTS` = `story STORY-X.Y` → run only that story's verification command
- `$ARGUMENTS` = `sprint N` → run sprint N's verification command
- `$ARGUMENTS` = `coverage` → run with coverage report
- `$ARGUMENTS` = `watch` → run in watch mode (interactive)

## Step 1: Detect Test Framework

Check in order:

### JavaScript/TypeScript
- `package.json` → read `scripts.test`
- `vitest.config.*` exists → `npx vitest run`
- `jest.config.*` exists → `npx jest`
- `node_modules/.bin/mocha` exists → `npx mocha`

### Python
- `pyproject.toml` with `[tool.pytest]` → `pytest`
- `pytest.ini` or `setup.cfg` with pytest → `pytest`
- `manage.py` exists → `python manage.py test`

### Rust
- `Cargo.toml` → `cargo test`

### Go
- `go.mod` → `go test ./...`

### Architecture Override
- Read `.bmad-ralph/docs/architecture.md` → look for "Testing Strategy" section for a custom test command

If no framework detected, ask the user for the test command.

## Step 2: Run Tests

### All tests (no arguments)
Run the detected test command and capture output.

### Story test
1. Read the story from `.bmad-ralph/sprints/sprint-<N>.md`
2. Find the `Verification Command` section
3. Run that exact command

### Sprint test
1. Read `.bmad-ralph/sprints/sprint-<N>.md`
2. Find the `Sprint Verification` section at the bottom
3. Run that command (typically build + lint + test)

### Coverage
Append coverage flag to detected command:
- vitest → `npx vitest run --coverage`
- jest → `npx jest --coverage`
- pytest → `pytest --cov`
- cargo → `cargo tarpaulin`
- go → `go test -cover ./...`

## Step 3: Display Results

Parse test output and display:

```
BMAD-RALPH TEST RUNNER
═══════════════════════════════════════════

  Framework:   vitest (from package.json)
  Command:     npx vitest run

  Results:
    Tests:     23 passed, 2 failed, 25 total
    Suites:    8 passed, 1 failed, 9 total
    Duration:  4.2s

  Failed tests:
    ✗ src/services/invoice.test.ts > createInvoice > should validate amount
      Expected: 100
      Received: undefined

    ✗ src/routes/auth.test.ts > login > should return 401 on bad password
      Expected status: 401
      Received status: 500

  Likely stories affected:
    STORY-2.3 "Invoice service" → invoice.test.ts
    STORY-1.5 "Auth endpoints"  → auth.test.ts

  Status: FAIL (2 failures)
```

## Step 4: Story Matching

When tests fail, try to match failing test files to sprint stories:
1. Read current sprint file
2. For each story, check if the failing test file is in the story's file list
3. Display the likely story responsible

This helps the user know which story to fix or retry.
