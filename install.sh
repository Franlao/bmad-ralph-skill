#!/bin/bash
#
# BMAD-Ralph Super Skill Installer
# Combines BMAD (structured agile planning) + Ralph Wiggum (autonomous execution)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         BMAD-RALPH SUPER SKILL INSTALLER      ║${NC}"
echo -e "${CYAN}║   Structured Planning + Autonomous Execution   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

BR_HOOK_SCRIPTS="br-guard.sh br-monitor.sh br-post-edit.sh br-lib.sh"

# Remove BMAD-Ralph hook entries from a settings.json (requires jq)
strip_br_hooks() {
    local settings="$1"
    jq '(.hooks // {}) |= map_values(
            map(select(
                ([.hooks[]?.command // ""] | any(test("br-(guard|monitor|post-edit)\\.sh"))) | not
            ))
        )
        | .hooks |= with_entries(select(.value | length > 0))
        | if .hooks == {} then del(.hooks) else . end' "$settings"
}

# Determine install scope
INSTALL_DIR=""
SCOPE=""

if [ "$1" == "--uninstall" ]; then
    if [ "$2" == "--global" ]; then
        INSTALL_DIR="$HOME/.claude"
    else
        INSTALL_DIR=".claude"
    fi
    echo -e "${YELLOW}Uninstalling BMAD-Ralph from ${INSTALL_DIR}...${NC}"
    for cmd in "${INSTALL_DIR}/commands"/br*.md; do
        [ -f "$cmd" ] && rm "$cmd" && echo -e "  ${RED}-${NC} $(basename "$cmd")"
    done
    for agent in "${INSTALL_DIR}/agents"/br-*.md; do
        [ -f "$agent" ] && rm "$agent" && echo -e "  ${RED}-${NC} $(basename "$agent")"
    done
    for hook in "${INSTALL_DIR}/hooks"/br-*.sh; do
        [ -f "$hook" ] && rm "$hook" && echo -e "  ${RED}-${NC} $(basename "$hook")"
    done
    # Only remove files WE installed — never the whole templates dir,
    # it may contain the user's own templates.
    for tmpl in CLAUDE.md hooks-config.json hooks-config.resolved.json; do
        if [ -f "${INSTALL_DIR}/templates/${tmpl}" ]; then
            rm "${INSTALL_DIR}/templates/${tmpl}" && echo -e "  ${RED}-${NC} templates/${tmpl}"
        fi
    done
    rmdir "${INSTALL_DIR}/templates" 2>/dev/null || true
    # Clean br-* hook entries out of settings.json when jq is available
    if [ -f "${INSTALL_DIR}/settings.json" ]; then
        if command -v jq >/dev/null 2>&1 && grep -q 'br-guard.sh' "${INSTALL_DIR}/settings.json"; then
            strip_br_hooks "${INSTALL_DIR}/settings.json" > "${INSTALL_DIR}/settings.json.tmp" \
                && mv "${INSTALL_DIR}/settings.json.tmp" "${INSTALL_DIR}/settings.json"
            echo -e "  ${RED}-${NC} br-* hook entries removed from settings.json"
        else
            echo -e "${YELLOW}Note: remove br-* hook entries from settings.json manually (jq not found).${NC}"
        fi
    fi
    echo -e "${YELLOW}Note: .bmad-ralph/ project data was NOT removed. Delete it manually if needed.${NC}"
    echo -e "${GREEN}BMAD-Ralph uninstalled.${NC}"
    exit 0
elif [ "$1" == "--global" ]; then
    INSTALL_DIR="$HOME/.claude"
    SCOPE="global (all projects)"
    # User-level hooks live at a fixed absolute path
    HOOKS_DIR_REF="$HOME/.claude/hooks"
elif [ "$1" == "--project" ] || [ -z "$1" ]; then
    INSTALL_DIR=".claude"
    SCOPE="project (current directory)"
    # Resolved by Claude Code at hook runtime, regardless of cwd
    HOOKS_DIR_REF='$CLAUDE_PROJECT_DIR/.claude/hooks'
else
    echo -e "${RED}Usage: ./install.sh [--global|--project|--uninstall]${NC}"
    echo "  --project    Install for current project only (default)"
    echo "  --global     Install for all projects (~/.claude/)"
    echo "  --uninstall  Remove BMAD-Ralph (add --global for global uninstall)"
    exit 1
fi

echo -e "${BLUE}Install scope: ${SCOPE}${NC}"
echo -e "${BLUE}Install path:  ${INSTALL_DIR}${NC}"
echo ""

if ! command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: jq not found. Hooks fall back to python3/sed parsing — install jq for the most robust guard.${NC}"
    echo ""
fi

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "${INSTALL_DIR}/commands"
mkdir -p "${INSTALL_DIR}/agents"
mkdir -p "${INSTALL_DIR}/hooks"

# Copy commands
echo -e "${YELLOW}Installing commands...${NC}"
for cmd in "${SCRIPT_DIR}/.claude/commands"/br*.md; do
    if [ -f "$cmd" ]; then
        cp "$cmd" "${INSTALL_DIR}/commands/"
        echo -e "  ${GREEN}+${NC} commands/$(basename "$cmd")"
    fi
done

# Copy agents
echo -e "${YELLOW}Installing agents...${NC}"
for agent in "${SCRIPT_DIR}/.claude/agents"/br-*.md; do
    if [ -f "$agent" ]; then
        cp "$agent" "${INSTALL_DIR}/agents/"
        echo -e "  ${GREEN}+${NC} agents/$(basename "$agent")"
    fi
done

# Copy hooks
echo -e "${YELLOW}Installing hooks...${NC}"
for hook in "${SCRIPT_DIR}/.claude/hooks"/br-*.sh; do
    if [ -f "$hook" ]; then
        cp "$hook" "${INSTALL_DIR}/hooks/"
        chmod +x "${INSTALL_DIR}/hooks/$(basename "$hook")"
        echo -e "  ${GREEN}+${NC} hooks/$(basename "$hook")"
    fi
done

# Copy templates
echo -e "${YELLOW}Installing templates...${NC}"
mkdir -p "${INSTALL_DIR}/templates"
if [ -f "${SCRIPT_DIR}/templates/CLAUDE.md" ]; then
    cp "${SCRIPT_DIR}/templates/CLAUDE.md" "${INSTALL_DIR}/templates/"
    echo -e "  ${GREEN}+${NC} templates/CLAUDE.md"
fi

# Resolve hook paths for this scope (template uses the __BR_HOOKS_DIR__ placeholder)
RESOLVED_HOOKS_CONFIG="${INSTALL_DIR}/templates/hooks-config.resolved.json"
sed "s|__BR_HOOKS_DIR__|${HOOKS_DIR_REF}|g" "${SCRIPT_DIR}/templates/hooks-config.json" > "$RESOLVED_HOOKS_CONFIG"

# Install hooks config
echo -e "${YELLOW}Configuring hooks...${NC}"
if [ ! -f "${INSTALL_DIR}/settings.json" ]; then
    cp "$RESOLVED_HOOKS_CONFIG" "${INSTALL_DIR}/settings.json"
    echo -e "  ${GREEN}+${NC} settings.json (guard + auto-format + monitor hooks)"
elif grep -q 'br-guard.sh' "${INSTALL_DIR}/settings.json"; then
    echo -e "  ${BLUE}i${NC} settings.json already contains BMAD-Ralph hooks — skipped"
elif command -v jq >/dev/null 2>&1; then
    # Append our hook groups to the existing arrays without touching anything else
    jq -s '
        .[0] as $cur | .[1] as $new
        | $cur
        | .hooks.PreToolUse  = (($cur.hooks.PreToolUse  // []) + $new.hooks.PreToolUse)
        | .hooks.PostToolUse = (($cur.hooks.PostToolUse // []) + $new.hooks.PostToolUse)
    ' "${INSTALL_DIR}/settings.json" "$RESOLVED_HOOKS_CONFIG" > "${INSTALL_DIR}/settings.json.tmp" \
        && mv "${INSTALL_DIR}/settings.json.tmp" "${INSTALL_DIR}/settings.json"
    echo -e "  ${GREEN}+${NC} BMAD-Ralph hooks merged into existing settings.json"
else
    echo -e "  ${BLUE}i${NC} settings.json exists and jq is unavailable — merge hooks manually from templates/hooks-config.resolved.json"
fi

# Count installed files
CMD_COUNT=$(ls -1 "${INSTALL_DIR}/commands"/br*.md 2>/dev/null | wc -l)
AGENT_COUNT=$(ls -1 "${INSTALL_DIR}/agents"/br-*.md 2>/dev/null | wc -l)
HOOK_COUNT=$(ls -1 "${INSTALL_DIR}/hooks"/br-*.sh 2>/dev/null | wc -l)

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "  Commands installed: ${CYAN}${CMD_COUNT}${NC}"
echo -e "  Agents installed:   ${CYAN}${AGENT_COUNT}${NC}"
echo -e "  Hooks installed:    ${CYAN}${HOOK_COUNT}${NC}"
echo ""
echo -e "${CYAN}Available commands:${NC}"
echo ""
echo -e "  ${YELLOW}Workflow:${NC}"
echo "  /br-init <description>  — Initialize a new project"
echo "  /br-auto                — Run all planning phases automatically"
echo "  /br-build               — Launch Ralph autonomous execution"
echo "  /br-build auto          — Run all sprints sequentially"
echo "  /br-review              — Quality gate review"
echo ""
echo -e "  ${YELLOW}Planning phases:${NC}"
echo "  /br-discover            — Discovery (4 parallel agents)"
echo "  /br-plan                — Generate PRD"
echo "  /br-architect           — Design architecture"
echo "  /br-sprint              — Break into stories"
echo ""
echo -e "  ${YELLOW}Monitoring:${NC}"
echo "  /br-status              — Dashboard"
echo "  /br-logs                — View logs"
echo "  /br-debug               — Diagnose issues"
echo "  /br-metrics             — Performance analytics"
echo "  /br-test                — Run tests"
echo ""
echo -e "  ${YELLOW}Management:${NC}"
echo "  /br-scope               — Add/remove features"
echo "  /br-rollback            — Revert stories/sprints"
echo "  /br-config              — Change settings"
echo "  /br-deploy              — Generate deployment artifacts"
echo "  /br-fix                 — Auto-repair issues"
echo "  /br-resume              — Resume after interruption"
echo "  /br-update              — Update skill from GitHub"
echo "  /br                     — Smart orchestrator"
echo ""
echo -e "${YELLOW}Autonomous mode:${NC}"
echo "  Execution agents run with bypassPermissions (set in their frontmatter)."
echo "  The guard hook (br-guard.sh) blocks common destructive operations —"
echo "  it is a best-effort safety net, not a sandbox."
echo ""
echo -e "${YELLOW}Quick start:${NC}"
echo "  1. cd your-project/"
echo "  2. claude"
echo '  3. /br-init "Build a task management SaaS with team collaboration"'
echo "  4. /br-auto   (runs all BMAD phases automatically)"
echo "  5. /br-build  (launches Ralph for autonomous execution)"
echo ""
