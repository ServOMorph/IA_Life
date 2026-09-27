# T1 v4 — premier choix appris, consommation sous le seuil

Statut : invalidé. Commentaire : le premier choix atteint 96/96, mais 70/96 consommations ne satisfont pas le seuil primaire de 0,80 ; la Phase 4 reste ouverte.

Le contrat v4 a été gelé avant l'entraînement. Il remplace l'exploration epsilon du premier pas
par le choix de l'action la moins essayée pour chaque secteur observé. Les autres règles du
scénario et les seuils de validation restent ceux du contrat T1 initial. Les seeds v4 sont
nouvelles ; les cartes de test final restent fermées.

Le lot headless contient 1 248 résultats complets et conformes au validateur. Les trois
checkpoints retenus par la règle préenregistrée sont 1 000. Les compteurs sauvegardés montrent
exactement 1 000 premiers essais par lignée ; dans chaque secteur observé, les huit actions ont
des nombres d'essais qui diffèrent d'au plus un.

| Bras | Consommations | Première direction disponible |
| --- | ---: | ---: |
| `scripted_observed` | 96/96 | 96/96 |
| `initial_frozen` | 27/96 | 27/96 |
| `random_valid` | 12/96 | 12/96 |
| `trained` | 70/96 | 96/96 |
| `reset_each_episode` | 27/96 | 27/96 |

Par lignée entraînée : consommations 23/32, 24/32, 23/32 ; premières directions 32/32 pour
chacune. Le critère causal de 0,90 est atteint, mais le seuil primaire de 0,80 en consommation
ne l'est pas (70/96 = 0,729). **Gate T1 v4 : critère non atteint.** Les résultats v3 et v4 ne
sont pas appariés, car ils utilisent des réserves différentes ; leur différence brute de
consommation ne mesure pas l'effet isolé du nouvel explorateur.

Les 96 épisodes des trois checkpoints retenus ont été rejoués. Les traces d'actions sont
identiques avant et après une nouvelle sauvegarde/recharge ; les huit champs de résultat et les
checksums concordent avec la campagne. Les traces de la campagne initiale n'avaient pas été
journalisées. Dans le replay, la première direction est exacte 96/96, mais la consommation
est de 36/36 à 3 m, 21/30 à 6 m et 13/30 à 9 m. Des échecs à 9 m montrent par exemple une
première action correcte puis 23 actions vers le nord, ou une alternance de deux directions
jusqu'à l'horizon. Ce comportement indique un défaut de navigation après le choix initial ;
l'observation tabulaire ne contient pas la position courante. Cette explication reste une
hypothèse, puisque les collisions et les valeurs Q de ces trajectoires n'ont pas été isolées.

Les tests Godot du scénario et de la table v4 passent : compteur unique, équilibre des essais,
évaluation figée, recharge exacte, contact et consommation réels. Six tests Python du
validateur passent. Le probe headless sur une carte d'entraînement a pris 0,008 s pour trois
actions, avec 25 222 394 octets de mémoire statique Godot, sous les bornes préenregistrées.

Reproduction : `python tools/run_t1_campaign.py --contract v4 --godot D:/Godot/godot.exe --jobs 3 --resume`,
`python tools/t1_results.py experiments/t1_v4_results.jsonl --contract v4`,
`python tools/analyze_t1.py --contract v4`, puis replay des checkpoints avec
`tools/t1_replay.tscn` et `python tools/analyze_t1_replay.py --contract v4`.
Les résultats et traces sont dans `experiments/t1_v4_results.jsonl` et
`experiments/t1_v4_replay_*.jsonl`.
