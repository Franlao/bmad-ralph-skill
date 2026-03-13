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
    [ -d "${INSTALL_DIR}/templates" ] && rm -rf "${INSTALL_DIR}/templates" && echo -e "  ${RED}-${NC} templates/"
    echo ""
    echo -e "${YELLOW}Note: settings.json was NOT removed. Remove br-* hook entries manually if needed.${NC}"
    echo -e "${YELLOW}Note: .bmad-ralph/ project data was NOT removed. Delete it manually if needed.${NC}"
    echo -e "${GREEN}BMAD-Ralph uninstalled.${NC}"
    exit 0
elif [ "$1" == "--global" ]; then
    INSTALL_DIR="$HOME/.claude"
    SCOPE="global (all projects)"
elif [ "$1" == "--project" ] || [ -z "$1" ]; then
    INSTALL_DIR=".claude"
    SCOPE="project (current directory)"
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

# Install hooks config
echo -e "${YELLOW}Configuring hooks...${NC}"
if [ -f "${INSTALL_DIR}/settings.json" ]; then
    echo -e "  ${BLUE}i${NC} settings.json exists — merge hooks manually from templates/hooks-config.json"
else
    cp "${SCRIPT_DIR}/templates/hooks-config.json" "${INSTALL_DIR}/settings.json"
    echo -e "  ${GREEN}+${NC} settings.json (guard + auto-format hooks)"
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
echo "  /project:br-init <description>  — Initialize a new project"
echo "  /project:br-auto                — Run all planning phases automatically"
echo "  /project:br-build               — Launch Ralph autonomous execution"
echo "  /project:br-build auto          — Run all sprints sequentially"
echo "  /project:br-review              — Quality gate review"
echo ""
echo -e "  ${YELLOW}Planning phases:${NC}"
echo "  /project:br-discover            — Discovery (4 parallel agents)"
echo "  /project:br-plan                — Generate PRD"
echo "  /project:br-architect           — Design architecture"
echo "  /project:br-sprint              — Break into stories"
echo ""
echo -e "  ${YELLOW}Monitoring:${NC}"
echo "  /project:br-status              — Dashboard"
echo "  /project:br-logs                — View logs"
echo "  /project:br-debug               — Diagnose issues"
echo "  /project:br-metrics             — Performance analytics"
echo "  /project:br-test                — Run tests"
echo ""
echo -e "  ${YELLOW}Management:${NC}"
echo "  /project:br-scope               — Add/remove features"
echo "  /project:br-rollback            — Revert stories/sprints"
echo "  /project:br-config              — Change settings"
echo "  /project:br-deploy              — Generate deployment artifacts"
echo "  /project:br-fix                 — Auto-repair issues"
echo "  /project:br-resume              — Resume after interruption"
echo "  /project:br-update              — Update skill from GitHub"
echo "  /project:br                     — Smart orchestrator"
echo ""
echo -e "${YELLOW}Autonomous mode:${NC}"
echo "  All agents run with bypassPermissions — zero user prompts needed."
echo "  Guard hook (br-guard.sh) blocks dangerous operations automatically."
echo ""
echo -e "${YELLOW}Quick start:${NC}"
echo "  1. cd your-project/"
echo "  2. claude"
echo '  3. /project:br-init "Build a task management SaaS with team collaboration"'
echo "  4. /project:br-auto   (runs all BMAD phases automatically)"
echo "  5. /project:br-build  (launches Ralph for autonomous execution)"
echo ""
