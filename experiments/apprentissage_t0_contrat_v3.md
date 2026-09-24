# Contrat expérimental T0 — apprentissage alimentaire persistant v3

Statut : préenregistré avant toute implémentation ou mesure T0 v3.

Ce contrat remplace T0 v2 uniquement pour une nouvelle expérience. Les contrats, résultats et
seeds T0 v1/v2 restent gelés et ne servent ni à régler ni à confirmer T0 v3.

## Décision et hypothèse

T0 v2 n'atteint pas son gate : `random_valid` réussit trop souvent avec une ronce à 2 m pour
laisser au candidat entraîné la marge préenregistrée de 0,30. La correction retenue est une ronce
à **3,0 m**, sans modifier l'observation, les actions, la récompense, l'algorithme ou le gate.

H0 : une table initialisée à zéro ne conserve pas un avantage après des épisodes distincts.

H1 : une table tabulaire entraînée sur T0 v3 puis rechargée choisit la direction de la ronce
visible mieux que son état initial, qu'un tirage aléatoire comparable et qu'une même table
réinitialisée entre épisodes.

La calibration aléatoire de T0 v2 a seulement motivé cette distance ; elle ne constitue pas une
mesure T0 v3 et ne peut pas être ajoutée au lot ni employée pour modifier ce contrat.

## Monde, épisode et horloge

Toutes les clauses de `apprentissage_t0_contrat_v1.md` restent applicables, avec les substitutions
verrouillées suivantes :

| Élément | Valeur T0 v3 |
| --- | --- |
| Ronce | une seule, une mûre, à **3,0 m** du centre dans le secteur de la carte |
| Identifiant d'expérience | `t0_contract_v3` |
| Empreinte de configuration | `t0_contract_v3|resource_distance=3.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90` |

L'arène reste un carré de 24 m, Rouge démarre à l'origine, les huit secteurs et directions sont
inchangés, une action couvre 15 ticks physiques de 1/60 s et l'horizon est de 48 actions.
La réussite reste la cueillette réelle de l'unique mûre. La récompense reste `+1` à cette
cueillette, `-1` à une mort sans cueillette et `0` sinon. Aucun bonus de distance, macro-action
ou information supplémentaire n'est autorisé.

## Observation, apprentissage et bras

L'observation est strictement celle de T0 v1 : `resource_sector`, `resource_visible` et
`previous_action`. Les coordonnées, seed, distance exacte, solution scriptée et état des cartes
précédentes sont interdits.

Le candidat reste une table Q initialisée à zéro (`alpha=0,20`, `gamma=0,90`, epsilon `0,20` à
l'entraînement puis `0` à l'évaluation). Les bras restent `scripted`, `initial_frozen`,
`random_valid`, `trained` et `reset_each_episode`, avec les mêmes checkpoints `0`, `10`, `50`,
`200` et `1 000`, les mêmes règles de persistance et d'évaluation figée que T0 v1.

## Seeds distinctes et verrouillées

| Usage | Seeds |
| --- | --- |
| Cartes d'entraînement T0 v3 | `330000001..330000016` |
| Cartes de validation T0 v3 | `330000101..330000132` |
| Cartes de test final commun T0 v3 | `330000201..330000264` |
| Initialisations développement | `330001001`, `330001002`, `330001003` |
| Initialisations confirmation | `330001101`, `330001102`, `330001103`, `330001104`, `330001105` |
| RNG du bras aléatoire | `330002001`, `330002002`, `330002003`, `330002101`, `330002102` |

Ces réserves sont disjointes des seeds T0 v1/v2, des seeds de calibration T0 v2 et des réserves
T1. Elles ne peuvent plus être modifiées, complétées ou réordonnées après le premier entraînement
T0 v3. Toute modification ultérieure exige une version, des seeds et un gate nouveaux.

## Analyse et gate T0 v3

Chaque checkpoint est évalué, sans mise à jour, sur les 32 cartes de validation pour chacune des
trois initialisations de développement. Le checkpoint retenu maximise le taux de réussite ; une
égalité choisit le checkpoint le plus précoce. Les 64 cartes de test final restent fermées.

Le gate est atteint seulement si, sur les 96 évaluations de validation :

1. `scripted` réussit 96/96 ;
2. `trained` réussit au moins 0,90 ;
3. son gain de réussite atteint au moins 0,30 contre `initial_frozen` et `random_valid` ;
4. chaque lignée `trained` gagne strictement contre ces deux contrôles ;
5. un checkpoint rechargé reproduit exactement actions et résultats ;
6. `reset_each_episode` ne satisfait pas simultanément les critères 2 à 4.

Les comparaisons sont appariées par `(initialization_seed, card_seed)`. Un lot incomplet, un
doublon, une seed hors réserve ou une empreinte différente est refusé sans imputation. Un échec
reste « critère non atteint » ou « indéterminé » ; il ne permet pas de modifier le contrat après
lecture des résultats.

## Prérequis avant mesure

Les 12 tests T0 v1 restent requis. En complément, l'implémentation et le validateur T0 v3 doivent
refuser l'ancien identifiant, l'ancienne empreinte et toute seed T0 v1/v2. Avant campagne, un
probe mesure débit, temps de reset et mémoire ; plus de 2 GiB ou un épisode complet de plus de
60 secondes réelles bloque le lancement pour diagnostic technique.

T1 demeure gelé jusqu'à un verdict complet de T0 v3.
