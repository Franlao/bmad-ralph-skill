---
name: br-mcp
description: "Install and configure MCP servers — context7, playwright, DB, linting, and more"
---

# BMAD-Ralph MCP Manager

Install relevant MCP servers so Ralph has access to live library docs, browser testing, database tools, and more during autonomous execution.

## Arguments

- `$ARGUMENTS` empty → auto-detect stack and install recommended MCPs
- `$ARGUMENTS` = `list` → show installed and available MCPs
- `$ARGUMENTS` = `add <name>` → install a specific MCP
- `$ARGUMENTS` = `remove <name>` → remove a MCP server
- `$ARGUMENTS` = `all` → install ALL recommended MCPs for detected stack
- `$ARGUMENTS` = `minimal` → install only context7 (lightweight)
- `$ARGUMENTS` = `status` → check which MCPs are running

## MCP Catalog

### TIER 1 — Essential (auto-installed by br-init)

| Name | Package | Free | What it does |
|------|---------|------|-------------|
| **context7** | `@upstash/context7-mcp` | Yes | Live docs for ANY library. Ralph looks up current APIs instead of guessing. |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | Yes | Structured step-by-step reasoning for complex architecture decisions and debugging. |
| **fetch** | `@modelcontextprotocol/server-fetch` | Yes | Fetch any web page as markdown. Read docs, READMEs, Stack Overflow answers. |

### TIER 2 — Recommended (install per project need)

| Name | Package | Free | What it does |
|------|---------|------|-------------|
| **playwright** | `@playwright/mcp` | Yes | Browser automation + E2E testing. Microsoft official. |
| **github** | Remote HTTP | Yes | PRs, issues, code review via GitHub API. OAuth. |
| **postgres** | `@bytebase/dbhub` | Yes | Database schema exploration + queries. Multi-DB support. |
| **memory** | `@modelcontextprotocol/server-memory` | Yes | Persistent knowledge graph across sessions. |
| **eslint** | `@eslint/mcp` | Yes | JS/TS linting with project ESLint config. |
| **vitest** | `@djankies/vitest-mcp` | Yes | AI-optimized test runner with coverage. |

### TIER 3 — Specialized

| Name | Package | Free | What it does |
|------|---------|------|-------------|
| **brave-search** | `@modelcontextprotocol/server-brave-search` | Free tier | Web search (2000 queries/month free). Needs API key. |
| **sentry** | Remote HTTP | Yes | Error monitoring, stack traces, root cause analysis. |
| **supabase** | Remote HTTP | Yes | Full backend: DB, auth, storage, edge functions. |
| **neon** | Remote HTTP | Yes | Serverless Postgres with branching. |
| **e2b** | `@e2b/mcp-server` | Free tier | Cloud sandbox for safe code execution. |
| **kubernetes** | `mcp-server-kubernetes` | Yes | K8s pod/deployment management. |

## Step 1: Detect Stack and Pick MCPs

Read `.bmad-ralph/state.json` for `project.tech_stack`. Then select MCPs:

| Stack | Auto-install | Recommend |
|-------|-------------|-----------|
| **All projects** | context7, sequential-thinking, fetch | memory |
| **TypeScript/Node** | + eslint, vitest | playwright |
| **Python** | (context7 covers it) | postgres if using DB |
| **React/Next.js** | + eslint | playwright for E2E |
| **With PostgreSQL** | + postgres (dbhub) | |
| **GitHub repo** | + github | sentry |

## Step 2: Install MCPs

Detect OS (Windows vs Linux/Mac) and install using `claude mcp add`:

### Tier 1 — Always install

```bash
# Context7 — live library documentation
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest

# Sequential Thinking — structured reasoning
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# Fetch — read any web page
claude mcp add fetch -- npx -y @modelcontextprotocol/server-fetch
```

### Tier 2 — Based on stack

```bash
# Playwright — browser testing (TypeScript/React projects)
claude mcp add playwright -- npx -y @playwright/mcp@latest

# GitHub — PRs, issues (if .git/config has github remote)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# PostgreSQL — database tools (if project uses PostgreSQL)
claude mcp add postgres -- npx -y @bytebase/dbhub --dsn "${DATABASE_URL}"

# Memory — persistent knowledge graph
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory

# ESLint — JS/TS linting (if package.json has eslint)
claude mcp add eslint -- npx -p @eslint/mcp@latest -p jiti -c mcp

# Vitest — test runner (if vitest in devDependencies)
claude mcp add vitest -- npx -y @djankies/vitest-mcp
```

### Fallback — Manual .mcp.json

If `claude mcp add` fails, create/update `.mcp.json` in project root.

**Linux/Mac:**
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
```

**Windows:**
```json
{
  "mcpServers": {
    "context7": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@upstash/context7-mcp@latest"]
    },
    "sequential-thinking": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
```

## Step 3: Verify

```bash
claude mcp list
```

Display:
```
MCP SERVERS INSTALLED
═══════════════════════════════════════════════════

  TIER 1 (Essential):
    [x] context7              Live library docs
    [x] sequential-thinking   Structured reasoning
    [x] fetch                 Web page reader

  TIER 2 (Stack-specific):
    [x] eslint                JS/TS linting
    [x] vitest                Test runner + coverage
    [ ] playwright            Not installed
    [ ] postgres              Not installed

  Install more: /br-mcp add playwright

═══════════════════════════════════════════════════
```

## How Ralph Uses These MCPs

During the EXECUTE phase (`/br-build`), Ralph automatically uses available MCPs:

| MCP | When Ralph uses it |
|-----|-------------------|
| **context7** | Before implementing: looks up current API docs for libraries in the story |
| **sequential-thinking** | When debugging complex failures: structured analysis of root cause |
| **fetch** | When docs aren't in context7: fetches official docs directly |
| **eslint** | After implementing: runs lint check before verification |
| **vitest** | Runs tests with AI-optimized output and coverage |
| **playwright** | For stories that need E2E testing or browser interaction |
| **postgres** | Explores DB schema before writing queries or migrations |
| **memory** | Recalls patterns from previous sprints |

**No code changes needed** — MCP tools appear automatically in Claude Code once installed.

## Add a Specific MCP

When `$ARGUMENTS` = `add <name>`:

Look up the name in the catalog above and run the corresponding `claude mcp add` command.

If the name isn't recognized, tell the user:
```
Unknown MCP: <name>
Available: context7, sequential-thinking, fetch, playwright, github,
           postgres, memory, eslint, vitest, brave-search, sentry,
           supabase, neon, e2b, kubernetes
```

## Remove a MCP

When `$ARGUMENTS` = `remove <name>`:

```bash
claude mcp remove <name>
```

Display confirmation.
