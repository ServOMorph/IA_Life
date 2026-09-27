# Phase 4 — T1 non validé

Statut : invalidé pour T1 v3. Commentaire : la consommation atteint 82/96, mais la première direction correcte reste à 69/96, sous le seuil causal ; v4 est documenté séparément et la Phase 4 demeure ouverte.

Le travail T1 préparé a été corrigé avant mesure : l'observation lit désormais le stock réel,
et la table v2 regroupe les cartes par secteur/distance de la ressource disponible plutôt que
par l'ensemble des trois slots. Un signal d'entraînement de progression mesuré par Godot a été
préenregistré. Après l'échec v2, une hypothèse v3 séparée a été testée sur de nouvelles seeds :
une table contextuelle apprend le premier pas sans bootstrap, puis Q-learning pilote la suite.
Les contrats v1, v2 et v3 restent distincts.

| Expérience et bras | Consommations | Première direction correcte |
| --- | ---: | ---: |
| v2 scripté | 96/96 | 96/96 |
| v2 initial | 12/96 | 12/96 |
| v2 aléatoire | 4/96 | 9/96 |
| v2 entraîné | 74/96 | 19/96 |
| v2 remise à zéro | 12/96 | 12/96 |
| v3 scripté | 96/96 | 96/96 |
| v3 initial | 12/96 | 12/96 |
| v3 aléatoire | 9/96 | 8/96 |
| v3 entraîné | 82/96 | 69/96 |
| v3 remise à zéro | 12/96 | 13/96 |

Chaque campagne contient 1 248 résultats complets et valides ; le choix préenregistré retient
le checkpoint 1 000 pour les trois lignées. En v3, les lignées entraînées consomment 29/32,
26/32 et 27/32, avec 23/32, 17/32 et 29/32 premières directions correctes. Le seuil de
consommation 0,80 est atteint en v3 (82/96), mais le seuil causal 0,90 échoue (69/96).
Le gate T1 exige tous les critères : **critère non atteint**. Aucun test final T1 n'a été utilisé.
T2 et T3 ne sont pas engagés, car le niveau de choix préalable n'est pas validé.

Les tests Godot couvrent les 32 cartes d'entraînement, les collisions, le contact vide, la
consommation réelle, la remise à zéro, la disponibilité après cueillette, le transfert de clé,
le crédit terminal unique, l'évaluation figée, et les sauvegardes/recharges v2 et v3. Cinq tests
Python couvrent le manifeste de 1 248 clés et les rejets du validateur. Le probe v3 headless
donne 0,022 s pour un épisode scripté de 13 actions et 25 165 806 octets de mémoire statique
Godot ; ces chiffres ne préjugent pas du débit du monde complet. Les deux campagnes ont été
évaluées en processus Godot séparés avec `--fixed-fps 60`.

Le checksum de la table rechargée est identique avant les évaluations de chaque checkpoint ;
le test de sauvegarde vérifie aussi le choix sur un état connu. Une comparaison exhaustive des
traces d'actions originales et rechargées n'a pas été exécutée. Ce critère de recharge ne peut
donc pas être déclaré entièrement satisfait, même si le gate échoue déjà sur la première
direction. T1 utilise encore son scénario direct Godot, pas l'adaptateur Gym du monde.

Reproduction : `python tools/run_t1_campaign.py --contract v3 --godot D:/Godot/godot.exe --jobs 3 --resume`,
`python tools/t1_results.py experiments/t1_v3_results.jsonl --contract v3`,
`python tools/analyze_t1.py --contract v3`. Les résultats v2 ont la même commande avec
`--contract v2` et restent dans `experiments/t1_v2_results.jsonl`.

La suite exigerait une nouvelle hypothèse et de nouvelles réserves. Réutiliser les validations
v2/v3 pour régler la politique transformerait le gate en jeu d'entraînement. La roadmap ne
permet pas de déclarer la Phase 4 franchie à partir de la seule consommation.

## Diagnostic rétrospectif des premiers pas — 2026-09-27

Les trois checkpoints v3 retenus ont été rejoués sur les 96 couples
`(initialization_seed, card_seed)` de validation. Après une nouvelle sauvegarde et recharge,
les 96 traces d'actions et résultats sont identiques aux traces obtenues avant cette recharge.
Les huit champs de résultat et les checksums concordent avec la campagne initiale pour les
96 couples. La campagne initiale ne journalisait pas les traces d'actions ; l'identité de ces
traces avec la campagne initiale ne peut donc pas être établie rétrospectivement.

Sur les 27 premières actions hors du secteur exact, **27/27 sont dans un secteur adjacent** et
**27/27 réduisent la distance réelle à la ronce disponible**. Parmi elles, 17 épisodes se
terminent par une consommation et 10 échouent. **11/27 directions adjacentes correspondent
exactement au secteur d'un roncier vide** ; 5 de ces 11 épisodes consomment ensuite malgré ce
départ. La réussite est de 65/69 lorsque la première action prend le secteur exact. Parmi les
actions adjacentes, la consommation vaut 7/7 à 3 m, 6/9 à 6 m et 4/11 à 9 m. Une progression
géométrique vers la mûre ne suffit donc pas à établir que le premier choix de ressource est bon.
L'écart angulaire a un coût réel sur les trajets longs.
Ce diagnostic ne change ni le seuil ni le verdict v3. Les cartes de test final restent fermées.

Reproduction : lancer `tools/t1_replay.tscn` avec chaque checkpoint 1 000 et la seed
d'initialisation correspondante, puis `python tools/analyze_t1_replay.py`. Les 96 traces sont
dans `experiments/t1_v3_replay_*.jsonl`.

## Suite T1 v4 — 2026-09-27

L'exploration équilibrée préenregistrée atteint 96/96 premières directions exactes sur les
nouvelles validations, mais 70/96 consommations, sous le seuil de 0,80. Le gate T1 reste non
atteint. Les échecs surviennent après le premier pas, surtout à 6 et 9 m. Détail :
`_docs/decisions/2026-09-27_t1-v4-gate-non-atteint.md`. Les seeds de test final T1 v4 restent
fermées et T2/T3 ne sont pas engagés.
