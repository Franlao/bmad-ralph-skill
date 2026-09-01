# BMAD-Ralph : construire un projet de A a Z avec Claude Code

> **Page Confluence** | Espace : Engineering | Statut : Actif
> Depot : https://github.com/Franlao/bmad-ralph-skill

## 1. En bref

BMAD-Ralph est un pack de skills pour Claude Code. Il fait deux choses :

1. **Planifier** (methode BMAD) : decouverte, PRD, architecture, decoupage en stories.
2. **Executer** (boucle Ralph) : Claude code chaque story, la verifie, la commit, tout seul.

Tu decris ton projet en une phrase. Claude produit les specs, puis le code.

| Info | Valeur |
|---|---|
| Contenu | 23 skills, 2 agents, 3 hooks |
| Langages supportes | tous (le stack est detecte automatiquement) |
| Teste sur | TypeScript/Node, Python, Rust, Go |
| Licence | MIT |

## 2. Prerequis

* Claude Code installe et connecte.
* Git.
* `jq` recommande (sans lui, les hooks tombent sur un parsing python3/sed, moins robuste, et la fusion des settings doit se faire a la main).
* Sous Windows : lancer l'installeur depuis **Git Bash**, pas PowerShell ni cmd.

## 3. Installation

```bash
git clone https://github.com/Franlao/bmad-ralph-skill.git ~/bmad-ralph-skill
```

Installation sur un projet :

```bash
cd ton-projet/
bash ~/bmad-ralph-skill/install.sh --project
```

Installation globale (tous les projets) :

```bash
bash ~/bmad-ralph-skill/install.sh --global
```

Desinstallation : `bash ~/bmad-ralph-skill/install.sh --uninstall [--global]`.
Les donnees du projet (`.bmad-ralph/`) ne sont pas supprimees.

### Cas Windows

Si `bash` du PATH pointe vers un stub WSL casse, l'installeur le detecte et fige le chemin du Git Bash utilise. Pour forcer un chemin :

```bash
BR_BASH="C:/Program Files/Git/bin/bash.exe" bash ~/bmad-ralph-skill/install.sh --project
```

Ce chemin est propre a la machine. Si `.claude/settings.json` est commite en equipe, deplacer le bloc `hooks` dans `.claude/settings.local.json` (non commite).

> **Attention : le global masque le projet.** Pour les skills, `~/.claude/` ecrase `.claude/`. Si BMAD-Ralph est installe aux deux endroits, c'est la version globale qui tourne. `/br-config` le signale.

## 4. Demarrage rapide

```text
/br-init "Application de gestion de taches avec collaboration en equipe"
/br-auto
/br-build auto
```

1. `/br-init` : prepare le projet et redige le brief.
2. `/br-auto` : enchaine decouverte, PRD, architecture, stories, puis s'arrete pour que tu relises.
3. `/br-build auto` : Ralph code tous les sprints.

## 5. Le pipeline

```text
INIT -> DISCOVER -> PLAN -> ARCHITECT -> SPRINT_PREP -> EXECUTE -> REVIEW -> DONE
          (BMAD)   (BMAD)    (BMAD)       (BMAD)       (Ralph)    (QA)
```

| Phase | Commande | Ce qu'elle produit |
|---|---|---|
| INIT | `/br-init "<desc>"` | `.bmad-ralph/state.json`, `docs/brief.md`, commandes de test/lint validees en les executant |
| DISCOVER | `/br-discover` | `docs/business-brief.md` (4 agents en parallele : marche, concurrence, faisabilite technique, codebase) |
| PLAN | `/br-plan` | `docs/prd.md` : user stories P0/P1/P2, criteres d'acceptation, comportement en cas d'echec |
| ARCHITECT | `/br-architect` | `docs/architecture.md` : stack, schema DB, endpoints, variables d'env, graphe de dependances, strategie d'erreur |
| SPRINT | `/br-sprint` | `sprints/sprint-N.md` : stories detaillees (fichiers exacts, etapes, commande de verification) |
| EXECUTE | `/br-build` | Le code, un commit par story, les logs |
| REVIEW | `/br-review` | Rapport QA (correctness, securite, performance, architecture), note A a F, decision PASS / CONDITIONAL_PASS / FAIL |

### Details utiles

* **INIT** lance vraiment les commandes de test avant de les enregistrer. Un `pytest` du PATH peut viser un autre environnement que `python3 -m pytest`.
* **DISCOVER** sonde le runtime reel au lieu de citer la doc. Exemple trouve en test : `NaN` passe le parsing `Decimal`.
* **ARCHITECT** fait relire son brouillon par un panel d'experts (staff engineer, securite, agentic, chef de projet, devops). Chaque objection est integree ou rejetee par ecrit.
* **REVIEW** trie chaque constat : **VIOLATION** (le code enfreint une exigence ecrite, donc story de correction) ou **LACUNE** (l'exigence manque, donc amendement d'architecture).

### La boucle Ralph

Pour chaque story :

1. lire les instructions ;
2. implementer ;
3. verifier (tests, typecheck) ;
4. si OK : commit, puis story suivante ;
5. si KO : analyser l'erreur, retenter (3 fois max) ;
6. si 3 echecs : circuit breaker, rapport d'escalation, story suivante.

Les regles de la boucle vivent a un seul endroit : `.claude/skills/br-ralph-protocol/SKILL.md`. Toute modification se fait la. `bash tests/run-structure-tests.sh` verifie qu'aucune copie n'est reapparue ailleurs.

## 6. Les commandes

### Workflow

| Commande | Role |
|---|---|
| `/br-init <desc>` | Initialiser le projet |
| `/br-discover` | Phase decouverte |
| `/br-plan` | Generer le PRD |
| `/br-architect` | Designer l'architecture |
| `/br-sprint` | Decouper en stories |
| `/br-build` | Executer le sprint courant |
| `/br-review` | Quality gate |
| `/br-auto` | Toutes les phases de planification d'un coup |

### Options de build

| Commande | Usage |
|---|---|
| `/br-build` | Sprint courant seulement, pour relire entre chaque |
| `/br-build auto` | Tous les sprints a la suite, gate incluse, arret des qu'une gate n'est pas un PASS |
| `/br-build parallel` | Stories independantes en parallele : plus rapide, plus couteux en tokens |
| `/br-build story STORY-2.3` | Une seule story |

### Suivi et diagnostic

| Commande | Usage |
|---|---|
| `/br-status` | Tableau de bord du projet |
| `/br-logs` | Resume des logs |
| `/br-logs tail` | 10 dernieres lignes |
| `/br-logs errors` | Erreurs uniquement |
| `/br-logs sprint 1` | Log d'un sprint |
| `/br-logs escalations` | Stories bloquees par le circuit breaker |
| `/br-debug` | Diagnostic complet (7 verifications) |
| `/br-debug story STORY-X.Y` | Diagnostic cible sur une story |

### Reparation

| Commande | Usage |
|---|---|
| `/br-fix` | Detecte et corrige les problemes courants |
| `/br-fix state` | Resynchroniser `state.json` avec git |
| `/br-fix retry STORY-X.Y` | Relancer une story apres reset du compteur d'echecs |
| `/br-fix rewrite STORY-X.Y` | Reecrire les instructions d'une story, puis relancer |
| `/br-fix clean` | Annuler les changements non commites |
| `/br-rollback` | Revenir en arriere sur une story ou un sprint |

### Utilitaires

| Commande | Usage |
|---|---|
| `/br` | Orchestrateur : lit l'etat et dit quoi faire ensuite |
| `/br-resume` | Reprendre apres un crash ou une fermeture de terminal |
| `/br-config` | Voir et modifier la configuration |
| `/br-test` | Lancer les tests |
| `/br-metrics` | Taux de reussite, iterations, cout estime |
| `/br-scope` | Ajouter ou retirer des fonctionnalites |
| `/br-deploy` | Generer Dockerfile, CI/CD, instructions de deploiement |
| `/br-mcp` | Installer des serveurs MCP |
| `/br-update` | Mettre a jour le skill |

## 7. Fichiers

### Installes dans `.claude/`

```text
.claude/
  skills/      23 skills (br, br-init, br-build, br-ralph-protocol, ...)
  agents/      br-developer.md (sonnet, autonome), br-qa.md (sonnet, rapport seul)
  hooks/       br-guard.sh, br-monitor.sh, br-post-edit.sh, br-lib.sh
  templates/   CLAUDE.md
  settings.json
```

### Crees dans le projet (`.bmad-ralph/`)

```text
.bmad-ralph/
  state.json          etat du projet (phase, sprint, metriques)
  docs/               brief.md, business-brief.md, prd.md, architecture.md
  sprints/            sprint-1.md, sprint-2.md, ...
  logs/               monitor.log, errors.log, sprint-N.log, escalations, rapports de review
```

## 8. Garde-fous

| Garde-fou | Ce qu'il fait |
|---|---|
| Circuit breaker | 3 echecs consecutifs sur une story : arret des retries et rapport d'escalation |
| Max tentatives par story | 5 (plafond dur, utile seulement si le circuit breaker est remonte) |
| Max iterations par sprint | 40, au-dela : pause et rapport |
| Max cycles de quality gate | 3 sur un meme sprint, au-dela : escalation |
| `br-guard.sh` | Bloque l'ecriture des secrets (`.env`, `*.key`, `*.pem`, `id_rsa*`, `credentials.json`) et les commandes dangereuses (`rm -rf /`, `DROP TABLE`, `git push --force`, `git reset --hard`, `curl \| sh`) |
| `br-monitor.sh` | Journalise chaque commande, fichier modifie, agent lance et erreur |
| Commits atomiques | Une story reussie egale un commit, donc `git revert` toujours possible |

Precisions sur le guard :

* Le filtrage se fait sur le **nom** du fichier, pas le chemin. `src/config/secrets.ts` reste editable, sinon Ralph bouclerait sur une story impossible a reparer.
* `.env.example` reste autorise, `--force-with-lease` aussi.
* Les commandes de lecture (`grep`, `cat`, `git log`) ne declenchent rien.
* C'est une blocklist best-effort, un filet de securite, pas un bac a sable. Tests : `bash tests/run-guard-tests.sh`.

## 9. Un modele par phase

| Phase | Modele par defaut | Pourquoi |
|---|---|---|
| discover, plan, architect, sprint, review, auto, scope | `opus` | Synthese et redaction de specs, la qualite conditionne la suite |
| build, resume, fix, test, agents dev et qa | `sonnet` | Execution cadree par des specs, gros volume de tokens |
| status, logs, metrics, debug, rollback, deploy, mcp, update, init, br | aucun | Elles lisent et affichent, donc modele de la session |

Changer un role : `/br-config model architect fable`
Tout changer : `/br-config model opus`
Revenir au modele de session : `/br-config model dev inherit`
Profil qualite max : `/br-config model best`

La disponibilite d'opus et fable depend de l'abonnement. En cas d'erreur "model not available", rabattre le role sur `sonnet`.

Verifier quel modele a reellement tourne :

```bash
grep -o '\[model:[^]]*\]' .bmad-ralph/logs/monitor.log | sort | uniq -c
```

## 10. Configuration

Limites Ralph, dans `.bmad-ralph/state.json` :

```json
{
  "ralph": {
    "max_iterations_per_story": 5,
    "max_iterations_per_sprint": 40,
    "circuit_breaker_threshold": 3
  }
}
```

Autres reglages :

* Desactiver l'auto-format : retirer `br-post-edit.sh` de la section `PostToolUse` de `.claude/settings.json`.
* Proteger d'autres fichiers : ajouter des motifs dans `is_protected()` de `.claude/hooks/br-guard.sh`.
* Changer le modele d'un agent : ligne `model:` dans `.claude/agents/br-developer.md`.

## 11. Depannage

| Symptome | Marche a suivre |
|---|---|
| Je ne sais plus ou j'en suis | `/br-status`, sinon `/br` |
| Une erreur quelque part | `/br-logs errors`, puis `/br-debug` |
| Une story echoue en boucle | `/br-debug story STORY-X.Y`, puis `/br-fix retry` ou `/br-fix rewrite` |
| Terminal ferme, session perdue | `/br-resume` |
| `state.json` desynchronise de git | `/br-fix state` |
| Fichiers modifies non commites | `/br-fix clean` |
| Les commandes `/br-*` editees n'ont aucun effet | Version globale installee qui masque le projet, verifier avec `/br-config` |

## 12. FAQ

**Combien ca coute ?**
Test NoteAPI (7 stories, 23 tests) : environ 45K tokens pour l'execution. Un projet de 30 stories ou plus : de 5 a 50 dollars selon la complexite.

**Quels stacks ?**
Tous. Le stack est detecte automatiquement. Valide sur TypeScript/Node, Python, Rust, Go.

**Puis-je relire et corriger les stories avant execution ?**
Oui. Apres `/br-auto`, elles sont dans `.bmad-ralph/sprints/`. Edite-les avant `/br-build`.

**Utilisable en CI/CD ?**
Oui, en mode non interactif :

```bash
claude -p "/br-build auto" --max-turns 100
```

## 13. References

* BMAD Method : https://github.com/bmad-code-org/BMAD-METHOD
* Ralph Wiggum plugin : https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md
* RIPER-5 : https://github.com/tony/claude-code-riper-5
* Context Engineering : https://github.com/coleam00/context-engineering-intro
