# Contrat T1 v2 — transfert entre cartes

Gelé avant tout entraînement T1 v2 et avant lecture des résultats de validation, le 2026-09-27.
Le contrat v1 reste archivé. Ses deux défauts détectés par lecture du code préparé sont :
la disponibilité était copiée depuis l'état initial après cueillette ; la clé de table
concaténait les trois slots et l'action précédente, rendant les cartes de validation presque
toutes inédites pour la table. Aucun résultat de validation ou de test T1 n'a servi à cet amendement.

Le monde, les seeds, bras, budgets, checkpoints, métriques et seuils sont ceux du contrat v1.
Les cartes de test final restent fermées. Le nouvel identifiant est `t1_choice_v2` et l'empreinte :

```text
t1_choice_v2|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|state=available_sector_distance_previous
```

L'observation garde les trois slots dans leur ordre tiré au sort ; `available` lit le stock réel
au moment de l'observation. La clé tabulaire abstrait les distracteurs :
`(secteur du slot disponible, classe de distance de ce slot, action précédente)`.
Elle emploie exclusivement des champs observés. Deux cartes avec la même cible disponible et
les mêmes valeurs de ces trois champs partagent ainsi les valeurs Q. Une observation sans stock
positif n'est rencontrée qu'à la fin d'un épisode réussi.

Pendant l'entraînement uniquement, la mise à jour Q reçoit
`r_train = r_base + 0,50 × (distance_avant − distance_après)` vers le roncier disponible,
avec la distance horizontale mesurée par Godot à chaque action. `r_base` reste `+1` une fois à la
consommation réelle et `0` sinon. Le façonnage n'est ni dans l'observation ni dans les métriques
d'évaluation. Tous les bras sont évalués avec le même monde, les mêmes actions et la même
récompense de résultat. Le candidat, s'il réussit, sera décrit comme une politique apprise avec
ce signal d'entraînement auxiliaire.

Le checkpoint v2 est sauvegardé puis rechargé avant l'évaluation de chaque palier. La comparaison
porte sur le checksum, les actions et résultats obtenus à seed fixe. Le validateur refuse tout
identifiant, empreinte ou lot incomplet. La campagne ne commence qu'après les tests de physique,
de stock, de table et un probe de débit sur une carte d'entraînement. Toute modification après
lecture de validation exige un nouveau contrat et de nouvelles réserves.
