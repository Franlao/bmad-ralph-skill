#!/bin/bash
#
# Structural invariants of the BMAD-Ralph skill.
#
# A 23-directory layout breaks by a botched move, a stale path or a second copy
# of something that must exist once — not by logic. These checks are cheap and
# catch exactly that class.
#
# Usage: bash tests/run-structure-tests.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASSED=0; FAILED=0

ok()   { PASSED=$((PASSED + 1)); printf "  ${GREEN}ok${NC}   %s\n" "$1"; }
fail() { FAILED=$((FAILED + 1)); printf "  ${RED}FAIL${NC} %s\n" "$1"; }

check() { # check <description> <expected-empty-output>
    if [ -z "$2" ]; then ok "$1"; else fail "$1"; printf "       %s\n" "$2"; fi
}

# 1 — every skill directory carries a SKILL.md
missing=""
for d in .claude/skills/*/; do
    [ -f "${d}SKILL.md" ] || missing="${missing} ${d}"
done
check "chaque skill a son SKILL.md" "$missing"

# 2 — frontmatter present, and `name:` matches the directory (the directory is
#     what actually names the command; a mismatch is a silent rename)
mismatch=""
for d in .claude/skills/*/; do
    f="${d}SKILL.md"
    [ -f "$f" ] || continue
    head -1 "$f" | grep -q '^---$' || { mismatch="${mismatch} ${f}(pas de frontmatter)"; continue; }
    declared=$(sed -n '2,20{/^name:[[:space:]]*/{s/^name:[[:space:]]*//;s/["'\'']//g;p;q}}' "$f")
    expected=$(basename "$d")
    [ "$declared" = "$expected" ] || mismatch="${mismatch} ${f}(name=${declared:-<absent>} != ${expected})"
done
check "name: aligné sur le nom du répertoire" "$mismatch"

# 3 — the pre-skills layout is gone
check "plus de .claude/commands/br*" "$(ls -d .claude/commands 2>/dev/null || true)"

# 4 — no dangling reference to the old layout or the deleted prompt directory
check "aucune référence pendante (commands/br-, .bmad-ralph/prompts)" \
    "$(grep -rln 'commands/br-\|\.bmad-ralph/prompts' .claude README.md templates 2>/dev/null | tr '\n' ' ')"

# 5 — the Ralph protocol exists exactly once. Two sentences from its BODY, one
#     from the circuit-breaker accounting and one from the quality bar: if
#     either shows up in a second file, a copy has grown back. Section titles
#     make poor sentinels — a caller is allowed to name the section it defers to.
for sentinel in "does not survive a context compaction" "premature optimization"; do
    hits=$(grep -rl "$sentinel" .claude 2>/dev/null | tr '\n' ' ')
    count=$(printf '%s' "$hits" | wc -w)
    if [ "$count" = "1" ] && [ "${hits% }" = ".claude/skills/br-ralph-protocol/SKILL.md" ]; then
        ok "protocole en un seul exemplaire (\"$sentinel\")"
    else
        fail "\"$sentinel\" présent dans $count fichier(s): $hits"
    fi
done

# 6 — the agent really preloads the protocol, and the skill it names exists
if grep -q '^skills:[[:space:]]*br-ralph-protocol' .claude/agents/br-developer.md; then
    ok "br-developer précharge br-ralph-protocol"
else
    fail "br-developer ne déclare pas skills: br-ralph-protocol"
fi
check "le skill préchargé existe" \
    "$([ -f .claude/skills/br-ralph-protocol/SKILL.md ] || echo 'br-ralph-protocol/SKILL.md absent')"

# 6b — the fallback matters more than the preload: `skills:` can silently fail
#      (stale session, older Claude Code), and an agent that improvises the loop
#      from memory is the exact failure this refactor exists to prevent.
if grep -q 'invoke the `br-ralph-protocol` skill' .claude/agents/br-developer.md; then
    ok "br-developer sait charger le protocole si le préchargement échoue"
else
    fail "br-developer n'a plus de repli si le préchargement échoue"
fi

# 7 — the protocol is injected into every story delegation: keep it small
lines=$(wc -l < .claude/skills/br-ralph-protocol/SKILL.md)
if [ "$lines" -le 200 ]; then
    ok "protocole compact (${lines} lignes ≤ 200)"
else
    fail "protocole trop long (${lines} lignes) — il est injecté à chaque story"
fi

echo ""
if [ "$FAILED" -gt 0 ]; then
    printf "${RED}%d failed${NC}, %d passed\n" "$FAILED" "$PASSED"
    exit 1
fi
printf "${GREEN}all %d structure checks pass${NC}\n" "$PASSED"
