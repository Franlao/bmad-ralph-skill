# BMAD-Ralph Super Skill

**Build entire projects from A to Z with Claude Code.**

BMAD-Ralph combine deux methodologies communautaires en un seul skill :
- **BMAD** (Breakthrough Method for Agile AI-Driven Development) — planification structuree avec agents specialises
- **Ralph Wiggum** — execution autonome en boucle avec circuit breakers

Le resultat : tu decris ton projet en une phrase, Claude planifie tout, puis code tout de maniere autonome.

---

## Installation rapide (depuis n'importe quel PC)

```bash
git clone https://github.com/Franlao/bmad-ralph-skill.git ~/bmad-ralph-skill
```

Puis dans ton projet :

```bash
cd ton-projet/
bash ~/bmad-ralph-skill/install.sh --project
```

Ou installation globale (tous les projets) :

```bash
bash ~/bmad-ralph-skill/install.sh --global
```

L'installeur copie les commandes, agents, hooks, et configure les settings automatiquement.

---

## Demarrage rapide (3 commandes)

```
# 1. Initialiser
/project:br-init "Application de gestion de taches avec collaboration en equipe"

# 2. Planifier (automatique)
/project:br-auto

# 3. Construire (autonome)
/project:br-build auto
```

C'est tout. Claude planifie, architecture, decoupe en stories, puis Ralph code chaque story, verifie, et commit.

---

## Comment ca marche

### Le pipeline

```
INIT → DISCOVER → PLAN → ARCHITECT → SPRINT → EXECUTE → REVIEW → DONE
        (BMAD)    (BMAD)   (BMAD)    (BMAD)   (Ralph)   (QA)
```

### Chaque phase en detail

#### 1. INIT (`/project:br-init "description"`)
- Detecte automatiquement le tech stack (package.json, Cargo.toml, etc.)
- Analyse le codebase existant
- Cree le dossier `.bmad-ralph/` et le fichier d'etat

#### 2. DISCOVER (`/project:br-discover`)
- Lance **4 agents en parallele** :
  - Analyse marche et utilisateurs
  - Analyse concurrentielle
  - Faisabilite technique
  - Analyse du codebase existant
- Produit : `.bmad-ralph/docs/business-brief.md`

#### 3. PLAN (`/project:br-plan`)
- Agent Product Manager qui genere un PRD complet
- User stories avec priorites (P0/P1/P2)
- Criteres d'acceptation pour chaque story
- Estimation du nombre de sprints
- Produit : `.bmad-ralph/docs/prd.md`

#### 4. ARCHITECT (`/project:br-architect`)
- Architecture systeme concrete et implementable
- Schema de base de donnees exact
- Endpoints API avec types
- Graphe de dependances entre fichiers (ordre d'implementation)
- Strategie de test
- Produit : `.bmad-ralph/docs/architecture.md`

#### 5. SPRINT (`/project:br-sprint`)
- Decoupe l'architecture en stories hyper-detaillees
- Chaque story contient :
  - Fichiers exacts a creer/modifier
  - Instructions d'implementation pas a pas
  - Commande de verification
  - Criteres d'acceptation
- Detecte les stories parallelisables
- Genere les prompts Ralph pour chaque sprint
- Produit : `.bmad-ralph/sprints/sprint-N.md`

#### 6. EXECUTE (`/project:br-build`)
- **La boucle Ralph** : pour chaque story :
  1. Lire les instructions
  2. Implementer
  3. Verifier (run tests/typecheck)
  4. Si OK → commit → story suivante
  5. Si KO → analyser l'erreur → retry (max 3 fois)
  6. Si 3 echecs → circuit breaker → escalation → story suivante
- Chaque story reussie = un commit git
- Produit : code + commits + logs

#### 7. REVIEW (`/project:br-review`)
- **4 agents QA en parallele** :
  - Correctness (criteres d'acceptation)
  - Securite (OWASP, injection, auth)
  - Performance (N+1, memory leaks, indexes)
  - Conformite architecture
- Note globale : A/B/C/D/F
- Decision : PASS / CONDITIONAL_PASS / FAIL
- Si FAIL → genere des stories de correction et relance

---

## Toutes les commandes

### Workflow principal

| Commande | Description |
|----------|-------------|
| `/project:br-init <desc>` | Initialiser un projet |
| `/project:br-discover` | Phase decouverte (4 agents paralleles) |
| `/project:br-plan` | Generer le PRD |
| `/project:br-architect` | Designer l'architecture |
| `/project:br-sprint` | Decouper en stories |
| `/project:br-build` | Executer le sprint courant |
| `/project:br-review` | Quality gate |
| `/project:br-auto` | Toutes les phases BMAD d'un coup (s'arrete avant build) |

### Options de build

| Commande | Description |
|----------|-------------|
| `/project:br-build` | Sprint courant |
| `/project:br-build auto` | Tous les sprints a la suite |
| `/project:br-build parallel` | Stories parallelisees avec subagents |
| `/project:br-build story STORY-2.3` | Une story specifique |

### Monitoring et debug

| Commande | Description |
|----------|-------------|
| `/project:br-status` | Dashboard visuel du projet |
| `/project:br-logs` | Resume de tous les logs |
| `/project:br-logs tail` | Dernieres 10 lignes (check rapide) |
| `/project:br-logs errors` | Uniquement les erreurs |
| `/project:br-logs sprint 1` | Log du sprint 1 |
| `/project:br-logs escalations` | Stories en escalation |
| `/project:br-debug` | Diagnostic complet (7 health checks) |
| `/project:br-debug story STORY-X.Y` | Diagnostic cible sur une story |

### Reparation

| Commande | Description |
|----------|-------------|
| `/project:br-fix` | Auto-reparer tous les problemes detectes |
| `/project:br-fix state` | Resynchroniser state.json avec git |
| `/project:br-fix retry STORY-X.Y` | Retry propre d'une story echouee |
| `/project:br-fix rewrite STORY-X.Y` | Reecrire les instructions d'une story |
| `/project:br-fix clean` | Revert les changements non commites |

### Utilitaires

| Commande | Description |
|----------|-------------|
| `/project:br` | Orchestrateur intelligent (detecte quoi faire) |
| `/project:br status` | Raccourci pour br-status |
| `/project:br auto` | Raccourci pour br-auto |
| `/project:br-resume` | Reprendre apres interruption |

---

## Structure des fichiers

### Ce que le skill installe (dans `.claude/`)

```
.claude/
├── commands/          ← 14 slash commands
│   ├── br.md              Orchestrateur principal
│   ├── br-init.md         Initialisation
│   ├── br-discover.md     Phase decouverte
│   ├── br-plan.md         Phase PRD
│   ├── br-architect.md    Phase architecture
│   ├── br-sprint.md       Phase stories
│   ├── br-build.md        Execution Ralph
│   ├── br-review.md       Quality gate
│   ├── br-auto.md         Pipeline automatique
│   ├── br-resume.md       Reprise intelligente
│   ├── br-status.md       Dashboard
│   ├── br-debug.md        Diagnostic
│   ├── br-fix.md          Auto-reparation
│   └── br-logs.md         Viewer de logs
├── agents/            ← 2 agents specialises
│   ├── br-developer.md    Agent dev autonome (sonnet, bypassPermissions)
│   └── br-qa.md           Agent QA read-only (sonnet, bypassPermissions)
├── hooks/             ← 3 hooks
│   ├── br-guard.sh        Protection fichiers sensibles + commandes dangereuses
│   ├── br-monitor.sh      Log automatique de toute activite
│   └── br-post-edit.sh    Auto-format apres chaque edit
└── settings.json      ← Configuration des hooks
```

### Ce que le skill cree dans ton projet (`.bmad-ralph/`)

```
.bmad-ralph/
├── state.json              ← Etat du projet (phase, sprint, metriques)
├── docs/
│   ├── business-brief.md       Synthese de la decouverte
│   ├── prd.md                  Product Requirements Document
│   ├── architecture.md         Architecture systeme
│   └── architecture-amendments.md  (si corrections post-escalation)
├── sprints/
│   ├── sprint-1.md             Stories du sprint 1
│   ├── sprint-2.md             Stories du sprint 2
│   └── ...
├── prompts/
│   ├── ralph-sprint-1.md       Prompt Ralph pour sprint 1
│   └── ...
└── logs/
    ├── monitor.log             Activite en temps reel (auto)
    ├── errors.log              Erreurs detectees (auto)
    ├── sprint-1.log            Log d'execution sprint 1
    ├── escalation-STORY-X.Y.md Rapport d'escalation
    ├── review-sprint-1.md      Rapport de review
    ├── review-correctness-sprint-1.md
    ├── review-security-sprint-1.md
    ├── review-performance-sprint-1.md
    └── review-architecture-sprint-1.md
```

---

## Garde-fous de securite

### Circuit Breaker
Si une story echoue **3 fois de suite**, Ralph arrete de retenter et passe a la suivante. Un rapport d'escalation est cree avec :
- Les 3 tentatives et leurs erreurs
- L'analyse de la cause racine
- La recommandation de fix

### Hook de protection (`br-guard.sh`)
Bloque automatiquement :
- Modification de fichiers `.env`, `.key`, `.pem`, `credentials`
- Commandes dangereuses : `rm -rf /`, `DROP TABLE`, `git push --force`, `git reset --hard`

### Hook de monitoring (`br-monitor.sh`)
Enregistre automatiquement dans `monitor.log` :
- Chaque commande bash executee
- Chaque fichier modifie
- Chaque agent lance
- Chaque erreur (exit code != 0)

### Commits atomiques
Chaque story reussie = un commit git. Si Ralph deraille, tu peux toujours revenir en arriere avec `git revert`.

### Limite d'iterations
- Max **5 tentatives par story**
- Max **40 iterations par sprint**
- Au-dela → pause et rapport

---

## Exemples de cas d'usage

### Projet from scratch

```
/project:br-init "API REST de e-commerce avec panier, paiement Stripe, et gestion de stock"
/project:br-auto
# (review les docs generes)
/project:br-build auto
# (aller dormir)
/project:br-status     ← le matin
/project:br-logs errors ← verifier les problemes
```

### Nouvelle feature sur projet existant

```
/project:br-init "Ajouter l'authentification OAuth2 (Google + GitHub) au projet"
/project:br-auto
/project:br-build
/project:br-review
```

### Migration / Refactoring

```
/project:br-init "Migrer de Express a Fastify en gardant tous les tests verts"
/project:br-auto
/project:br-build auto
```

### Quand ca bloque

```
/project:br-status              ← ou en est-on ?
/project:br-logs errors         ← quelles erreurs ?
/project:br-debug story STORY-2.3  ← diagnostic cible
/project:br-fix retry STORY-2.3    ← retry propre
# ou
/project:br-fix rewrite STORY-2.3  ← reecrire la story et retry
```

### Reprendre apres interruption

```
/project:br-resume
```

---

## Configuration avancee

### Modifier les limites Ralph

Editer `.bmad-ralph/state.json` :

```json
{
  "ralph": {
    "max_iterations_per_story": 5,      // tentatives par story
    "max_iterations_per_sprint": 40,    // iterations max par sprint
    "circuit_breaker_threshold": 3      // echecs avant escalation
  }
}
```

### Desactiver l'auto-format

Retirer le hook `br-post-edit.sh` de `.claude/settings.json` dans la section `PostToolUse`.

### Ajouter des fichiers proteges

Editer `.claude/hooks/br-guard.sh` et ajouter des patterns dans la fonction `is_protected()`.

### Utiliser un modele different pour les agents

Editer `.claude/agents/br-developer.md` et changer la ligne `model:` :
```
model: opus    # plus puissant mais plus cher
model: haiku   # plus rapide et moins cher
model: sonnet  # equilibre (defaut)
```

---

## FAQ

**Q: Combien ca coute en tokens ?**
Le test NoteAPI (7 stories, 23 tests) a utilise environ 45K tokens pour l'execution Ralph. Un gros projet (30+ stories) peut aller de $5 a $50+ selon la complexite.

**Q: Ca marche avec quel stack ?**
Tout. Le skill detecte le tech stack automatiquement. Teste avec : TypeScript/Node, Python, Rust, Go. L'architecture s'adapte.

**Q: Je peux modifier les stories avant que Ralph les execute ?**
Oui. Apres `br-auto`, les stories sont dans `.bmad-ralph/sprints/`. Edite-les a la main avant de lancer `br-build`.

**Q: Que faire si Ralph boucle sans avancer ?**
```
/project:br-logs errors         ← voir le pattern d'erreur
/project:br-debug               ← diagnostic complet
/project:br-fix                 ← auto-reparation
```

**Q: Je peux utiliser ca dans un CI/CD ?**
Oui, en mode non-interactif :
```bash
claude -p "/project:br-build auto" --max-turns 100
```

---

## Inspirations

- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) — Breakthrough Method for Agile AI-Driven Development
- [Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) — Autonomous loop technique
- [RIPER-5](https://github.com/tony/claude-code-riper-5) — Research/Innovate/Plan/Execute/Review
- [Context Engineering](https://github.com/coleam00/context-engineering-intro) — Structured context for AI coding

---

## License

MIT — Utilise, modifie, partage librement.
