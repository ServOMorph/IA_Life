# Confirmation indépendante T3 v3 — critère non atteint (7 critères sur 8)

Date : 2026-09-30. Statut : invalidé au sens du contrat gelé ; aucune nouvelle exécution.

Contrat : `experiments/apprentissage_t3_confirmation_contrat_v1.md`, commité avec l'outillage au
commit `c31c0520` avant toute exécution sur les cartes finales `410000201..410000264`
(enregistré dans `experiments/t3_confirmation_final_manifest.json`). Lot final unique :
5 entraînements indépendants (`410001101..105`), checkpoint 200 fixé d'avance, 64 cartes, soit
1 600 résultats conformes ; rejeu des 5 checkpoints identique après rechargement.

## Résultats

| Bras | Survies | Taux |
| --- | ---: | ---: |
| `trained` | 201/320 | 0,628 |
| `initial_frozen` | 40/320 | 0,125 |
| `random_valid` | 31/320 | 0,097 |
| `reset_each_episode` | 37/320 | 0,116 |
| `scripted_food` | 280/320 | 0,875 |

Gains de `trained` : 0,503 contre l'initial et 0,531 contre l'aléatoire ; intervalles bilatéraux
corrigés à 97,5 % `[0,434 ; 0,572]` et `[0,463 ; 0,600]`, strictement positifs. Gain positif dans
les 5 lignées (0,47 à 0,56). L'ablation par remise à zéro ne rattrape rien (intervalles touchant
zéro). Non-régression alimentaire et rechargement satisfaits.

## Verdict

Le critère 1 du contrat (survie de `scripted_food` ≥ 0,90) échoue : 0,875. Les autres critères
sont satisfaits. Le contrat exige tous les critères et interdit de modifier un seuil après
ouverture : le résultat est **critère non atteint**, non requalifié.

Lecture, sans changer le verdict :
- Le critère en échec mesure la solvabilité des 64 cartes pour l'automate de référence, pas
  l'apprentissage. L'automate fait 0,906 en validation contre 0,875 ici ; une variation de tirage
  de cartes est une hypothèse plausible, non établie.
- La survie de `trained` (0,628) dépasse le seuil de 0,60 de 0,028 seulement, contre 0,72 en
  validation sur le même protocole : la généralisation sur cartes fraîches est inférieure à ce
  que la validation indiquait.
- Les gains de l'apprentissage sont stables entre lignées et causalement dus à la persistance.

## Suite

Le lot final est consommé : il ne peut servir ni à choisir un correctif ni à être rejoué. Une
validation propre exige un contrat de confirmation v2 avec de nouvelles cartes et de nouvelles
graines, dont un critère de solvabilité défini sur un échantillon dédié et une décision explicite
sur le réalisme du seuil de survie de 0,60.

Le décideur `politique_apprise` (`scripts/t3_applied_controller.gd`) reste livré comme
fonctionnalité expérimentale, sans revendication de validation. Sa démonstration fenêtrée est en
attente dans `tests_manuels.md`.

## Reproduction

```powershell
$env:PYTHONPATH='tools'
.venv/Scripts/python.exe tools/run_t3_confirmation.py --godot D:/Godot/godot_console.exe --cards final --confirm-freeze --jobs 3
.venv/Scripts/python.exe tools/replay_t3_confirmation.py --godot D:/Godot/godot_console.exe --cards final --jobs 3
.venv/Scripts/python.exe tools/analyze_t3_confirmation.py --cards final
```

Résultats : `experiments/t3_confirmation_final_results.jsonl`,
`experiments/t3_confirmation_final_analysis.json`,
`experiments/t3_confirmation_final_workers/`, `experiments/t3_confirmation_final_replay_*.jsonl`.
