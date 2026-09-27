# Contrat T1 v3 — apprendre le premier choix

Gelé le 2026-09-27 avant tout entraînement T1 v3 et avant lecture de ses validations.
Le résultat v2 est conservé comme échec. L'hypothèse est que l'amorçage Q de la navigation
ultérieure perturbe la valeur de la première action ; un estimateur séparé de son effet physique
immédiat doit améliorer `first_selected_available` sans enseigner la réponse correcte.

Le scénario, les trois cibles, les huit actions, 15 ticks, l'horizon de 24 actions, la récompense
de résultat et les cinq bras restent ceux du contrat v2. Les trois cibles et leurs disponibilités
sont toutes observées. La table Q v2 continue de choisir les actions après la première ; une
table contextuelle supplémentaire indexée uniquement par le secteur observé de la ressource
disponible choisit la première action. À l'entraînement, elle met à jour la valeur de l'action
effectivement exécutée avec `alpha=0,20` et le retour immédiat
`r_base + 0,50 × distance_progress`. Elle ne bootstrappe pas. Le premier pas emploie
`epsilon=0,50` pendant l'entraînement, puis `0` en évaluation. Les autres pas conservent
`epsilon=0,20`, `alpha=0,20`, `gamma=0,90`. Les ex æquo choisissent l'action de plus petit indice.
Le contrôleur ne reçoit aucune distance géométrique ni solution en observation ; ce signal sert
seulement à la mise à jour pendant l'entraînement.

Identifiant et empreinte :

```text
t1_choice_v3|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_bandit=sector|first_epsilon=0.50
```

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `350000001..350000032` |
| Cartes de validation | `350000101..350000132` |
| Cartes de test final, fermées | `350000201..350000264` |
| Initialisations de développement | `350001001`, `350001002`, `350001003` |
| Initialisations de confirmation | `350001101..350001105` |
| RNG aléatoire | `350002001..350002003`, `350002101..350002102` |

Budget : 1 000 épisodes maximum par initialisation, cartes d'entraînement en cycle,
checkpoints `0`, `10`, `50`, `200`, `1 000`. Choix du checkpoint : consommation de validation,
puis première direction correcte, puis palier le plus précoce. Les seuils et contrôles du contrat
T1 v1 sont repris sans changement : scripté 96/96 ; entraîné ≥0,80 de consommation et gain
≥0,25 contre initial et aléatoire ; première direction ≥0,90 et gain ≥0,30 contre ces deux
contrôles ; chaque lignée gagne sur les deux métriques ; recharge exacte ; remise à zéro
insuffisante. Les 64 cartes de test restent fermées pendant T1. Tout lot incomplet échoue au
validateur et toute modification après validation exige de nouvelles réserves.
