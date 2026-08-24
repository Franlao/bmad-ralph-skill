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
#
# Design rule: a FALSE POSITIVE is not free. During an autonomous loop a deny
# is a story failure Ralph cannot repair — it retries, fails again, and burns
# the circuit breaker into a bogus escalation. Every rule here is therefore
# anchored (basename, command position) instead of matching substrings.
# Regression cases live in tests/guard-cases.tsv — add one for every rule change.

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
# Matched on the BASENAME, never as a substring of the whole path: a naive
# "*secret*" rule denies src/config/secrets.ts and stalls the loop on a story
# it can never repair. Lockfiles (package-lock.json, ...) are NOT blocked.
is_protected() {
    local path="$1"
    path="${path%\"}"; path="${path#\"}"
    path="${path%\'}"; path="${path#\'}"
    local base="${path##*/}"
    [ -n "$base" ] || return 1
    local lower
    lower=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')

    # .env / .env.<x> / <x>.env — but .env.example & friends are files the
    # architecture explicitly asks Ralph to create (section 7b).
    case "$lower" in
        .env|.env.*|*.env)
            case "$lower" in
                *.example|*.sample|*.template|*.dist|*.tpl) return 1 ;;
            esac
            return 0
            ;;
    esac

    # Key material
    case "$lower" in
        *.key|*.pem|*.crt|*.cert|*.p12|*.pfx|*.keystore|*.jks) return 0 ;;
        id_rsa*|id_dsa*|id_ecdsa*|id_ed25519*)                 return 0 ;;
    esac

    # Credential/secret FILES (json, yaml, .enc, extensionless) — never source
    # code that merely handles secrets.
    case "$lower" in
        credential*|secret*|*.secret|*-credentials*|*_credentials*|*-secrets*|*_secrets*)
            case "$lower" in
                *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.py|*.go|*.rs|*.java|*.rb|*.php|*.cs|*.kt|*.swift|*.sql|*.md|*.rst|*.txt)
                    return 1 ;;
            esac
            return 0
            ;;
    esac

    return 1
}

# Does this shell command WRITE somewhere (as opposed to reading)?
is_write_command() {
    printf '%s\n' "$1" | grep -Eq \
        '>>?|(^|[;&|[:space:]])(tee|dd|truncate|install)([[:space:]]|$)|(^|[;&|[:space:]])sed[[:space:]]+-[a-z]*i|(^|[;&|[:space:]])(cp|mv|rsync)([[:space:]]|$)'
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

        # Writes to a protected file THROUGH THE SHELL. The Edit/Write rule
        # above only covers the file tools — `echo x > .env` used to sail past.
        if is_write_command "$COMMAND"; then
            for token in $COMMAND; do
                case "$token" in
                    -*) continue ;;
                esac
                case "$token" in
                    *.*|*/*|.*)
                        if is_protected "$token"; then
                            deny "shell write touching a protected file: $token"
                        fi
                        ;;
                esac
            done
        fi

        # Read-only inspection commands are exempt from the blocklist below:
        # `grep -r "drop table" docs/` is not a DROP TABLE. Only when the
        # command chains nothing else (no ; && || backtick $()).
        SCAN_DANGEROUS=1
        if ! printf '%s\n' "$COMMAND" | grep -Eq '[;&|`]|\$\('; then
            FIRST_TOKEN=$(printf '%s' "$CMD_LOWER" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]].*//')
            FIRST_TOKEN="${FIRST_TOKEN##*/}"
            case "$FIRST_TOKEN" in
                grep|rg|ag|cat|head|tail|less|more|find|ls|wc|awk|jq|echo|printf|diff|sort|uniq|which|type|file)
                    SCAN_DANGEROUS=0 ;;
                git)
                    case "$(printf '%s' "$CMD_LOWER" | awk '{print $2}')" in
                        log|grep|show|diff|status|branch|remote|blame|describe) SCAN_DANGEROUS=0 ;;
                    esac
                    ;;
            esac
        fi

        # Index-aligned arrays: a single "pattern|label" string silently
        # truncated the pattern as soon as a label contained a pipe.
        DANGEROUS_PATTERNS=(
            '(^|[;&|`[:space:]])rm[[:space:]]+-[a-z]*(rf|fr)[a-z]*([[:space:]]+--no-preserve-root)?[[:space:]]+["'\'']?(/|~|\$home|\*|\.\.?/?["'\'']?([[:space:]]|$|[;&|]))'
            '(^|[;&|`[:space:]])rm[[:space:]]+(-[a-z]+[[:space:]]+)+["'\'']?(/|~|\$home|\*)([[:space:]]|$|["'\''])'
            'git[[:space:]]+reset[[:space:]]+--hard'
            'git[[:space:]]+clean[[:space:]]+-[a-z]*f'
            'drop[[:space:]]+(table|database)'
            'truncate[[:space:]]+table'
            'chmod[[:space:]]+(-[a-z]+[[:space:]]+)*777'
            '(^|[;&|[:space:]])mkfs'
            'dd[[:space:]][^;|&]*of=/dev/'
            '>[[:space:]]*/dev/(sd|nvme|hd)'
            ':\(\)[[:space:]]*\{[[:space:]]*:\|:'
            '(curl|wget)[^;|&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)'
        )
        DANGEROUS_LABELS=(
            'recursive rm on a broad target (/, ~, ., *)'
            'rm with split flags on a broad target'
            'git reset --hard'
            'git clean -f (deletes untracked files)'
            'SQL DROP'
            'SQL TRUNCATE'
            'chmod 777'
            'mkfs (formats a disk)'
            'dd writing to a device'
            'redirect to a block device'
            'fork bomb'
            'piping a remote script into a shell'
        )

        if [ "$SCAN_DANGEROUS" = "1" ]; then
            for i in "${!DANGEROUS_PATTERNS[@]}"; do
                if printf '%s\n' "$CMD_LOWER" | grep -Eq "${DANGEROUS_PATTERNS[$i]}"; then
                    deny "dangerous command (${DANGEROUS_LABELS[$i]}): $COMMAND"
                fi
            done
        fi
        ;;
esac

# Allow everything else — exit 0 with no JSON means "no decision,
# normal permission flow applies".
exit 0
