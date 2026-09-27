# Contrat expérimental T1 — choix alimentaire persistant v1

Statut : préenregistré après le gate T0 v2 et avant toute implémentation ou mesure T1.
Ce contrat est indépendant de T0 et de l'axe danger. Il ne modifie ni leurs campagnes, ni leurs
seeds réservés.

## Hypothèse et périmètre

H0 : une table initialisée à zéro ne sélectionne pas plus souvent la seule ressource disponible
qu'un contrôle aléatoire comparable, et ne conserve aucun avantage entre épisodes.

H1 : une table tabulaire entraînée, sauvegardée puis rechargée sélectionne et consomme plus
souvent la seule ressource disponible que son état initial, le contrôle aléatoire et la même
table remise à zéro entre épisodes.

T1 mesure un choix parmi plusieurs ressources visibles, pas la mémoire ni la navigation du monde
complet. Le moteur Godot reste l'autorité pour le déplacement, le contact, la cueillette et la
consommation. Une diminution de distance, l'arrivée près d'un roncier vide ou la seule cueillette
ne constituent pas une réussite.

## Monde, épisode et horloge

| Élément | Valeur verrouillée |
| --- | --- |
| Arène | carré plan de 24 m de côté, centre `(0, 0, 0)`, murs physiques aux limites |
| Agent | un Rouge à l'origine, faim initiale `50`, inventaire vide, mémoire désactivée |
| Ronciers | trois ronciers visibles dès le début, chacun avec collision de contact et collision physique |
| Disponibilité | exactement un roncier contient une mûre ; les deux autres ont un stock nul |
| Distances | permutation de `3 m`, `6 m` et `9 m`, tirée depuis la seed de carte |
| Secteurs | trois secteurs distincts parmi les huit secteurs T0, tirés depuis la seed de carte |
| Faim et inventaire | déplétion désactivée ; `max_berries_carried = 1` ; seuils de cueillette et consommation à `50` |
| Danger, agents tiers, obstacles, mémoire | désactivés |
| Action | huit directions T0, 15 ticks physiques de `1/60 s`, soit `0,25 s` simulée |
| Horizon | 24 actions, soit `6,0 s` simulées ; `game_speed = 1,0` |
| Succès | la mûre de l'unique roncier disponible est réellement cueillie puis consommée ; `terminated=true` |
| Échec | mort éventuelle : `terminated=true` ; horizon sans consommation : `truncated=true` |
| Coupure technique | erreur, timeout ou arrêt opérateur : run invalide, jamais une troncature ni un échec |

Les secteurs ont le même ordre que T0 : `N`, `NE`, `E`, `SE`, `S`, `SO`, `O`, `NO`. Les trois
emplacements et le slot disponible sont dérivés exclusivement de `card_seed` par un RNG local au
scénario. Chaque seed reconstruit exactement les mêmes secteurs, distances, stocks et ordre des
slots. L'ordre des slots est une permutation déterministe indépendante de la distance et de la
disponibilité : aucun tri ne révèle la cible.

## Observation et actions autorisées

L'observation T1 est exactement :

```text
targets : trois slots, chacun = (resource_sector: 0..7,
                                 distance_bin: 0..2,
                                 available: bool)
previous_action : entier 0..7 ou START avant la première action
```

`distance_bin` code respectivement `3 m`, `6 m` et `9 m`. `available` correspond au stock réel
du roncier, sans anticiper une cueillette future. Les coordonnées absolues, la seed, l'identité du
slot disponible, tout état hors perception, la solution scriptée, la table et toute carte
antérieure sont interdits. Après une cueillette, l'observation reflète le stock réellement vidé.

Les huit actions directionnelles ont la même vitesse et la même durée. Il n'existe ni action
d'immobilité, ni macro-action vers une ressource. Le masque, si l'interface en fournit un, expose
toujours les huit actions et ne dépend ni du slot disponible ni de sa direction.

Le champ `first_selected_available` est une métrique journalisée, pas une observation : il vaut
vrai seulement si la première action de l'épisode est la direction du slot disponible. Il reste
faux dans tous les autres cas, y compris lorsqu'une consommation survient ensuite.

## Retour et transition

La récompense vaut `+1` une seule fois lors de la consommation réelle qui suit la cueillette de
la mûre disponible ; elle vaut `0` sinon. Il n'y a ni récompense de distance, ni prime pour un
roncier vide, ni récompense pour la seule direction correcte. La transition de consommation est
écrite avant la terminaison et n'est jamais doublée. Une terminaison ne bootstrappe pas ; une
troncature applique le bootstrap seulement si l'algorithme le prévoit explicitement.

Le candidat est Q-learning tabulaire : table nulle, `alpha = 0,20`, `gamma = 0,90`, epsilon-greedy
avec `epsilon = 0,20` à l'entraînement et `0` à l'évaluation. Les ex æquo gloutons sont résolus
par l'identifiant d'action le plus petit. La clé d'état sérialise les trois slots dans leur ordre
déterministe et `previous_action`. Elle n'utilise aucune coordonnée absolue.

Un reset reconstruit l'arène, Rouge, les trois ronciers, leurs collisions, stocks, compteurs et
RNG de carte. Seuls la table, le RNG d'entraînement, le compteur d'épisodes, le schéma et
l'empreinte de configuration persistent. Une évaluation ne modifie aucun de ces éléments.

## Seeds distinctes et verrouillées

| Usage | Seeds |
| --- | --- |
| Cartes d'entraînement T1 | `320000001..320000032` |
| Cartes de validation T1 | `320000101..320000132` |
| Cartes de test final T1 | `320000201..320000264` |
| Initialisations développement | `320001001`, `320001002`, `320001003` |
| Initialisations confirmation | `320001101`, `320001102`, `320001103`, `320001104`, `320001105` |
| RNG du bras aléatoire | `320002001`, `320002002`, `320002003`, `320002101`, `320002102` |

Ces collections sont disjointes entre elles et des réserves T0 ainsi que des plages historiques
danger et apprentissage. Une seed de carte ne sert jamais de seed d'initialisation. Elles ne
peuvent être modifiées, complétées ou réordonnées après le premier entraînement ; cela exigerait
une nouvelle version du contrat et de nouvelles réserves.

## Bras, budget et empreinte

L'identifiant d'expérience est `t1_choice_v1`. L'empreinte de configuration est :

```text
t1_choice_v1|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90
```

| Bras | Entraînement | Évaluation |
| --- | --- | --- |
| `scripted_observed` | aucun | choisit le secteur du slot observé avec `available=true` ; diagnostic de solvabilité |
| `initial_frozen` | aucun | table nulle, epsilon `0`, figée |
| `random_valid` | aucun | tirage uniforme parmi les huit actions, même cadence et exécutant |
| `trained` | table persistante | checkpoint choisi sur validation, epsilon `0`, figé |
| `reset_each_episode` | mêmes hyperparamètres, table recréée avant chaque épisode | dernier état obtenu, epsilon `0`, figé |

Pour chaque initialisation de développement, `trained` et `reset_each_episode` consomment au plus
`1 000` épisodes. Les checkpoints obligatoires sont `0`, `10`, `50`, `200` et `1 000`. Les
cartes d'entraînement sont parcourues cycliquement dans l'ordre verrouillé. Avant le premier lot,
mesurer le débit, le temps médian de reset et la mémoire ; plus de `2 GiB` ou un épisode complet
de plus de `60 s` réelles invalident le lancement et demandent un diagnostic technique.

## Analyse et gate T1

Chaque checkpoint est évalué sur les 32 cartes de validation sans mise à jour. Pour chaque lignée,
le checkpoint retenu maximise d'abord le taux de consommation réussie, puis le taux de
`first_selected_available`; une égalité choisit le checkpoint le plus précoce. Les 64 cartes de
test final restent fermées pendant T1.

La métrique primaire est la consommation réussie. La métrique causale est
`first_selected_available`. Les secondaires sont cueillettes réelles, consommations réelles,
actions jusqu'à consommation, raison de terminaison et checksum de table. Les comparaisons sont
appariées par `(initialization_seed, card_seed)`. Le rapport publie chaque lignée, les 96 paires
de validation, les égalités, les runs absents et les doublons. Tout lot incomplet est refusé, sans
imputation.

Le gate T1 est atteint seulement si, sur les 96 évaluations de validation :

1. `scripted_observed` consomme 96/96 ;
2. `trained` consomme au moins `0,80` ;
3. `trained` gagne au moins `0,25` en consommation contre `initial_frozen` et `random_valid` ;
4. `trained` atteint au moins `0,90` de `first_selected_available` et gagne au moins `0,30`
   sur chacun des deux contrôles ;
5. chaque lignée `trained` a un gain strictement positif sur les deux métriques contre les deux
   contrôles ;
6. le checkpoint rechargé reproduit exactement actions, résultats et checksum de l'évaluation ;
7. `reset_each_episode` ne satisfait pas simultanément les critères 2 à 5.

Un échec est publié comme `critère non atteint` ou `indéterminé` selon la complétude. Il ne permet
ni de modifier les métriques après coup, ni de consulter le test final pour régler le candidat.

## Tests requis avant toute mesure T1

1. chaque seed génère trois secteurs distincts, les trois distances et exactement un stock positif ;
2. l'ordre des slots ne varie pas avec la disponibilité et ne trie ni distance ni stock ;
3. les trois ronciers ont une collision de contact et une collision physique ;
4. sur chaque placement, `scripted_observed` cueille puis consomme réellement l'unique mûre ;
5. un contact avec un roncier vide ne produit ni cueillette, ni consommation, ni récompense ;
6. la récompense de consommation est unique, terminale et jamais perdue ;
7. les huit actions conservent vitesse, durée et symétrie T0 ;
8. les observations ne contiennent ni seed, ni coordonnées absolues, ni identité cachée de cible ;
9. le masque reste identique lorsque le slot disponible change ;
10. même seed et même trace d'actions produisent mêmes placements, événements et summary ;
11. reset après succès ou troncature reconstruit stocks, collisions et compteurs ;
12. évaluation figée : checksum, compteur d'épisodes et RNG d'entraînement sont inchangés ;
13. sauvegarde/recharge et incompatibilité de schéma ou d'empreinte sont respectivement acceptées
    et rejetées ;
14. la remise à zéro entre épisodes ne conserve aucune valeur de table ;
15. le validateur rejette run manquant, doublon, seed hors réserve, champ causal absent ou valeur
    booléenne invalide.

Toute implémentation T1 doit produire une campagne et un validateur distincts de T0, avec les
champs `consumed`, `first_selected_available`, `berries_picked` et `berries_eaten` ajoutés aux
résultats. Aucun résultat T0 ne peut compléter ou remplacer un résultat T1.
