# T1 v2 — gate non atteint

Statut : invalidé. Commentaire : consommation 74/96 et première direction correcte 19/96, sous les seuils préenregistrés.

La campagne headless `t1_choice_v2` a produit 1 248 résultats. Le validateur a refusé les
doublons, absences, seeds hors réserve, valeurs booléennes invalides et empreintes divergentes ;
le lot final est complet. Les trois checkpoints retenus par la règle préenregistrée sont 1 000.

| Bras | Consommations | Première direction disponible |
| --- | ---: | ---: |
| `scripted_observed` | 96/96 | 96/96 |
| `initial_frozen` | 12/96 | 12/96 |
| `random_valid` | 4/96 | 9/96 |
| `trained` | 74/96 | 19/96 |
| `reset_each_episode` | 12/96 | 12/96 |

Par lignée `trained`, consommations : 28/32, 21/32, 25/32 ; premières directions : 6/32,
5/32, 8/32. Les seuils absolus de 0,80 en consommation et 0,90 sur la première direction
échouent. Le verdict est **critère non atteint**. Les cartes de test final T1 v2 restent fermées.

Le checksum montre que la table apprend souvent à atteindre une ressource après un départ
erroné. La clé `(secteur, distance, action précédente)` multiplie les états de départ ;
l'amorçage Q d'une valeur future peut rendre un premier pas incorrect attirant. C'est une
hypothèse explicative, pas une attribution causale démontrée. Une nouvelle expérience doit
isoler l'apprentissage du premier choix sur de nouvelles seeds, sans réutiliser la validation v2.

Reproduction : `python tools/run_t1_campaign.py --contract v2 --godot D:/Godot/godot.exe --jobs 3 --resume`,
`python tools/analyze_t1.py --contract v2`. Résultats : `experiments/t1_v2_results.jsonl`.
