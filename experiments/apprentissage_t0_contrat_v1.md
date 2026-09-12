# Contrat expérimental T0 — apprentissage alimentaire persistant v1

Statut : préenregistré en Phase 0 de `roadmap_apprentissage_fonctionnel_proposition.md`.

Ce contrat décrit une expérience nouvelle. Il ne modifie ni les campagnes historiques ni leurs
seeds réservés. Aucun résultat ne peut être attribué à T0 avant que le scénario, les tests et le
chargeur de résultats définis ici existent.

## Hypothèse et périmètre

H0 : une table initialisée à zéro ne conserve pas un avantage après des épisodes distincts.

H1 : une table tabulaire, entraînée sur T0 puis rechargée, choisit la direction du roncier visible
mieux que son état initial, qu'un tirage aléatoire comparable et qu'une même table réinitialisée
entre épisodes.

T0 contient un seul Rouge, aucun autre agent, aucun danger, aucun souvenir, aucun obstacle et un
roncier contenant exactement une mûre. Le moteur Godot reste l'autorité pour le déplacement, le
contact et la cueillette. Une position proche ou une diminution de distance ne constitue pas une
réussite.

## Monde, épisode et horloge

| Élément | Valeur verrouillée |
| --- | --- |
| Arène | carré plan de 24 m de côté, centre `(0, 0, 0)`, murs physiques aux limites |
| Rouge | position initiale `(0, 0, 0)`, faim `50`, inventaire vide, capacité positive |
| Ronce | une seule, une mûre, position à 8 m du centre dans le secteur de la carte |
| Perception | ronce visible dès le début ; son secteur relatif est l'unique information de cible |
| Danger, agents tiers, mémoire | désactivés |
| Action | 15 ticks physiques de 1/60 s, soit 0,25 s simulée, par décision |
| Horizon | 48 actions, soit 12,0 s simulées ; `game_speed = 1,0` |
| Succès | `try_pick_berry_from_ronce` retire réellement l'unique mûre ; épisode `terminated=true` |
| Échec | mort éventuelle : `terminated=true` ; horizon atteint sans cueillette : `truncated=true` |
| Coupure technique | erreur, timeout ou arrêt opérateur : run invalide, jamais une troncature ni un échec |

Les huit secteurs sont, dans l'ordre de leur identifiant, `N`, `NE`, `E`, `SE`, `S`, `SO`, `O`,
`NO`. La position de la ronce est le vecteur unitaire de ce secteur multiplié par 8 m. Le mapping
de carte est obligatoire : `secteur = card_seed mod 8`. Il rend la rotation contrôlable sans
exposer la seed ni les coordonnées absolues à la politique.

## Observation et actions autorisées

L'observation T0 est exactement :

```text
resource_sector : entier 0..7
resource_visible : vrai
previous_action : entier 0..7 ou START avant la première action
```

`resource_sector` est calculé dans le repère local de Rouge. Les coordonnées monde, la seed, la
distance exacte, le stock hors perception, la solution scriptée, la table et tout état d'une carte
antérieure sont interdits dans l'observation. `resource_visible` est conservé pour figer le schéma
commun, bien qu'il soit toujours vrai avant succès dans T0.

Les actions sont exactement les huit directions ci-dessus, à vitesse identique et pendant la même
durée. Il n'y a ni action d'immobilité, ni diagonale manquante, ni macro-action vers la ressource.
Un masque d'action, si l'interface en fournit un, vaut toujours les huit actions valides et ne peut
pas dépendre du secteur.

## Retour et transition

La récompense de transition vaut `+1` une seule fois pour la cueillette réelle, `-1` pour une mort
sans cueillette et `0` sinon, y compris à l'horizon. La transition portant `+1` est écrite avant la
terminaison et n'est jamais doublée. Une troncature utilise le bootstrap de l'état final seulement
si l'algorithme l'autorise explicitement ; une mort ou un succès n'utilise aucun bootstrap.

Le candidat principal est Q-learning tabulaire : table initiale nulle, `alpha = 0,20`,
`gamma = 0,90`, epsilon-greedy avec `epsilon = 0,20` pendant l'entraînement puis `0` en évaluation.
Les ex æquo à la sélection gloutonne sont résolus par l'identifiant d'action le plus petit. Cet
ordre doit être identique dans tous les bras non aléatoires.

Un reset reconstruit l'arène, Rouge, la ronce, son stock, les compteurs, le RNG de l'épisode et
l'état transitoire du décideur. Seuls les paramètres de la table, le RNG d'entraînement, le
compteur d'épisodes, la version de schéma et l'empreinte de configuration persistent dans un
checkpoint. Une évaluation ne modifie aucun de ces paramètres.

## Seeds distinctes et verrouillées

Les seeds sont des entiers explicites ; les bornes sont inclusives.

| Usage | Seeds |
| --- | --- |
| Cartes d'entraînement T0 | `310000001..310000016` |
| Cartes de validation T0 | `310000101..310000132` |
| Cartes de test final commun | `310000201..310000264` |
| Initialisations développement | `310001001`, `310001002`, `310001003` |
| Initialisations confirmation | `310001101`, `310001102`, `310001103`, `310001104`, `310001105` |
| RNG du bras aléatoire | `310002001`, `310002002`, `310002003`, `310002101`, `310002102` |

Les trois collections de cartes sont disjointes entre elles et des plages historiques connues de
la roadmap v2 et du danger. Une seed de carte ne sert jamais de seed d'initialisation. Les listes
ne peuvent être complétées, remplacées ou réordonnées après le premier entraînement ; une nouvelle
version du contrat et de nouvelles réserves sont alors requises.

## Bras et budgets T0

| Bras | Entraînement | Évaluation |
| --- | --- | --- |
| `scripted` | aucun | choisit le secteur observé ; diagnostic de solvabilité seulement |
| `initial_frozen` | aucun | table nulle, epsilon 0, figée |
| `random_valid` | aucun | tirage uniforme parmi les 8 actions, même cadence et exécutant |
| `trained` | table persistante | checkpoint choisi sur validation, epsilon 0, figé |
| `reset_each_episode` | mêmes hyperparamètres que `trained`, table remise à zéro à chaque épisode | dernier état obtenu, epsilon 0, figé |

Pour chaque initialisation de développement, `trained` et `reset_each_episode` consomment au plus
1 000 épisodes. Les checkpoints obligatoires sont ceux obtenus après `0`, `10`, `50`, `200` et
`1 000` épisodes. Les cartes d'entraînement sont parcourues cycliquement dans leur ordre ci-dessus.
La seed d'initialisation fixe les tirages epsilon-greedy ; l'ordre des cartes ne dépend pas de cette
seed. Aucun ajustement d'hyperparamètre ou ajout de variante ne peut être lancé sans hypothèse
écrite, budget explicite et nouvelle entrée de campagne.

Avant le premier lot, mesurer séparément le débit des épisodes complets, le temps médian de reset et
la mémoire du processus. Le budget matériel est refusé si le scénario consomme plus de 2 GiB ou si
un épisode sans coupure dépasse 60 s réelles ; ces cas demandent un diagnostic technique, pas une
campagne partielle.

## Choix du checkpoint, analyses et critères T0

À chaque checkpoint, chaque lignée est évaluée sur les 32 cartes de validation, sans mise à jour.
Le checkpoint retenu pour cette lignée est celui ayant le plus grand taux de réussite ; une égalité
choisit le checkpoint le plus précoce. Les cartes de test final ne sont pas exécutées durant T0.

La métrique primaire est la réussite par carte (cueillette réelle avant l'horizon). Secondaires :
nombre d'actions jusqu'à succès, nombre de cueillettes, raison de terminaison et checksum de table.
Les comparaisons sont appariées par `(initialization_seed, card_seed)`. Le rapport publie chaque
lignée, les 96 paires de validation, les égalités, les runs absents et les doublons. Un lot incomplet
est refusé, sans imputation.

Le gate T0 est atteint seulement si, sur les 96 évaluations de validation :

1. `scripted` réussit 96/96 ;
2. `trained` réussit au moins 0,90 ;
3. son gain de réussite est au moins 0,30 contre `initial_frozen` et contre `random_valid` ;
4. chaque lignée `trained` a un gain strictement positif contre ces deux références ;
5. le checkpoint rechargé produit exactement les mêmes actions et résultats que celui évalué avant
   sauvegarde ;
6. `reset_each_episode` ne satisfait pas simultanément les critères 2 à 4.

Le gate établit une première preuve d'ingénierie, non une généralisation au monde complet. Un échec
est rapporté comme `critère non atteint` ou `indéterminé` selon la complétude du lot ; il ne justifie
ni une campagne danger ni un changement rétroactif de métrique.

## Matrice du curriculum

| Niveau | Information et choix | Référence de succès | Décision de progression |
| --- | --- | --- | --- |
| T0 | un secteur visible, 8 directions symétriques | gate ci-dessus, persistance après recharge | prouver la chaîne complète |
| T1 | plusieurs ressources visibles, choix de cible | collecte et consommation ; contrôle omniscient diagnostic | introduire le choix, pas la mémoire |
| T2 | ressources hors champ, dernière perception explicitement stockée | comparaison observation seule / mémoire | établir le besoin d'information historique |
| T3 | monde procédural alimentaire, puis agents fixes ; danger désactivé | exigences du contrat commun de la roadmap | valider la fonctionnalité alimentaire |

Un contrôle omniscient n'est permis qu'en `scripted` de diagnostic : il ne participe pas aux
comparaisons équitables et ne fournit aucune démonstration à `trained`.

## Tests requis avant toute mesure T0

1. huit placements : le contrôle scripté cueille la mûre réelle ;
2. hors contact : aucune récompense ni terminaison de succès ;
3. huit actions : même vitesse, même durée et symétrie géométrique ;
4. même seed et trace d'actions : même summary et mêmes événements ;
5. reset après succès ou horizon : monde et stock reconstruits ;
6. récompense de cueillette suivie de terminaison : une transition `+1`, ni perdue ni doublée ;
7. mort et troncature : sémantiques et bootstrap distincts ;
8. sauvegarde/recharge : table, schéma, empreinte et RNG reproduisent la suite ;
9. évaluation figée : checksum de table inchangé ;
10. schéma ou empreinte incompatible : checkpoint rejeté ;
11. aucune valeur initiale ne précharge l'action correspondant à un secteur ;
12. rapport : rejet d'un run manquant, d'un doublon ou d'un croisement de seeds.

L'interface RL actuelle, qui expose sept directions et ne reconstruit pas le monde à son reset, ne
satisfait pas ce contrat. T0 requiert un chemin expérimental distinct avant toute exécution.
