# T3 v2 — probes d'entraînement franchis, validation encore fermée

Date : 2026-09-29. Statut : contrôles d'entraînement atteints ; validation non ouverte.

Après l'arrêt de T3 v1, le contrat v2 porte la vision locale à 40 m et réserve les seeds `400...`.
Sur les 32 nouvelles cartes d'entraînement, le contrôle scripté survit 29/32, l'initial 8/32 et
l'aléatoire 3/32. Le scénario n'est donc ni non solvable selon le seuil préenregistré, ni saturé
par les références.

Trois tables indépendantes ont ensuite reçu 200 épisodes chacune, toujours sur entraînement. Leur
évaluation figée sur les mêmes 32 cartes donne :

| Initialisation | Survies | Repas |
| --- | ---: | ---: |
| `400001001` | 24/32 | 92 |
| `400001002` | 23/32 | 85 |
| `400001003` | 27/32 | 107 |

Les checkpoints utilisent le schéma `t3_q_table_v2`, se rechargent avec le même checksum et ne
changent pas durant l'évaluation. Le temps total entraînement plus évaluation est de 204 à 209
secondes par lignée en trois processus parallèles ; la mémoire statique finale est de 36,5 à
37,0 Mo.

Ces mesures montrent que la représentation tabulaire peut apprendre sur les cartes de
développement. Elles ne démontrent pas la généralisation. Avant d'ouvrir la validation, il reste à
faire passer l'équivalence directe/bridge du contrat T3 et à verrouiller le lanceur, le validateur
et l'analyse bootstrap.
