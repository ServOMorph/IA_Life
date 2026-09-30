# T3 v2 — gate de survie alimentaire mono-agent atteint

Date : 2026-09-29. Statut : validé sur la réserve de validation ; tests finaux fermés.

T3 v2 évalue une table persistante dans le monde procédural du projet, avec relief, murs et
24 ronciers réels, mais sans danger ni concurrents actifs. La portée locale de 40 m avait été
gelée avant validation après les probes d'entraînement.

## Contrôles préalables

Le serveur Gym T3 instancie directement le même `T3Scenario` que les campagnes. Deux trajectoires
sur cartes d'entraînement, avec seize actions chacune, produisent les mêmes observations,
récompenses, stocks et fins d'épisode pas à pas en exécution directe et via bridge. Les huit tests
Gym T3/monde et les tests structurels T3 passent.

Le lot comparatif contient 1 056 résultats complets et conformes. Les trois lignées entraînées
retiennent toutes le checkpoint 200 ; les checkpoints se rechargent avec un checksum identique et
l'évaluation reste figée.

## Résultats de validation

| Bras retenu | Survies | Épisodes avec repas | Mûres consommées |
| --- | ---: | ---: | ---: |
| `scripted_food` | 90/96 | 90/96 | 378 |
| `initial_frozen` | 6/96 | 6/96 | 18 |
| `random_valid` | 9/96 | 9/96 | 29 |
| `trained` | 76/96 | 76/96 | 288 |
| `reset_each_episode` | 7/96 | 7/96 | 21 |

Le gain de survie entraîné vaut 0,729 contre l'initialisation et 0,698 contre l'aléatoire. Les
intervalles bilatéraux corrigés à 97,5 % sont respectivement `[0,604 ; 0,844]` et
`[0,552 ; 0,833]`. Chaque lignée a un gain strictement positif contre les deux références.
L'ablation avec remise à zéro ne satisfait pas le cœur du gate.

Les 96 replays indépendants reproduisent les résultats et checksums après recharge, avec une
trace d'actions complète. Les suites de scénario T0–T3, les 22 tests Python de résultats et les
analyses/replays T1 v5 et T2 v1 passent. Les 64 cartes finales `400000201..400000264` restent
fermées.

**Gate T3 v2 mono-agent : atteint sur validation.** La concurrence des trois agents fixes doit
être introduite sous un nouveau contrat T3 v3 et de nouvelles réserves ; elle ne peut pas être
revendiquée à partir de ce résultat mono-agent. Le statut de la roadmap n'est pas modifié en cours
de session.

## Reproduction

```powershell
$env:PYTHONPATH='tools'
.venv/Scripts/python.exe -m unittest tools/test_t3_gym_env.py tools/test_world_gym_env.py
.venv/Scripts/python.exe tools/run_t3_campaign.py --godot D:/Godot/godot_console.exe --jobs 3
.venv/Scripts/python.exe tools/analyze_t3.py
.venv/Scripts/python.exe tools/analyze_t3_replay.py
```

Les résultats, l'analyse, les checkpoints et les replays sont dans
`experiments/t3_v2_results.jsonl`, `experiments/t3_v2_analysis.json`,
`experiments/t3_v2_workers/` et `experiments/t3_v2_replay_*.jsonl`.
