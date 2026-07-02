# br-lib.sh — shared helpers for BMAD-Ralph hooks (sourced, never executed)
#
# Claude Code hooks receive a JSON payload on stdin with fields like
# tool_name and tool_input (https://code.claude.com/docs/en/hooks.md).
# Callers must read stdin into BR_HOOK_INPUT before using br_get_field.

# br_get_field <dotted.path> — print a string/number field from BR_HOOK_INPUT.
# Prefers jq, falls back to python3, then to a crude sed that only handles
# simple values (breaks on escaped quotes — acceptable last resort).
br_get_field() {
    local path="$1"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$BR_HOOK_INPUT" | jq -r --arg p "$path" '
            getpath($p | split(".")) // empty
            | if type == "string" or type == "number" then tostring else "" end
        ' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "$BR_HOOK_INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    for k in sys.argv[1].split("."):
        d = d.get(k) if isinstance(d, dict) else None
    sys.stdout.write(str(d) if isinstance(d, (str, int, float)) else "")
except Exception:
    pass' "$path" 2>/dev/null
    else
        local key="${path##*.}"
        printf '%s' "$BR_HOOK_INPUT" \
            | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
            | head -1
    fi
}
