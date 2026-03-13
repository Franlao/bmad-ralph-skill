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

## Toutes les commandes et comment les utiliser

### Workflow principal

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/project:br-init <desc>` | Initialiser un projet | **En premier.** Decris ton projet en une phrase entre guillemets. |
| `/project:br-discover` | Phase decouverte (4 agents paralleles) | Apres init. Analyse le marche, la concurrence et le codebase. |
| `/project:br-plan` | Generer le PRD | Apres discover. Cree le document produit avec toutes les user stories. |
| `/project:br-architect` | Designer l'architecture | Apres plan. Genere le schema DB, les API, l'arborescence fichiers. |
| `/project:br-sprint` | Decouper en stories | Apres architect. Cree les instructions detaillees pour chaque story. |
| `/project:br-build` | Executer le sprint courant | Apres sprint. Lance Ralph qui code chaque story en autonome. |
| `/project:br-review` | Quality gate | Apres build. 4 agents QA verifient le code (secu, perf, archi). |
| `/project:br-auto` | Toutes les phases BMAD d'un coup | **Le raccourci.** Fait discover+plan+architect+sprint d'un coup, s'arrete avant build pour te laisser relire. |

#### Exemples concrets

```bash
# Projet Python from scratch
/project:br-init "API FastAPI de gestion de factures avec PDF et paiements Stripe"
/project:br-auto
# (relire les docs generes dans .bmad-ralph/docs/)
/project:br-build auto

# Projet TypeScript from scratch
/project:br-init "App Next.js de suivi de budget personnel avec graphiques et export CSV"
/project:br-auto
/project:br-build auto

# Nouvelle feature sur un projet existant
/project:br-init "Ajouter un systeme de notifications push au projet"
/project:br-auto
/project:br-build

# Refactoring
/project:br-init "Migrer de JavaScript a TypeScript tout le dossier src/"
/project:br-auto
/project:br-build auto
```

---

### Options de build

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/project:br-build` | Sprint courant uniquement | Tu veux avancer sprint par sprint et reviewer entre chaque. |
| `/project:br-build auto` | Tous les sprints a la suite | **Tu pars et tu laisses tourner.** Ralph enchaine tous les sprints avec review automatique entre chaque. |
| `/project:br-build parallel` | Stories parallelisees avec subagents | Projets avec beaucoup de stories independantes. Plus rapide mais plus gourmand en tokens. |
| `/project:br-build story STORY-2.3` | Une story specifique | Tu veux relancer ou tester une seule story. |

#### Exemples concrets

```bash
# Mode prudent : sprint par sprint
/project:br-build              # sprint 1
/project:br-review             # verifier
/project:br-build              # sprint 2 (auto-incremente)
/project:br-review

# Mode autonome total : tout d'un coup
/project:br-build auto         # tous les sprints, tu peux partir

# Relancer une story qui a echoue
/project:br-build story STORY-1.4

# Mode rapide avec parallelisation
/project:br-build parallel
```

---

### Monitoring et debug

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/project:br-status` | Dashboard visuel du projet | **A tout moment.** Voir la progression, le sprint courant, les stories faites. |
| `/project:br-logs` | Resume de tous les logs | Vue d'ensemble de ce qui s'est passe. |
| `/project:br-logs tail` | Dernieres 10 lignes | **Check rapide.** Tu reviens et tu veux savoir ce qui vient de se passer. |
| `/project:br-logs errors` | Uniquement les erreurs | Quelque chose a echoue, tu veux comprendre pourquoi. |
| `/project:br-logs sprint 1` | Log d'un sprint specifique | Voir le detail d'execution d'un sprint en particulier. |
| `/project:br-logs escalations` | Stories en escalation | Voir les stories qui ont echoue 3 fois (circuit breaker). |
| `/project:br-debug` | Diagnostic complet (7 health checks) | **Quand ca bloque.** Verifie state.json, git, fichiers, dependances. |
| `/project:br-debug story STORY-X.Y` | Diagnostic cible sur une story | Comprendre pourquoi UNE story specifique echoue. |

#### Exemples concrets

```bash
# Tu reviens apres une pause, tu veux savoir ou ca en est
/project:br-status

# Ralph a tourne, tu veux un check rapide
/project:br-logs tail

# Quelque chose a plante
/project:br-logs errors
/project:br-debug

# Une story specifique echoue en boucle
/project:br-debug story STORY-2.3
```

---

### Reparation

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/project:br-fix` | Auto-reparer tous les problemes | **Premier reflexe quand ca bloque.** Detecte et corrige les problemes courants. |
| `/project:br-fix state` | Resynchroniser state.json avec git | Le state.json est desynchronise (stories marquees "done" mais pas commitees, ou l'inverse). |
| `/project:br-fix retry STORY-X.Y` | Retry propre d'une story | Relance une story echouee apres avoir reset son compteur d'echecs. |
| `/project:br-fix rewrite STORY-X.Y` | Reecrire les instructions d'une story | La story echoue parce que ses instructions sont mauvaises. Reecrit les instructions puis retry. |
| `/project:br-fix clean` | Revert les changements non commites | Ralph a laisse des fichiers modifies mais pas commites. Nettoie tout. |

#### Exemples concrets

```bash
# Quelque chose ne va pas, je sais pas quoi
/project:br-fix

# state.json dit sprint 2 mais git montre que sprint 2 est deja fini
/project:br-fix state

# STORY-2.3 a echoue 3 fois, je veux retenter
/project:br-fix retry STORY-2.3

# Les instructions de la story sont mauvaises, il faut les reecrire
/project:br-fix rewrite STORY-2.3

# Ralph a laisse du bazar, je veux repartir propre
/project:br-fix clean
```

---

### Utilitaires

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/project:br` | Orchestrateur intelligent | **Tu sais pas quoi faire.** Il lit le state et te dit la prochaine etape. |
| `/project:br status` | Raccourci pour br-status | Meme chose que br-status. |
| `/project:br auto` | Raccourci pour br-auto | Meme chose que br-auto. |
| `/project:br-resume` | Reprendre apres interruption | **Tu as ferme le terminal** ou Claude a crash. Reprend exactement ou c'etait. |

#### Exemples concrets

```bash
# Je sais plus ou j'en suis
/project:br

# Nouvelle session Claude apres avoir ferme le terminal
/project:br-resume

# Apres un crash ou une erreur de rate limit
/project:br-resume
```

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
