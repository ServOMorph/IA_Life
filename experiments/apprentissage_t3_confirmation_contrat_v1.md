# Contrat de confirmation T3 v3 — lot final indépendant (Phase 5)

Rédigé le 2026-09-30, avant toute exécution sur les cartes finales. Ce document est le gel du
candidat et du plan d'analyse. Toute modification après le commit de gel est une déviation à
consigner, et un résultat obtenu après déviation ne vaut plus confirmation.

## Question

La procédure d'apprentissage T3 v3 (table Q persistante, 200 épisodes, concurrence de trois agents
fixes) améliore-t-elle la survie alimentaire de Rouge sur des cartes jamais utilisées, avec des
entraînements indépendants de ceux du développement ?

## Candidat gelé

- Contrat monde, observation, actions, récompense, hyperparamètres et empreinte : ceux de
  `apprentissage_t3_contrat_v3.md`, sans aucun changement (empreinte `t3_world_v3|...`).
- Schéma de checkpoint : `t3_q_table_v3`.
- Checkpoint évalué : **200 épisodes, fixé d'avance**. Aucun choix de checkpoint sur le lot final ;
  seul ce checkpoint est évalué pour `trained` et `reset_each_episode`.
- Justification du 200 : sur validation, les trois lignées de développement ont toutes été
  retenues à 200 (`experiments/t3_v3_analysis.json`). C'est un choix fait sur validation, pas sur
  le lot final.
- Cartes d'entraînement : `410000001..410000032`, ordre `(épisode × 5 + seed_initialisation) mod 32`.
- Les entraînements de développement (`410001001..003`) ne sont pas réutilisés : les cinq
  entraînements de confirmation repartent d'une table neuve.

## Graines de confirmation

| Usage | Seeds |
| --- | --- |
| Cartes de test final (64) | `410000201..410000264` |
| Initialisations de confirmation (5) | `410001101..410001105` |
| RNG du bras aléatoire (5) | `410002101..410002105`, associé dans l'ordre à l'initialisation |
| Bootstrap d'analyse | `410003101` |

Amendement au contrat T3 v3 : celui-ci ne réservait que `410002101..102` pour le RNG aléatoire,
insuffisant pour cinq initialisations. La plage est étendue à `410002101..105`, et le bootstrap de
confirmation utilise `410003101` (`410003001` a servi au développement).

Vérifié par recherche dans le dépôt versionné et dans les résultats `.jsonl` : aucune de ces
graines n'apparaît hors du contrat T3 v3 et de la décision T3 v3 (mentions de réservation
uniquement), et aucun résultat existant ne porte `card_seed 4100002xx`.

## Bras

| Bras | Rôle | Évaluations |
| --- | --- | --- |
| `trained` (200) | Résultat après expérience | 5 × 64 |
| `initial_frozen` | Même table initiale, figée | 5 × 64 |
| `random_valid` | Aléatoire sur les 8 actions | 5 × 64 |
| `reset_each_episode` (200) | Ablation de la persistance | 5 × 64 |
| `scripted_food` | Référence de solvabilité | 5 × 64 |

Total attendu : 1 600 résultats. Les lignes `scripted_food` sont répétées par initialisation pour
conserver la même structure d'identifiants ; elles ne dépendent pas de l'entraînement.
Les quatre personnages, les concurrents et la physique sont identiques dans tous les bras.

## Analyse (fixée)

Unité appariée : `(initialisation, carte)`. Estimateur : différence moyenne de survie entre
`trained` et chaque référence (`initial_frozen`, `random_valid`).

Intervalle : bootstrap hiérarchique, 20 000 rééchantillonnages — tirage avec remise de 5
initialisations, puis de 64 cartes par initialisation tirée — seed `410003101`. Correction de
multiplicité pour deux contrastes : intervalle bilatéral à 97,5 % (percentiles 1,25 % et 98,75 %).

Avertissement de méthode : avec seulement 5 initialisations, le bootstrap sur ce niveau est
approximatif. Pour cette raison, le gate exige aussi que chaque lignée ait un gain strictement
positif, et le rapport publie le gain par lignée.

### Critères de gate (tous requis)

1. `scripted_food` survit à au moins 0,90.
2. `trained` survit à au moins 0,60.
3. Gain de survie de `trained` d'au moins 0,10 contre `initial_frozen` et contre `random_valid`.
4. Borne inférieure de l'intervalle corrigé strictement positive pour ces deux contrastes.
5. Gain strictement positif dans chacune des 5 lignées, contre chaque référence.
6. Non-régression alimentaire : part d'épisodes avec repas de `trained` + 0,05 au moins égale à
   celle de chaque référence.
7. Ablation : `reset_each_episode` ne satisfait pas les critères 2 à 5 (cœur du gate).
8. Rechargement : chaque checkpoint à 200 se recharge avec le même checksum, l'évaluation ne
   modifie jamais la table, et le replay reproduit les résultats et checksums.

Verdicts : tous les critères satisfaits = « critère atteint » ; un critère de niveau (2, 3) ou
d'incertitude (4) non satisfait = « critère non atteint » ou « indéterminé » selon que
l'intervalle est simplement sous le seuil ou trop large pour trancher ; ne jamais conclure
« impossible à apprendre ». Un lot incomplet, un doublon ou une empreinte différente invalide le
lot : il ne passe pas.

### Sensibilité de puissance

Le gain observé en validation (0,583 contre initial, 0,667 contre aléatoire, intervalles corrigés
`[0,458 ; 0,698]` et `[0,542 ; 0,781]` avec 3 × 32) est très supérieur au seuil de 0,10. Passer à
5 × 64 réduit l'incertitude. Ce n'est pas un calcul de puissance formel, seulement un contrôle
d'ordre de grandeur : le risque principal n'est pas la puissance mais un écart entre validation et
cartes fraîches, que ce lot mesure justement.

## Livraison dans le jeu — modèle désigné

Le modèle livré est **la lignée `410001101` au checkpoint 200**, désignée maintenant par une règle
indépendante du score final. Elle n'est pas choisie parmi les cinq après observation. Si cette
lignée échoue au critère 5, le gate échoue ; la désignation n'est pas remplacée.

## Procédure d'exécution

1. Le présent contrat et le code de campagne de confirmation sont commités **avant** tout lancement
   sur les cartes finales. Le commit de gel est enregistré dans le rapport.
2. Un essai à blanc de l'outillage tourne sur des cartes de validation (jamais sur
   `410000201..264`) pour vérifier le format, la validation structurelle et l'analyse.
3. Le lot final est lancé une seule fois. Une reprise (`--resume`) ne peut que compléter des
   fichiers manquants avec le code et la configuration inchangés.
4. L'analyse est exécutée telle qu'écrite. Aucun réglage, aucun changement de métrique, aucun
   choix de candidat après ouverture.
5. En cas d'échec : nouvelle version du contrat, nouvelles réserves, aucune réutilisation du lot
   final pour choisir un correctif.

## Contrôles techniques de livraison (sur cartes non finales)

- Rechargement du modèle par le décideur, rejet d'un schéma ou d'une empreinte incompatibles.
- Mode figé : aucune mise à jour de la table, checksum constant.
- Perte ou absence du modèle : repli explicite vers l'automate, compté et journalisé ; une survie
  obtenue par le repli ne valide pas le modèle.
- Contrôle manuel prioritaire sur le décideur.
- Équivalence d'actions entre le chemin évalué (campagne) et le chemin livré (décideur en jeu)
  sur des cartes d'entraînement ou de validation.
- Télémétrie : modèle, schéma, empreinte et checksum dans les logs.
- Démonstration fenêtrée sur le bureau virtuel IA_Life, ajoutée à `tests_manuels.md`.
