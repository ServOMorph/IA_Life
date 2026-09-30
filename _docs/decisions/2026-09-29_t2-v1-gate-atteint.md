# T2 v1 — gate de mémoire explicite atteint

Date : 2026-09-29. Statut : validé sur la réserve de validation ; tests finaux fermés.

Le contrat a été gelé avant l'ouverture des 32 cartes de validation. La tâche sépare une phase de
perception et une phase de décision : la ronce est d'abord dans le cône local, puis le personnage
est tourné de 180 degrés. Au moment du choix, tous les bras voient une observation courante sans
cible ; seul le bras mémoire reçoit le secteur de la dernière perception.

La politique choisit une direction une fois, puis l'exécutant commun maintient ce cap. T2 v1
démontre donc l'apprentissage d'un choix fondé sur une mémoire explicite, pas une navigation
générale apprise ni une mémoire récurrente.

## Contrôles préalables

La suite Godot couvre la perception avant rotation, sa disparition après rotation, la remise à
zéro de la mémoire, l'absence de seed et de coordonnées dans l'observation, l'équilibre des huit
secteurs, les trois distances, la consommation réelle, le choix unique, la reproductibilité,
l'exploration équilibrée, l'évaluation figée, la sauvegarde/recharge et le rejet du schéma T1.
Les cinq tests Python du validateur passent.

Le probe sur une carte d'entraînement termine en 0,006 seconde avec 24 904 838 octets de mémoire
statique. Il consomme la mûre réelle en trois primitives avec une décision de politique.

## Résultats de validation

Le lot contient 1 728 résultats complets et conformes. Les trois checkpoints retenus pour le bras
mémoire sont à 200 épisodes.

| Bras | Consommations |
| --- | ---: |
| `scripted_memory` | 96/96 |
| `initial_memory_frozen` | 12/96 |
| `random_valid` | 16/96 |
| `trained_memory` | 96/96 |
| `trained_observation_only` | 12/96 |
| `reset_each_episode` | 12/96 |

Chaque lignée mémoire entraînée réussit 32/32. Ses gains agrégés valent 0,875 contre l'état
initial, 0,833 contre l'aléatoire et 0,875 contre l'observation seule. Cette dernière reste à
0,125, sous son plafond préenregistré de 0,35. La remise à zéro ne passe pas le gate.

Les 96 replays reproduisent les résultats et checksums de campagne après recharge. Les 96 choix
correspondent au secteur mémorisé. La régression T0 passe par son lanceur et son validateur ; la
régression T1 passe par sa suite, son validateur et ses 96 replays. Les résultats finaux réservés
ne sont pas ouverts.

**Gate T2 v1 : atteint sur validation.** La prochaine étape de la Phase 4 est T3, dans le monde
alimentaire procédural avec danger désactivé. Le statut de la roadmap n'est pas modifié en cours
de session.

## Reproduction

```powershell
D:/Godot/godot_console.exe --headless --path . --scene tools/t2_scenario_tests.tscn
python -m unittest tools/test_t2_results.py
D:/Godot/godot_console.exe --headless --fixed-fps 60 --path . --scene tools/t2_campaign.tscn -- --probe
python tools/run_t2_campaign.py --godot D:/Godot/godot_console.exe --jobs 3
python tools/analyze_t2.py
python tools/analyze_t2_replay.py
```

Les résultats, checkpoints et replays sont dans `experiments/t2_v1_results.jsonl`,
`experiments/t2_v1_workers/` et `experiments/t2_v1_replay_*.jsonl`.
