# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 4 personnages lowpoly, dont un est piloté par le développeur et les autres par des LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible. Axe apprentissage en pause : confirmation T3 v3 en critère non
atteint (7/8, solvabilité scriptée 0,875 sous 0,90), cartes finales consommées ; axe danger en pause.
Nouvelle orientation décidée : 4 agents pilotés par LLM (`gemma3:1b`), roadmap `roadmap_survie_llm.md`
(Phase 0 en cours, aucun code écrit). Ollama ne répondait pas en fin de session.
Décideur `politique_apprise` livré en jeu (expérimental, non validé).

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-09-24 : T0 v3 (ronce à 3 m) est invalidé : 1 248 résultats conformes, mais `trained`
  atteint 0,458 contre 0,604 pour `random_valid` et échoue au seuil absolu. T1 reste gelé ; voir
  `_docs/decisions/2026-09-24_t0-v3-gate-non-atteint.md`.
- 2026-09-26 : T0 v4 franchit le gate sur 1 248 résultats : `trained` 96/96, initial 12/96,
  aléatoire 57/96. La recharge reproduit les décisions ; preuve limitée aux huit secteurs T0.
  Voir `_docs/decisions/2026-09-26_t0-v4-gate-atteint.md`.
- 2026-09-26 : Phase 3 valide le bridge TCP/JSONL et les adaptateurs Gymnasium T0/monde :
  12 tests d'intégration, vérification SB3 et 24/24 secteurs T0 des checkpoints retenus.
  Voir `_docs/decisions/2026-09-26_phase3-interface-t0.md`.
- 2026-09-27 : T1 v2/v3/v4 échouent au gate. V4 apprend le premier choix (96/96), mais
  consomme dans 70/96 cas, sous le seuil de 0,80. Phase 4 ouverte ; diagnostic de navigation
  requis avant tout nouveau contrat. Voir `_docs/decisions/2026-09-27_t1-v4-gate-non-atteint.md`.
- 2026-09-28 : T1 v5 franchit le gate : la direction tenue remplace les redécisions instables
  et produit 96/96 consommations, avec trois checkpoints à 1 000 stables au replay. Voir
  `_docs/decisions/2026-09-28_t1-v5-gate-atteint.md`.
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
