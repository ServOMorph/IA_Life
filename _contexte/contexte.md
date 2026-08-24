# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Le prototype est un laboratoire headless reproductible : configurations versionnées, logs JSONL,
résumés et campagnes. Le bridge RL TCP/JSONL maison est validé (épisode complet sans NaN via
`rl/client_random.py`). `VariableRegistry` est la source unique des défauts/bornes de `GameConfig`
et `Character` (Phases 0-1 de `roadmap_experimentation.md` closes). Contexte du jeu tranché : cadre
non historique (île isolée) ; le rig reste limité au personnage de développement.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-17 : Mémoire spatiale des ronciers par personnage + collision physique des ronces.
- 2026-08-17 : Correctif bug terrain invisible (culling) + relief escarpé + cuvettes de
  spawn + capture d'écran automatisée (`run_screenshot.py`) + skill `synthese-projet`.
- 2026-08-17 : Validation manuelle terrain/relief/faim-mort + correctif luminosité (scène
  de jour) ; mode dev (roadmap depuis archivée dans
  `_docs/archives/2026-08-23_roadmap_mode-dev.md`) en cours de construction (Phases 1-2 faites).
- 2026-08-18 : Checklist en jeu (Phase 3 mode dev) + pivot vers un personnage de test
  contrôlable manuellement (remplace F1-F4 seul), voir `_docs/decisions/2026-08-18_*.md`.
- 2026-08-18 : Personnage riggé (Phase 5 graphisme, Blender custom généré par script)
  branché uniquement sur le personnage de test, validé — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- 2026-08-22 : Refonte visuelle des ronces (buisson vert fixe + mûres noires visibles,
  retrait à la cueillette) ; test manuel 5 validé — voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
- 2026-08-23 : Le rig Blender reste un outil du personnage de développement ; les quatre
  agents normaux conservent un rendu léger afin de préserver la priorité expérimentale.
- 2026-08-23 : Après échec des bridges tiers, le projet retient provisoirement un bridge
  TCP/JSONL maison pour le premier RL.
- 2026-08-24 : Cadre non historique (île isolée) retenu pour l'identité du jeu, sans ancrage
  temporel — voir `DOCUMENTATION/orientation_contexte.md`.
- 2026-08-24 : `VariableRegistry` devient la source unique des valeurs par défaut/bornes de
  `GameConfig` et `Character` ; bridge RL TCP/JSONL maison validé (épisode complet).
