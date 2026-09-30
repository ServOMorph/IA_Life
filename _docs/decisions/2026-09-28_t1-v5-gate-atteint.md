# T1 v5 — gate de validation atteint

Date : 2026-09-28. Statut : validé sur la réserve de validation ; tests finaux fermés.

Le contrat v5 a été gelé avant l'implémentation et avant l'ouverture des 32 cartes de validation.
Il sépare le choix appris de la ressource et son exécution : une seule direction est choisie,
puis le même exécutant moteur maintient ce cap pour les cinq bras. Cette réussite démontre un
choix de compétence appris, pas une navigation générale apprise.

## Contrôles préalables

La suite Godot couvre le choix unique, le maintien du cap, la consommation réelle, l'exploration
équilibrée, l'évaluation figée, la sauvegarde/recharge et le rejet du schéma v4. Les sept tests
Python du validateur passent. Le probe sur une carte d'entraînement termine en 0,019 seconde avec
25 326 382 octets de mémoire statique, sous les limites préenregistrées.

## Résultats de validation

Le lot contient 1 248 résultats complets et conformes. Les trois checkpoints retenus sont à
1 000 épisodes.

| Bras | Consommations | Premiers choix corrects |
| --- | ---: | ---: |
| `scripted_observed` | 96/96 | 96/96 |
| `initial_frozen` | 9/96 | 9/96 |
| `random_valid` | 13/96 | 13/96 |
| `trained` | 96/96 | 96/96 |
| `reset_each_episode` | 9/96 | 9/96 |

Chaque lignée entraînée réussit 32/32 consommations et 32/32 premiers choix. Les gains agrégés
de `trained` valent 0,906 contre l'état initial et 0,865 contre l'aléatoire sur les deux métriques,
au-dessus des seuils respectifs de 0,25 et 0,30. La remise à zéro ne passe pas le gate.

Les compteurs montrent une exploration équilibrée des huit actions dans chaque secteur observé.
Après sauvegarde et recharge, les 96 replays reproduisent exactement les résultats, décisions et
checksums de la campagne. Tous les secteurs et les trois classes de distance réussissent sans
échec dans le replay.

**Gate T1 v5 : atteint sur validation.** Les 64 cartes de test final restent fermées. T2 et T3
ne sont pas engagés par cette décision.

## Reproduction

```powershell
python tools/run_t1_campaign.py --contract v5 --godot D:/Godot/godot_console.exe --jobs 3
python tools/t1_results.py experiments/t1_v5_results.jsonl --contract v5
python tools/analyze_t1.py --contract v5
python tools/analyze_t1_replay.py --contract v5
```

Les résultats, checkpoints et replays sont dans `experiments/t1_v5_results.jsonl`,
`experiments/t1_v5_workers/` et `experiments/t1_v5_replay_*.jsonl`.
