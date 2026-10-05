# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 4 personnages lowpoly, dont un est piloté par le développeur et les autres par des LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible. Survie LLM livrée avec `gemma3:1b`, mémoire des ronciers et
carte limitée à l'exclusion des bords ; la mesure historique LLM ne valide pas son critère propre.
Décors bloquants livrés : placement sûr, contournements automate/LLM et `decor_collisions` activé
par défaut après gate sur six cartes (automate 102,02 %, LLM 100,84 % de la référence).
Les axes apprentissage et danger restent en pause. Les cinq échecs Phase 8 vision restent à instruire.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-09-29 : T2 v1 franchit le gate : la politique avec mémoire réussit 96/96, contre 12/96
  pour l'état initial et le contrôle sans mémoire ; les replays sont stables. Voir
  `_docs/decisions/2026-09-29_t2-v1-gate-atteint.md`.
- 2026-09-29 : T3 v2 franchit le gate mono-agent : 76/96 pour la politique entraînée, contre
  6/96 initiale et 9/96 aléatoire, avec intervalles corrigés positifs. Voir
  `_docs/decisions/2026-09-29_t3-v2-gate-atteint.md`.
- 2026-09-29 : T3 v3 franchit le gate avec trois concurrents fixes : 71/96 pour la politique
  entraînée, contre 15/96 initiale et 7/96 aléatoire ; replay 96/96 stable. Voir
  `_docs/decisions/2026-09-29_t3-v3-gate-concurrence-atteint.md`.
- 2026-09-30 : confirmation T3 v3 (lot final indépendant, 5 × 64 cartes) : critère non atteint,
  7 critères sur 8. `trained` 201/320 contre 40/320 (initial) et 31/320 (aléatoire) ; seule la
  solvabilité scriptée échoue (0,875 < 0,90). Cartes finales consommées ; suite = contrat v2. Voir
  `_docs/decisions/2026-09-30_t3-v3-confirmation-critere-non-atteint.md`.
- 2026-09-30 : orientation survie pilotée par LLM (4 agents, `gemma3:1b`), axe apprentissage en
  pause. Cible = roncier, ramasser/manger explicites, mémoire illimitée, décision asynchrone sans
  pause, mesure à x1 et `--jobs 1`. Voir `_docs/decisions/2026-09-30_survie-pilotee-par-llm.md`.
- 2026-10-02 : mémoire cartographique `llm_survie` sans influence stratégique : prompt inchangé, directions
  « bord » retirées du schéma Ollama ; usage stratégique reporté. Effet survie non mesuré.
  Voir `_docs/decisions/2026-10-02_memoire-cartographique-llm-survie.md`.
- 2026-10-01 : survie pilotée par LLM livrée (Phases 0 à 5) : `llm_survie` 542 s de vie moyenne
  contre 292 s (automate), 6/6 cartes, 0 repli ; prompt directif et cueillette libre, critère non
  validé. Voir `_docs/decisions/2026-09-30_survie-pilotee-par-llm.md`.
- 2026-10-03 : décors bloquants cadrés par `roadmap_decor_collisions.md` : variable `decor_collisions`
  (défaut `false`) pour arbres et futurs décors, rochers toujours bloquants, placement des rochers
  soumis à la même exclusion que les arbres (références automate et `llm_survie` rompues).
  Voir `_docs/decisions/2026-10-03_decors-collisions-roadmap.md`.
- 2026-10-03 : contrat décors validé (exclusions 3,0 / 5,0 / 1,5 / 3,0 m ; N = 3 s ; M = 12 cartes) ;
  `decor_collisions` livré (défaut `false`). Voir `experiments/decor_collisions_contrat_v1.md`.
- 2026-10-05 : décors bloquants validés sur six cartes appariées ; `decor_collisions` passe à
  `true` par défaut. Automate 102,02 % et LLM 100,84 % de leur référence, zéro échec de détour ;
  les blocages LLM de cible ne sont pas attribuables à un tronc dans l'audit spatial. Voir
  `_docs/decisions/2026-10-03_decor_collisions_gate.md`.
