# Gate T0 v4 atteint

Date : 2026-09-26. Phase 2, première preuve alimentaire entre épisodes.
Statut : validé. Commentaire : tous les seuils préenregistrés du gate T0 v4 sont atteints sur le lot complet ; la portée reste limitée aux huit secteurs de la micro-tâche.

## Décision

Le contrat T0 v4, gelé avant la mesure, atteint le gate de validation. Le signal de progression a permis à la table persistante d'apprendre les huit directions de la micro-tâche. T1 était gelé jusqu'au checkpoint `/compact` et à la décision de reprise du travail T1 déjà engagé. Les seeds de test final T0 v4 et T1 restent fermées.

## Résultats

Le lot `experiments/t0_v4_results.jsonl` contient 1 248 résultats et aucune erreur de structure, de doublon, de seed ou d'empreinte. Les checkpoints retenus selon la règle préenregistrée sont 200, 200 et 1 000 épisodes pour les initialisations 340001001, 340001002 et 340001003.

| Bras | Réussites / 96 |
| --- | ---: |
| `scripted` | 96 |
| `initial_frozen` | 12 |
| `random_valid` | 57 |
| `trained` | 96 |
| `reset_each_episode` | 8 |

Le gain de `trained` est de 84/96 = 0,875 contre l'initialisation et de 39/96 = 0,40625 contre l'aléatoire. Chaque lignée entraînée réussit 32/32 ; les lignées aléatoires réussissent 21/32, 19/32 et 17/32. Le contrôle scripté réussit 96/96. Les seuils absolu et comparatifs du contrat passent. `reset_each_episode` échoue aux seuils du candidat.

Les trois lignées entraînées ont été rejouées après la campagne : leurs 160 résultats par lignée sont identiques octet pour octet aux premiers fichiers de résultats. À chaque checkpoint, la table a été sauvegardée puis rechargée sans perte ; les actions, résultats et checksums sont identiques sur les 32 validations. Les checkpoints retenus sont conservés dans `experiments/t0_v4_checkpoints/`.

## Portée et limite

La carte est déterminée par `card_seed mod 8` : les 32 validations couvrent quatre fois les mêmes huit secteurs. Ce gate est une preuve d'apprentissage et de persistance dans cette micro-tâche ; il ne démontre pas une généralisation à 32 géométries distinctes ni une compétence dans le monde complet. Le retour de progression utilise la distance physique durant l'entraînement seulement. La réussite évaluée reste la cueillette réelle.

La suite devait traiter explicitement le travail T1 préexistant et les limites de représentation avant toute campagne T1. Les statuts de roadmap et de `signals.md` ont été mis à jour lors du `/close` du 2026-09-27.
