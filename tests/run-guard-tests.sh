#!/bin/bash
#
# Regression tests for .claude/hooks/br-guard.sh
#
# The guard is a blocklist that runs on EVERY tool call of an autonomous loop.
# A false positive is a story failure Ralph cannot repair (retry, retry,
# circuit breaker, bogus escalation); a false negative is a destroyed working
# tree. Both directions are covered here.
#
# Usage: bash tests/run-guard-tests.sh
# Exit code 0 = all cases behave as expected.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$REPO_ROOT/.claude/hooks/br-guard.sh"
CASES="$REPO_ROOT/tests/guard-cases.tsv"

[ -f "$GUARD" ] || { echo "guard hook not found: $GUARD" >&2; exit 1; }
[ -f "$CASES" ] || { echo "case file not found: $CASES" >&2; exit 1; }

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASSED=0; FAILED=0

# Run the guard on one payload and print "allow" or "deny".
# Both hook protocols are accepted: the JSON permissionDecision (jq present)
# and the exit-code-2 fallback (jq absent).
decision_for() {
    local payload="$1" out rc
    out=$(printf '%s' "$payload" | bash "$GUARD" 2>/dev/null)
    rc=$?
    if [ "$rc" = "2" ]; then
        echo "deny"
    elif printf '%s' "$out" | grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
        echo "deny"
    else
        echo "allow"
    fi
}

while IFS=$'\t' read -r payload expected label; do
    case "$payload" in ''|'#'*) continue ;; esac
    actual=$(decision_for "$payload")
    if [ "$actual" = "$expected" ]; then
        PASSED=$((PASSED + 1))
        printf "  ${GREEN}ok${NC}   %-8s %s\n" "$expected" "$label"
    else
        FAILED=$((FAILED + 1))
        printf "  ${RED}FAIL${NC} expected %-5s got %-5s  %s\n" "$expected" "$actual" "$label"
    fi
done < "$CASES"

echo ""
if [ "$FAILED" -gt 0 ]; then
    printf "${RED}%d failed${NC}, %d passed\n" "$FAILED" "$PASSED"
    exit 1
fi
printf "${GREEN}all %d guard cases pass${NC}\n" "$PASSED"
