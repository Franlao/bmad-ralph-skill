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

# 6b — preloading is verified to work (a br-developer probe quoted the protocol
#      verbatim with zero tool calls), so the fallback is compat insurance, not the
#      nominal path. Keep it: `skills:` is still ignored by older Claude Code and
#      dropped for plugin-scoped agents, and an agent that improvises the loop from
#      memory is the exact failure this refactor exists to prevent.
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

# 8 — the gate circuit breaker exists end to end: a threshold nobody stores and
#     nobody can change is a comment, not a limit. Four unbounded gate cycles on
#     one sprint is the observed failure this guards.
missing=""
grep -q 'max_gate_cycles' .claude/skills/br-init/SKILL.md   || missing="${missing} br-init(gabarit d'état)"
grep -q 'max_gate_cycles' templates/example-state.json      || missing="${missing} example-state.json"
grep -q 'max-gate-cycles' .claude/skills/br-config/SKILL.md || missing="${missing} br-config(argument)"
grep -q 'ralph.max_gate_cycles' .claude/skills/br-config/SKILL.md || missing="${missing} br-config(champ visé)"
grep -q 'max_gate_cycles' .claude/skills/br-review/SKILL.md || missing="${missing} br-review(lecture du seuil)"
check "disjoncteur de porte câblé partout" "$missing"

# 9 — a finding that cannot cite the requirement it breaks is a spec gap, and a
#     spec gap routed to a fix story is how one defect returns under four faces.
missing=""
grep -q 'VIOLATION' .claude/skills/br-review/SKILL.md || missing="${missing} pas de verdict VIOLATION"
grep -q 'LACUNE'    .claude/skills/br-review/SKILL.md || missing="${missing} pas de verdict LACUNE"
grep -q 'defect_classes' .claude/skills/br-review/SKILL.md || missing="${missing} classes de défauts non enregistrées"
grep -q 'defect_classes' .claude/skills/br-sprint/SKILL.md || missing="${missing} entrée de sprint sans defect_classes"
check "constats triés violation/lacune et classés" "$missing"

# 10 — the review checklist must not be hardwired for the web: the same rule the
#      discovery and the architect panel already follow.
if grep -q 'Right-size the review' .claude/skills/br-review/SKILL.md; then
    if grep -qE '^- (SQL injection vulnerabilities|XSS possibilities|N\+1 query patterns)$' .claude/skills/br-review/SKILL.md; then
        fail "br-review garde une liste web figée dans un prompt de relecteur"
    else
        ok "revue dimensionnée au type de projet"
    fi
else
    fail "br-review n'a pas de règle de dimensionnement"
fi

# 11 — the toolchain is established once by running it, then consumed. Three phases
#      re-detecting independently is how the gate ends up linting with another binary
#      than the loop did.
missing=""
grep -q 'Step 2b' .claude/skills/br-init/SKILL.md        || missing="${missing} br-init(pas d'étape de vérification)"
grep -q '"toolchain"' .claude/skills/br-init/SKILL.md    || missing="${missing} br-init(absent du gabarit d'état)"
grep -q '"toolchain"' templates/example-state.json       || missing="${missing} example-state.json"
for f in br-test br-review br-build; do
    grep -q 'toolchain' ".claude/skills/$f/SKILL.md" || missing="${missing} $f(ne le consomme pas)"
done
grep -q 'toolchain' .claude/skills/br-ralph-protocol/SKILL.md || missing="${missing} protocole(ne le consomme pas)"
check "chaîne d'outils constatée puis réutilisée" "$missing"

# 12 — discovery probes the real runtime instead of quoting docs, and what it observes
#      has to reach the design: a trap found and silently dropped is worse than no probe.
missing=""
grep -q 'PROBE THE RUNTIME' .claude/skills/br-discover/SKILL.md || missing="${missing} br-discover(pas de sonde)"
grep -q 'FACT — observé' .claude/skills/br-discover/SKILL.md    || missing="${missing} br-discover(pas de tag observé)"
grep -q 'Comportements observés du runtime' .claude/skills/br-architect/SKILL.md || missing="${missing} br-architect(n'exige pas leur traitement)"
check "runtime sondé, observations traitées par l'architecture" "$missing"

echo ""
if [ "$FAILED" -gt 0 ]; then
    printf "${RED}%d failed${NC}, %d passed\n" "$FAILED" "$PASSED"
    exit 1
fi
printf "${GREEN}all %d structure checks pass${NC}\n" "$PASSED"
