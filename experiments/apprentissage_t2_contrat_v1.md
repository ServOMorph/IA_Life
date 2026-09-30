# Contrat T2 v1 — retrouver une ressource après perte de perception

Gelé le 2026-09-29 avant toute exécution sur validation T2. T1 v5 conserve son verdict et ses
réserves. Les 64 cartes finales T0/T1 restent fermées.

## Hypothèse

Quand la ressource n'est plus visible au moment du choix, l'observation courante ne suffit pas à
choisir un cap. Une mémoire explicite de la dernière perception doit permettre d'apprendre ce
choix, tandis qu'une politique ayant la même table et le même exécutant mais privée de cet
historique doit rester proche du hasard.

T2 mesure l'usage d'une information historique, pas la navigation. Comme dans T1 v5, la politique
choisit une direction une fois et l'exécutant moteur maintient ce cap jusqu'à la consommation ou
l'horizon. Cette exécution est une compétence programmée ; l'apprentissage porte sur le rappel et
le choix du cap.

## Scénario et observations

Une arène vide contient un personnage et une ronce avec une mûre réelle. Les 32 cartes de chaque
réserve équilibrent exactement les huit secteurs ; la distance varie entre `3`, `6` et `9 m`.
Chaque épisode comporte deux phases :

1. `perception` : le personnage est orienté vers la ronce, qui est dans son cône local ; le secteur
   relatif et la distance sont observés puis éventuellement stockés ; aucune action ni récompense
   n'est possible ;
2. `décision` : le personnage est tourné de 180 degrés, la ronce est hors du cône et l'observation
   courante ne contient aucune cible. La politique choisit alors parmi huit directions monde.

L'observation ne contient ni seed, ni coordonnées absolues, ni secteur caché. Le bras mémoire
reçoit `last_seen_sector` issu de la phase de perception. Le bras observation seule reçoit
exactement la même observation courante, avec `last_seen_sector = -1`. La mémoire est remise à
zéro à chaque épisode. Un diagnostic à information complète peut lire le secteur réel, mais ne
participe ni à l'entraînement ni aux comparaisons équitables.

Tous les bras utilisent 15 ticks physiques par primitive, un horizon maximal de 24 primitives,
`game_speed = 1` et le même exécutant de maintien du cap. La réussite exige une cueillette et une
consommation réelles dans Godot.

## Bras et apprentissage

- `scripted_memory` : choisit le dernier secteur perçu ; contrôle de solvabilité ;
- `initial_memory_frozen` : table mémoire neutre et figée ;
- `random_valid` : une direction uniforme, choisie une fois ;
- `trained_memory` : table persistante indexée par le dernier secteur perçu ;
- `trained_observation_only` : même table, budget et exploration, mais état courant unique sans
  historique ;
- `reset_each_episode` : table mémoire remise à zéro avant chaque épisode.

L'exploration choisit l'action la moins essayée dans chaque état, avec ex aequo au plus petit
identifiant. Le compteur est incrémenté une fois après exécution. La valeur reçoit
`r_base + 0,50 × distance_progress` sur la première primitive, sans bootstrap. L'évaluation choisit
la meilleure valeur avec ex aequo au plus petit identifiant et ne modifie ni valeurs, ni compteurs,
ni RNG.

## Identifiant, schéma et réserves

```text
t2_memory_v1|target=1|distances=3,6,9|sectors=8|fov=90|turn=180|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|explore=min_count|execution=hold_first
```

Le checkpoint utilise le schéma `t2_q_table_v1` et conserve valeurs, compteurs, RNG, nombre
d'épisodes et empreinte de configuration.

| Usage | Seeds nouvelles |
| --- | --- |
| Cartes d'entraînement | `380000001..380000032` |
| Cartes de validation | `380000101..380000132` |
| Cartes de test final, fermées | `380000201..380000264` |
| Initialisations de développement | `380001001`, `380001002`, `380001003` |
| Initialisations de confirmation | `380001101..380001105` |
| RNG aléatoire | `380002001..380002003`, `380002101..380002102` |

Ces plages étaient absentes du projet au gel. La validation reste fermée jusqu'au passage des
tests et du probe sur cartes d'entraînement. Le test final reste fermé jusqu'au gate de validation.

## Budget, sélection et gate

Trois lignées, au plus 1 000 épisodes chacune, avec les checkpoints `0`, `10`, `50`, `200`,
`1 000`. Chaque lignée parcourt cycliquement les 32 cartes d'entraînement. Son checkpoint est
choisi par le plus grand nombre de consommations de validation, puis par le palier le plus précoce.
Le lot complet attendu contient 1 728 résultats.

Le gate est atteint seulement si :

1. `scripted_memory` réussit 96/96 ;
2. `trained_memory` réussit au moins 0,90 ;
3. son gain est au moins 0,30 contre `initial_memory_frozen`, `random_valid` et
   `trained_observation_only` ;
4. chaque lignée `trained_memory` a un gain strictement positif contre ces trois références ;
5. `trained_observation_only` ne dépasse pas 0,35 ;
6. la sauvegarde/recharge reproduit les décisions et résultats, et l'évaluation reste figée ;
7. `reset_each_episode` ne satisfait pas simultanément les critères 2 à 4 ;
8. les checkpoints T0 v4 et T1 v5 retenus passent leurs régressions existantes.

Avant toute validation, les tests sur cartes d'entraînement doivent couvrir : perception locale
présente avant rotation et absente après ; mémoire correcte puis remise à zéro ; absence de fuite
du secteur dans l'observation courante ; équilibre des secteurs ; même exécutant pour tous les
bras ; contact et consommation aux trois distances ; crédit unique ; évaluation figée ;
sauvegarde/recharge exacte ; rejet des schémas T1 ; probe sous les bornes T1 existantes.
