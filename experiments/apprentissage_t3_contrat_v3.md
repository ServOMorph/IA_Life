# Contrat T3 v3 — survie alimentaire avec trois concurrents fixes

Gelé le 2026-09-29 avant toute exécution sur validation T3 v3. T3 v2 reste validé uniquement en
mono-agent et ses réserves ne sont pas réutilisées.

## Hypothèse

La politique tabulaire T3 peut encore apprendre des directions alimentaires utiles lorsque les
trois autres personnages du monde restent actifs, consomment les mêmes stocks et créent des
collisions. Cette étape teste une politique apprise sous concurrence ; elle ne prétend pas encore
observer ni modéliser explicitement les autres agents.

## Contrat

Le monde, l'agent Rouge, l'observation, les huit actions, l'horizon, la récompense, la table et les
seuils statistiques de T3 v2 sont conservés. Les seuls changements fonctionnels sont :

- Bleu, Vert et Jaune restent actifs, visibles et collisionnels ;
- chacun utilise la politique fixe alimentaire du projet : ronce visible, sinon souvenir, sinon
  errance, sans danger ;
- les quatre personnages commencent à 50 de faim, avec déplétion `4,0/s`, vision `40 m`, mémoire
  de cinq ronciers et angle de vision `360°` ;
- les stocks des 24 ronciers sont partagés ; une mûre prise par un concurrent n'est plus
  disponible pour Rouge ;
- les mécaniques sociales normales du projet restent actives et sont identiques dans tous les
  bras.

L'observation de Rouge reste strictement celle de T3 v2. Elle n'ajoute ni position, identité,
inventaire ou objectif des concurrents. Collision et disparition réelle d'un stock restent les
seuls effets concurrents directement observables.

```text
t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01
```

Schéma de checkpoint : `t3_q_table_v3`.

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `410000001..410000032` |
| Cartes de validation | `410000101..410000132` |
| Cartes de test final, fermées | `410000201..410000264` |
| Initialisations de développement | `410001001`, `410001002`, `410001003` |
| Initialisations de confirmation | `410001101..410001105` |
| RNG aléatoire | `410002001..410002003`, `410002101..410002102` |
| Bootstrap d'analyse | `410003001` |

Ces plages n'apparaissaient pas dans les contrats, décisions ou outils avant ce gel.

## Probes, budget et gate

Avant validation, les 32 cartes d'entraînement doivent montrer :

- quatre agents actifs et collisionnels, trois décideurs fixes et aucun danger ;
- reset reproductible des quatre agents et des stocks partagés ;
- au moins 0,90 de survie pour `scripted_food` et absence de saturation de `random_valid` ;
- trois apprentissages indépendants à 200 épisodes, avec sauvegarde/recharge figée ;
- même contrat direct/bridge ; débit et mémoire compatibles avec le budget.

Les bras restent `scripted_food`, `initial_frozen`, `random_valid`, `trained` et
`reset_each_episode`. Checkpoints `0`, `10`, `50`, `200`, puis `1 000` seulement si 200 épisodes
ne permettent pas de conclure. L'ordre d'entraînement reste
`(épisode × 5 + seed_initialisation) modulo 32`.

La sélection et le gate statistique restent ceux de T3 v2 : survie scriptée ≥ 0,90, survie
entraînée ≥ 0,60, gains ≥ 0,10 contre initial et aléatoire, bornes inférieures corrigées
strictement positives, gains positifs par lignée, non-régression alimentaire, persistance et
échec de l'ablation. Les régressions T0–T3 v2 doivent passer.

La validation `410000101..410000132` reste fermée jusqu'au passage des probes. Les graines finales
`410000201..410000264` restent fermées pendant toute la Phase 4.
