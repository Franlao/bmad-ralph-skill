#!/bin/bash
#
# BMAD-Ralph Pre-Tool Guard Hook (PreToolUse)
#
# Reads the hook payload JSON on stdin (tool_name + tool_input, per
# https://code.claude.com/docs/en/hooks.md) and denies dangerous operations
# using the permissionDecision JSON protocol (recommended), falling back to
# the exit-code-2 protocol with the reason on stderr when jq is missing.
#
# This is a best-effort blocklist — a last line of defense during autonomous
# Ralph loops, NOT a sandbox. Keep it alongside, not instead of, sandboxing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/br-lib.sh"

BR_HOOK_INPUT=$(cat -)

deny() {
    local reason="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg r "$reason" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: ("BMAD-Ralph guard: " + $r)
            }
        }'
        exit 0
    fi
    # Exit-code protocol: code 2 blocks; Claude only sees stderr.
    echo "BLOCKED (BMAD-Ralph guard): $reason" >&2
    exit 2
}

TOOL_NAME=$(br_get_field "tool_name")

# --- Protected files: never edited during autonomous execution ---
# Note: lockfiles (package-lock.json, yarn.lock, ...) are NOT blocked.
is_protected() {
    case "$1" in
        *.env|*.env.local|*.env.production|*.env.staging)  return 0 ;;
        *.key|*.pem|*.cert|*.p12|*.pfx)                    return 0 ;;
        *credentials*|*secret*)                             return 0 ;;
    esac
    return 1
}

case "$TOOL_NAME" in
    Edit|Write|NotebookEdit)
        FILE_PATH=$(br_get_field "tool_input.file_path")
        if [ -n "$FILE_PATH" ] && is_protected "$FILE_PATH"; then
            deny "protected file: $FILE_PATH. If intentional, edit it manually or disable the guard hook."
        fi
        ;;

    Bash)
        COMMAND=$(br_get_field "tool_input.command")
        CMD_LOWER=$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')

        # Force-push: block -f/--force but allow --force-with-lease/--force-if-includes
        CMD_NO_LEASE=$(printf '%s' "$CMD_LOWER" | sed -e 's/--force-with-lease[^[:space:]]*//g' -e 's/--force-if-includes//g')
        if printf '%s\n' "$CMD_NO_LEASE" | grep -Eq 'git[[:space:]]+push[[:space:]]([^;|&]*[[:space:]])?(-f|--force)([[:space:]]|$)'; then
            deny "force push detected: $COMMAND"
        fi

        # Each entry: ERE pattern | human-readable label
        DANGEROUS=(
            '(^|[;&|`[:space:]])rm[[:space:]]+-[a-z]*(rf|fr)[a-z]*([[:space:]]+--no-preserve-root)?[[:space:]]+["'\'']?(/|~|\$home|\*|\.\.?["'\'']?([[:space:]]|$|[;&|]))|recursive rm on a broad target (/, ~, ., *)'
            'git[[:space:]]+reset[[:space:]]+--hard|git reset --hard'
            'git[[:space:]]+clean[[:space:]]+-[a-z]*f|git clean -f (deletes untracked files)'
            'drop[[:space:]]+(table|database)|SQL DROP'
            'truncate[[:space:]]+table|SQL TRUNCATE'
            'chmod[[:space:]]+(-[a-z]+[[:space:]]+)*777|chmod 777'
            '(^|[;&|[:space:]])mkfs|mkfs (formats a disk)'
            'dd[[:space:]][^;|&]*of=/dev/|dd writing to a device'
            '>[[:space:]]*/dev/(sd|nvme|hd)|redirect to a block device'
            ':\(\)[[:space:]]*\{[[:space:]]*:\|:|fork bomb'
            '(curl|wget)[^;|&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)|piping a remote script into a shell'
        )

        for entry in "${DANGEROUS[@]}"; do
            pattern="${entry%|*}"
            label="${entry##*|}"
            if printf '%s\n' "$CMD_LOWER" | grep -Eq "$pattern"; then
                deny "dangerous command ($label): $COMMAND"
            fi
        done
        ;;
esac

# Allow everything else — exit 0 with no JSON means "no decision,
# normal permission flow applies".
exit 0
