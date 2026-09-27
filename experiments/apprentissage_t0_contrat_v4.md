# Contrat expérimental T0 v4 — signal de progression

Statut : gelé avant toute mesure T0 v4, le 2026-09-26. Les contrats et résultats v1–v3 restent inchangés. T1 reste gelé jusqu'au verdict de ce contrat.

## Hypothèse

À 3 m, le retour `+1` limité à la cueillette laisse la politique gloutonne initiale choisir presque toujours le nord. La table ne découvre pas assez régulièrement les autres directions. Un signal d'entraînement proportionnel au rapprochement physique peut rendre chaque direction informative sans ajouter de cible à l'observation ni changer le critère de réussite.

Cette hypothèse reste incertaine : l'état `(secteur, visibilité, action précédente)` ne contient pas la position après déplacement. Un échec v4 motivera l'abandon de cette représentation T0 plutôt qu'un nouveau réglage de distance ou de coefficient sur les mêmes validations.

## Différence verrouillée avec v3

Monde, observation, huit actions, durée de 15 ticks, horizon de 48 actions, Q-learning (`alpha=0,20`, `gamma=0,90`, epsilon d'entraînement `0,20`), checkpoints et contrôles sont ceux de v3. La ronce reste à 3,0 m. La cueillette réelle reste l'unique succès.

Seul le retour utilisé pour mettre à jour la table pendant l'entraînement change :

`r_train = r_base + 0,50 × (distance_avant − distance_après)`

Les distances sont mesurées au sol entre Rouge et le centre de la ronce, au début et à la fin de chaque action. `r_base` reste `+1` à la cueillette, `−1` à une mort sans cueillette et `0` sinon. Le terme de progression n'est crédité qu'une fois par action exécutée, même si la cueillette interrompt ses 15 ticks. Les bras et l'évaluation figée utilisent la même observation et les mêmes actions ; aucune distance, coordonnée ou récompense façonnée n'est transmise à la politique. Le retour évalué reste `r_base`.

Identifiant : `t0_contract_v4`. Empreinte : `t0_contract_v4|resource_distance=3.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90|progress=0.50`.

## Réserves et budget

| Usage | Seeds |
| --- | --- |
| Cartes d'entraînement | `340000001..340000016` |
| Cartes de validation | `340000101..340000132` |
| Cartes de test final, fermées jusqu'au gate | `340000201..340000264` |
| Initialisations de développement | `340001001`, `340001002`, `340001003` |
| Initialisations de confirmation | `340001101..340001105` |
| RNG aléatoire | `340002001..340002003`, `340002101..340002102` |

Ces plages sont disjointes des versions précédentes et de T1. Comme `card_seed mod 8` détermine seul le placement, les 32 cartes de validation représentent quatre répétitions de chacun des huit secteurs. Les résultats par secteur et par initialisation seront publiés ; les 96 épisodes ne seront pas présentés comme 96 cartes distinctes.

Trois lignées indépendantes, chacune au plus 1 000 épisodes d'entraînement. Checkpoints : `0`, `10`, `50`, `200`, `1 000`. Ordre cyclique des 16 cartes d'entraînement. Avant campagne : probe inférieur à 60 s réelles par épisode et mémoire inférieure à 2 GiB, puis tests du calcul de progression, de l'évaluation figée et du validateur. Aucun coefficient ou seuil ne sera ajusté après lecture du lot.

## Gate

Choisir pour chaque lignée le checkpoint de plus forte réussite sur les 32 validations ; une égalité retient le plus précoce. Lot complet de 1 248 résultats, comparé par `(initialization_seed, card_seed)`. Le gate v3 est conservé : `scripted` 96/96 ; `trained` au moins 0,90 de réussite ; gain d'au moins 0,30 contre `initial_frozen` et `random_valid` ; gain strictement positif pour chaque lignée contre ces deux contrôles ; recharge identique ; `reset_each_episode` ne satisfait pas simultanément les seuils du candidat. Toute ligne absente, dupliquée ou hors contrat invalide le lot.

Si le gate échoue, verdict « critère non atteint ». Les seeds de test final restent fermées et T1 reste gelé jusqu'à une décision explicite sur la suite.
