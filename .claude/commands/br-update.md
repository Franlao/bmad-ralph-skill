---
name: br-update
description: "Update BMAD-Ralph skill from GitHub — pull latest and re-install"
---

# BMAD-Ralph Updater

Update the skill to the latest version from GitHub.

## Arguments

- `$ARGUMENTS` empty → update and re-install
- `$ARGUMENTS` = `check` → only check if updates are available
- `$ARGUMENTS` = `changelog` → show what changed since last update

## Locate Skill Repository

Check in order:
1. `~/bmad-ralph-skill/` (default clone location)
2. If not found, ask the user: "Where is your bmad-ralph-skill repo?"

## Check for Updates

```bash
cd ~/bmad-ralph-skill
git fetch origin master
git log HEAD..origin/master --oneline
```

If no new commits:
```
BMAD-Ralph is up to date. ✓
Current version: <last commit hash short> (<date>)
```

If new commits exist:
```
BMAD-RALPH UPDATE AVAILABLE
═══════════════════════════════════════════

  Current: <hash> (<date>)
  Latest:  <hash> (<date>)

  Changes:
    abc1234 Add br-rollback command
    def5678 Fix guard hook pattern matching
    ghi9012 Add br-metrics dashboard

  Run /project:br-update to install
```

## Update and Re-install

1. Pull latest:
   ```bash
   cd ~/bmad-ralph-skill && git pull origin master
   ```

2. Detect current install scope:
   - If `.claude/commands/br.md` exists in current directory → project install
   - If `~/.claude/commands/br.md` exists → global install
   - If both → ask user which to update

3. Re-run installer:
   ```bash
   bash ~/bmad-ralph-skill/install.sh --project
   # or
   bash ~/bmad-ralph-skill/install.sh --global
   ```

4. Show what changed:
   ```
   BMAD-RALPH UPDATED
   ═══════════════════════════════════════════

     Updated:  <old hash> → <new hash>
     Commands: 14 → 20 (+6 new)
     Agents:   2 (unchanged)
     Hooks:    3 (unchanged)

     New commands:
       + br-rollback   — Rollback sprints/stories
       + br-config     — Configure settings
       + br-update     — This command
       + br-test       — Test runner
       + br-metrics    — Performance analytics
       + br-deploy     — Deployment artifacts

     Note: Your .bmad-ralph/ project data is untouched.
   ```

## Show Changelog

When `$ARGUMENTS` = `changelog`:

```bash
cd ~/bmad-ralph-skill && git log --oneline -20
```

Display formatted with dates and descriptions.
