# Contrat T3 v1 — survie alimentaire procédurale mono-agent

Gelé le 2026-09-29 avant toute lecture de validation T3. Les verdicts T0 v4, T1 v5 et T2 v1,
ainsi que leurs réserves, restent inchangés. Tous leurs tests finaux restent fermés.

## Portée et hypothèse

T3 v1 introduit le monde procédural complet, son relief, ses murs et ses ronciers, avec un seul
agent actif et le danger strictement désactivé. Les trois agents fixes sont rendus inactifs et
non-collisionnels. Leur concurrence sera un contrat T3 v2 distinct, avec de nouvelles réserves,
seulement si v1 passe.

Hypothèse : une table persistante recevant les cibles visibles et les souvenirs structurés peut
apprendre à sélectionner des directions qui maintiennent l'agent en vie jusqu'à l'horizon. Le
signal de progression accélère l'apprentissage, mais la réussite est uniquement la survie et les
repas réels. Si la table ne représente pas ce choix, son échec doit être constaté avant d'engager
PPO.

## Monde et épisode

- carte procédurale du projet, spawn Rouge `(-40, -40)` et génération issue de la seed ;
- 24 ronciers, 3 mûres chacun, relief et collisions conservés ;
- zéro danger ; trois autres personnages désactivés et sans collision ;
- Rouge : faim initiale `50`, déplétion `4,0/s`, capacité mémoire `5`, portée de vision `25 m`,
  angle `360°`, vitesse `2,5 m/s` ;
- paramètres alimentaires du projet : inventaire `3`, cueillette sous `90`, consommation sous
  `50`, six mûres pour restaurer une vie complète ;
- huit directions monde, 15 ticks physiques par primitive, `game_speed = 1` ;
- horizon de 80 primitives, soit 20 secondes simulées ; un repas ne termine pas l'épisode ;
- terminaison à la mort, troncature vivant à l'horizon.

L'observation autorisée contient faim, inventaire, au plus trois cibles visibles relatives, au
plus trois souvenirs relatifs avec leur force, collision, progression et action précédente. Elle
ne contient ni seed, ni coordonnées absolues, ni liste complète des ressources. Une ronce vide ne
reste ni cible visible disponible ni souvenir utilisable.

## Politique tabulaire et contrôles

La clé tabulaire compacte encode : source prioritaire (`visible`, sinon `mémoire`, sinon `aucune`),
secteur relatif parmi huit, classe de distance parmi trois, classe de faim parmi quatre,
inventaire vide/non vide et action précédente. La cible prioritaire est le premier élément
disponible de l'observation, jamais un objet caché.

L'entraînement utilise Q-learning avec `alpha = 0,20`, `gamma = 0,90` et exploration epsilon
`0,20`. La récompense par primitive vaut `+1` par consommation réelle, `-1` à la mort, plus
`0,25 × progression` vers la cible observée au début de la primitive et `-0,01` de coût de temps.
La progression est bornée à `[-1, 1]`. En évaluation, la table est figée.

Bras :

- `scripted_food` : cible la première ronce visible disponible, sinon le souvenir utilisable le
  plus proche, sinon maintient son cap avec rotation déterministe après collision ;
- `initial_frozen` : même table neutre avant entraînement ;
- `random_valid` : direction uniforme parmi les huit actions ;
- `trained` : table persistante ;
- `reset_each_episode` : même entraînement avec table remise à zéro entre épisodes.

Le contrôle scripté prouve la solvabilité mais ne fournit aucune démonstration. Tous les bras
emploient les mêmes primitives physiques, observations et horizons.

## Identifiant, schéma et réserves

```text
t3_world_v1|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=25|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01
```

Le checkpoint utilise `t3_q_table_v1` et conserve table, RNG, nombre d'épisodes, schéma et
empreinte.

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `390000001..390000032` |
| Cartes de validation | `390000101..390000132` |
| Cartes de test final, fermées | `390000201..390000264` |
| Initialisations de développement | `390001001`, `390001002`, `390001003` |
| Initialisations de confirmation | `390001101..390001105` |
| RNG aléatoire | `390002001..390002003`, `390002101..390002102` |
| Bootstrap d'analyse | `390003001` |

Ces plages étaient absentes du projet au gel. Les validations restent fermées jusqu'au passage
des tests et des probes sur entraînement. Les tests finaux restent fermés pendant toute la Phase 4.

## Budget, sélection et gate

Trois lignées, checkpoints `0`, `10`, `50`, `200`, puis `1 000` seulement si 200 épisodes ne
permettent pas de conclure et si le débit mesuré respecte le budget local. Les 32 cartes
d'entraînement sont parcourues dans un ordre déterministe propre à chaque initialisation.

Le checkpoint retenu maximise d'abord la survie de validation, puis le taux d'au moins un repas,
puis le nombre moyen de repas, puis choisit le palier le plus précoce. Les comparaisons sont
appariées par initialisation et carte.

Pour les gains contre `initial_frozen` et `random_valid`, l'incertitude est estimée par 20 000
bootstraps hiérarchiques appariés : rééchantillonnage avec remise des trois initialisations, puis
des 32 cartes communes. Une correction de Bonferroni utilise un intervalle bilatéral à 97,5 % pour
chacun des deux contrastes.

Le gate v1 est atteint seulement si :

1. `scripted_food` survit sur au moins 0,90 des 96 évaluations ;
2. `trained` survit sur au moins 0,60 ;
3. son gain de survie est au moins 0,10 contre l'initialisation et l'aléatoire ;
4. la borne inférieure corrigée de chacun de ces deux gains est strictement positive ;
5. chaque lignée entraînée a un gain de survie strictement positif contre les deux références ;
6. son taux d'au moins un repas n'est inférieur de plus de 0,05 à aucune des deux références ;
7. sauvegarde/recharge, évaluation figée et replays sont identiques ;
8. `reset_each_episode` ne satisfait pas simultanément les critères 2 à 5 ;
9. les régressions T0 v4, T1 v5 et T2 v1 passent.

Avant toute validation, les tests et probes sur cartes d'entraînement doivent démontrer : reset du
monde, des stocks, des agents et de la mémoire ; trois concurrents réellement inactifs ; aucun
danger ; repas multiples sans terminaison prématurée ; mort et troncature distinctes ; observation
sans carte cachée ; ronce vidée retirée ; crédit unique ; checksum figé en évaluation ;
sauvegarde/recharge ; même contrat en exécution directe et via bridge ; solvabilité scriptée ;
débit et mémoire compatibles avec le palier 200.

Si le scripté échoue ou si la tâche est saturée pour l'aléatoire sur entraînement, corriger ou
versionner le scénario avant validation. Si le scripté passe mais pas la table, documenter la
limite de représentation avant toute campagne PPO. Aucun seuil ne sera modifié après ouverture de
la validation v1.
