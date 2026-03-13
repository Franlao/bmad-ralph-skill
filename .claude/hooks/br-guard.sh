#!/bin/bash
#
# BMAD-Ralph Pre-Tool Guard Hook
# Prevents dangerous operations during Ralph autonomous loops
# Receives tool input JSON on stdin
#

INPUT=$(cat -)
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Extract file path from tool input JSON
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# Protected files that should never be modified during execution
# Note: package-lock.json, yarn.lock etc are NOT blocked (needed for installs)
is_protected() {
    local file="$1"
    case "$file" in
        *.env|*.env.local|*.env.production|*.env.staging)  return 0 ;;
        *.key|*.pem|*.cert|*.p12|*.pfx)                    return 0 ;;
        *credentials*|*secret*)                             return 0 ;;
    esac
    return 1
}

if [ -n "$FILE_PATH" ] && is_protected "$FILE_PATH"; then
    echo "BLOCKED: BMAD-Ralph guard — Cannot modify protected file: $FILE_PATH"
    echo "If this is intentional, remove the guard hook temporarily."
    exit 2
fi

# Block destructive bash commands during Ralph loops
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

    # Normalize command for matching
    CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

    DANGEROUS_PATTERNS=(
        "rm -rf /"
        "rm -rf ~"
        "rm -rf ."
        "rm -rf *"
        "drop table"
        "drop database"
        "truncate table"
        "git push --force"
        "git push -f"
        "git reset --hard"
        "chmod 777"
        "mkfs"
        "> /dev/sda"
        ":(){ :|:&"
    )

    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$CMD_LOWER" | grep -qF "$pattern"; then
            echo "BLOCKED: BMAD-Ralph guard — Dangerous command detected: $pattern"
            exit 2
        fi
    done
fi

# Allow all other operations
exit 0
