# Contrat T3 v2 — survie procédurale avec couverture perceptive accrue

Gelé le 2026-09-29 avant toute exécution sur validation T3 v2. T3 v1 reste invalidé sur son probe
d'entraînement, sans ouverture de sa validation.

## Hypothèse v2

À 25 m de vision, le contrôle scripté v1 survit 28/32 cartes d'entraînement ; ses quatre échecs
n'obtiennent aucune mûre avant la mort. Un diagnostic unique à 40 m, tous les autres paramètres
inchangés, atteint 29/32 pour le scripté, contre 3/32 pour l'initial et 1/32 pour l'aléatoire.
L'aléatoire ne sature donc pas.

V2 teste l'hypothèse qu'une portée de 40 m rend le monde minimalement solvable dans la fenêtre de
20 secondes sans supprimer le besoin d'apprendre les directions. Ce changement concerne
l'information locale disponible ; il ne fournit ni coordonnées absolues ni carte complète.

## Contrat

Toutes les règles, bras, récompenses, états, budgets, statistiques, tests et seuils de
`apprentissage_t3_contrat_v1.md` sont conservés, avec seulement ces changements :

- portée de vision Rouge : `40 m` au lieu de `25 m` ;
- identifiant et empreinte :

```text
t3_world_v2|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01
```

- schéma de checkpoint : `t3_q_table_v2`, afin d'empêcher une recharge v1 silencieuse ;
- nouvelles réserves :

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `400000001..400000032` |
| Cartes de validation | `400000101..400000132` |
| Cartes de test final, fermées | `400000201..400000264` |
| Initialisations de développement | `400001001`, `400001002`, `400001003` |
| Initialisations de confirmation | `400001101..400001105` |
| RNG aléatoire | `400002001..400002003`, `400002101..400002102` |
| Bootstrap d'analyse | `400003001` |

Ces plages étaient absentes du projet au gel. La validation v2 reste fermée jusqu'au passage de
tous les contrôles prévus par v1 et d'un probe v2 sur les seules cartes `400000001..400000032`.
Un nouvel échec du contrôle scripté arrête T3 v2 avant entraînement comparatif.

## Précisions d'implémentation gelées avant validation

Les distances normalisées par 160 m sont discrétisées en `proche <= 0,05`,
`moyenne <= 0,12`, `lointaine > 0,12`. La faim normalisée est découpée en quatre quarts et
l'inventaire en vide/non vide. La cible visible disponible est prioritaire sur le premier souvenir
utilisable. La mort coupe le bootstrap ; la troncature temporelle conserve le bootstrap sur la
dernière observation. Le RNG d'exploration appartient au checkpoint.

À l'entraînement, l'ordre des 32 cartes est la permutation déterministe
`(épisode × 5 + seed_initialisation) modulo 32`. Le diagnostic à 200 épisodes sur entraînement
obtient 24/32, 23/32 et 27/32 survies pour les trois lignées. Ce résultat autorise seulement la
construction du lot de validation ; il ne compte pas dans le gate.
