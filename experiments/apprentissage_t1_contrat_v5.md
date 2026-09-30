# Contrat T1 v5 — choix unique et exécution de cap

Gelé le 2026-09-28 avant tout entraînement ou lecture de validation T1 v5. Les contrats et
résultats v1 à v4 conservent leurs verdicts. Le diagnostic v4 sur les 32 cartes d'entraînement,
répété pour les trois checkpoints retenus, donne 74/96 consommations avec la politique apprise,
contre 96/96 lorsque le premier cap est maintenu et 96/96 lorsque le cap est recalculé vers la
cible. Les trois modes partent du même premier choix correct 96/96. Aucune carte de validation
ou de test final n'a été utilisée pour ce diagnostic.

## Hypothèse v5

L'échec v4 vient des décisions postérieures au premier pas. Leur clé
`(secteur initial, distance initiale, action précédente)` n'observe pas la position courante ni
la direction relative à la cible. Elle fusionne donc des situations géométriques différentes et
produit des cycles d'actions qui finissent par éloigner ou bloquer l'agent. Le premier choix, la
physique et l'horizon ne sont pas la cause observée.

T1 mesure le choix d'une ressource visible, pas la navigation. V5 sépare ces responsabilités :
la politique choisit une direction une fois au début de l'épisode, puis l'exécutant moteur
maintient ce cap jusqu'à la consommation ou l'horizon. Cette exécution est une compétence
programmée explicitement déclarée ; l'apprentissage porte uniquement sur son choix. Il n'existe
plus de décision Q postérieure au premier pas dans ce contrat.

## Contrat conservé

Le monde, les trois cibles, les distances `3, 6, 9 m`, les stocks, les huit directions, les
collisions, la vitesse, les 15 ticks par primitive, l'horizon maximal de 24 primitives, la
consommation réelle, les cinq bras, les checkpoints et les seuils du contrat T1 v1 restent
inchangés. L'observation initiale reste celle de v4 et ne contient ni seed, ni coordonnées, ni
solution cachée.

Le sélecteur initial v5 reprend l'exploration équilibrée de v4 : pour chaque secteur disponible
observé, il choisit pendant l'entraînement l'action la moins essayée, avec ex aequo au plus petit
identifiant. Le compteur est incrémenté une fois après l'exécution effective. La valeur du choix
reçoit `r_base + 0,50 × distance_progress` sur la première primitive, sans bootstrap. En
évaluation, le meilleur choix appris est utilisé avec ex aequo au plus petit identifiant.

Après ce choix, l'exécutant répète la direction choisie. Il ne lit plus la table, ne reçoit aucune
coordonnée et ne change pas de cible. Le compteur `actions` continue de compter les primitives
physiques réellement exécutées. Tous les bras utilisent exactement cet exécutant :

- `scripted_observed` choisit le secteur disponible puis maintient ce cap ;
- `initial_frozen` choisit l'ex aequo initial puis maintient ce cap ;
- `random_valid` tire une direction uniforme une fois par épisode puis la maintient ;
- `trained` et `reset_each_episode` utilisent leur sélecteur initial puis maintiennent le choix.

Le contrôle `retarget` du diagnostic v4 est exclu de la campagne : il utilise la position réelle
pour recalculer le cap et sert uniquement à localiser le défaut.

## Identifiant, schéma et réserves

```text
t1_choice_v5|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|first_explore=min_count|first_tie=lowest|execution=hold_first
```

Le checkpoint utilise un nouveau schéma `t1_q_table_v5`. Il conserve les valeurs et compteurs du
sélecteur initial, le RNG, le nombre d'épisodes et l'empreinte ; il ne sérialise aucune table de
navigation postérieure au premier choix.

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `370000001..370000032` |
| Cartes de validation | `370000101..370000132` |
| Cartes de test final, fermées | `370000201..370000264` |
| Initialisations de développement | `370001001`, `370001002`, `370001003` |
| Initialisations de confirmation | `370001101..370001105` |
| RNG aléatoire | `370002001..370002003`, `370002101..370002102` |

Ces plages étaient absentes du projet au gel. Elles sont disjointes des versions T1 précédentes,
de T0 et des campagnes de danger. Les validations restent fermées jusqu'à la fin des tests et du
probe sur les seules cartes d'entraînement. Les tests finaux restent fermés tant que le gate de
validation n'est pas atteint.

## Budget, sélection et gate

Trois lignées, au plus 1 000 épisodes chacune, 32 cartes d'entraînement parcourues cycliquement.
Checkpoints `0`, `10`, `50`, `200`, `1 000`. Pour chaque lignée, le checkpoint retenu maximise la
consommation de validation, puis la première direction correcte, puis choisit le palier le plus
précoce. Le lot attendu contient 1 248 résultats complets. Les seuils du contrat T1 v1 restent
inchangés.

Avant toute campagne, les tests sur cartes d'entraînement doivent démontrer : choix unique ; cap
identique sur toutes les primitives d'un épisode ; absence d'appel à une table postérieure au
choix ; compteur secteur/action incrémenté une fois ; même exécutant pour les cinq bras ;
évaluation figée ; sauvegarde/recharge exacte ; contact et consommation réels aux trois distances ;
rejet du schéma v4 ; probe sous les bornes existantes. Aucun résultat de validation v5 ne doit
servir à modifier ce contrat.
