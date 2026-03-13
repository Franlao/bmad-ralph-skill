---
name: br-deploy
description: "Generate deployment artifacts — Dockerfile, CI/CD, deploy instructions"
---

# BMAD-Ralph Deployment Phase

Generate deployment artifacts after the project is built. Works at any phase but best used after `DONE` or after a successful sprint review.

**IMPORTANT**: Use `mode: "bypassPermissions"` on all Agent tool calls for autonomous execution.

## Arguments

- `$ARGUMENTS` empty → generate all deployment artifacts
- `$ARGUMENTS` = `docker` → Dockerfile + .dockerignore only
- `$ARGUMENTS` = `ci` → CI/CD pipeline only
- `$ARGUMENTS` = `guide` → deployment guide only
- `$ARGUMENTS` = `all` → everything

## Step 1: Analyze Project

Read:
- `.bmad-ralph/docs/architecture.md` → tech stack, dependencies
- `.bmad-ralph/state.json` → project info
- `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` → exact dependencies
- Existing CI/CD files (`.github/workflows/`, `Dockerfile`, etc.)

## Step 2: Generate Dockerfile

Detect stack and generate appropriate multi-stage Dockerfile:

### Node.js / TypeScript
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Python (FastAPI/Django/Flask)
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml poetry.lock* requirements*.txt ./
RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || pip install .
COPY . .

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Also generate `.dockerignore`:
```
node_modules
.bmad-ralph
.git
.claude
*.log
.env*
```

## Step 3: Generate CI/CD Pipeline

Detect platform and generate:

### GitHub Actions (default)
Write `.github/workflows/ci.yml`:
```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4  # or setup-python, etc.
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t ${{ github.repository }} .

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Add your deployment steps here
      - run: echo "Deploy step — configure for your platform"
```

Adapt the pipeline to the detected tech stack (Python → setup-python, Go → setup-go, etc.).

## Step 4: Generate Deployment Guide

Write `.bmad-ralph/docs/deploy-guide.md`:

```markdown
# Deployment Guide: <project_name>

## Prerequisites
- <runtime> installed (version X+)
- <database> running
- Environment variables configured

## Environment Variables
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| DATABASE_URL | Yes | Database connection string | postgresql://... |
| JWT_SECRET | Yes | Token signing secret | <random 32+ chars> |
| PORT | No | Server port (default: 3000) | 3000 |

## Database Setup
```bash
<migration command>
```

## Build & Run
```bash
# Development
<dev command>

# Production
<build command>
<start command>
```

## Docker
```bash
docker build -t <project> .
docker run -p 3000:3000 --env-file .env <project>
```

## Recommended Hosting
Based on the tech stack:
- <option 1> — <why>
- <option 2> — <why>
- <option 3> — <why>

## Monitoring
- Health endpoint: GET /health
- Logs: <where to find logs>
```

## Step 5: Display Summary

```
DEPLOYMENT ARTIFACTS GENERATED
═══════════════════════════════════════════

  [x] Dockerfile                    (multi-stage, optimized)
  [x] .dockerignore
  [x] .github/workflows/ci.yml     (test + build + deploy)
  [x] deploy-guide.md              (env vars, commands, hosting)

  Next steps:
  1. Copy .env.example to .env and fill in values
  2. Run: docker build -t my-app .
  3. Push to GitHub to trigger CI/CD
  4. Configure deploy step in ci.yml for your hosting
```
