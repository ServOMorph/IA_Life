# T3 v3 — gate de survie avec trois concurrents fixes atteint

Date : 2026-09-29. Statut : validé sur la réserve de validation ; tests finaux fermés.

Le contrat T3 v3 a été gelé avant toute mesure comparative avec de nouvelles graines `410...`.
Bleu, Vert et Jaune restent actifs, collisionnels et pilotés par la politique fixe alimentaire.
Les quatre personnages partagent faim initiale 50, déplétion 4/s, vision 40 m, mémoire 5 et les
stocks réels des 24 ronciers. Rouge ne reçoit aucune position ni état caché des concurrents.

## Contrôles d'entraînement

Sur les 32 cartes d'entraînement, le scripté survit 29/32, l'initial 5/32 et l'aléatoire 4/32.
Les concurrents consomment effectivement des ressources dans les trois bras. Trois tables
indépendantes entraînées pendant 200 épisodes survivent respectivement 24/32, 27/32 et 24/32,
avec 84, 101 et 90 mûres consommées.

Le reset reproduit les quatre agents et les stocks partagés. Le bridge T3 v3 et l'exécution
directe produisent la même trajectoire pas à pas sur entraînement. Les checkpoints utilisent le
schéma `t3_q_table_v3`, se rechargent exactement et restent figés à l'évaluation.

## Résultats de validation

Le lot contient 1 056 résultats complets et conformes. Les trois checkpoints entraînés retenus
sont à 200 épisodes.

| Bras retenu | Survies | Épisodes avec repas | Mûres consommées |
| --- | ---: | ---: | ---: |
| `scripted_food` | 87/96 | 87/96 | 369 |
| `initial_frozen` | 15/96 | 15/96 | 57 |
| `random_valid` | 7/96 | 7/96 | 21 |
| `trained` | 71/96 | 71/96 | 251 |
| `reset_each_episode` | 16/96 | 16/96 | 62 |

Le gain de survie entraîné vaut 0,583 contre l'initialisation et 0,667 contre l'aléatoire. Les
intervalles bilatéraux corrigés à 97,5 % sont `[0,458 ; 0,698]` et `[0,542 ; 0,781]`. Chaque
lignée entraînée présente un gain strictement positif contre les deux références. L'ablation de
persistance ne satisfait pas le cœur du gate.

Les 96 replays reproduisent les résultats et checksums après recharge, avec des traces d'actions
complètes. Les 34 tests Python de résultats/Gym, les suites de scénario et les analyses de
régression T0 v4, T1 v5, T2 v1 et T3 v2 passent. Les graines finales T0–T3, dont
`410000201..410000264`, restent fermées.

**Gate T3 v3 concurrence : atteint sur validation.** Les niveaux T0, T1, T2 et T3 requis par la
Phase 4 disposent désormais de résultats de validation positifs. Cette décision n'ouvre pas la
confirmation finale de Phase 5 ; le statut de la roadmap reste réservé à `/close` et son
checkpoint `/compact`.

## Reproduction

```powershell
$env:PYTHONPATH='tools'
.venv/Scripts/python.exe tools/run_t3_v3_campaign.py --godot D:/Godot/godot_console.exe --jobs 3
.venv/Scripts/python.exe tools/analyze_t3.py --contract v3
.venv/Scripts/python.exe tools/analyze_t3_replay.py --contract v3
```

Les résultats, l'analyse, les checkpoints et les replays sont dans
`experiments/t3_v3_results.jsonl`, `experiments/t3_v3_analysis.json`,
`experiments/t3_v3_workers/` et `experiments/t3_v3_replay_*.jsonl`.
