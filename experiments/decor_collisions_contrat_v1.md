# Contrat — décors avec collisions (v1, Phase 0)

Statut : VALIDÉ par l'utilisateur le 2026-10-03, sans modification, les quatre points de la section
finale inclus. Valeurs proposées par l'assistant, non mesurées ; elles sont gelées.

## Constats utilisés (code au 2026-10-03)

- Carte 160 x 160 m, mur de 1 m ; `_build_decor()` tire dans `[-76, 76]` (marge 3 m des murs).
- 8 rochers (boîte de 1,0 x 0,7 x 0,9 m x échelle 0,5 à 1,1, collision active) et 108 arbres
  (tronc : cylindre de rayon `0,2 x échelle`, échelle 0,85 à 1,3, soit 0,17 à 0,26 m).
- Densité des arbres : environ 1 pour 214 m².
- Ronciers : 24 par défaut, 6 par quadrant, tirés dans `[0, 78]` par quadrant (RNG global seedé).
- Points de départ : `(±40, ±40)`.
- Portée de vision de référence des campagnes : 25 m.

## Variable

- `decor_collisions` : booléen, défaut `false`, portée globale, catégorie environnement, non
  modifiable en direct (`live_editable: false`), enregistrée dans `scripts/variable_registry.gd`.
- Pilote les troncs d'arbres et les futurs décors ; les rochers restent toujours bloquants.

## Rayons d'exclusion (centre à centre, en mètres)

| Paire | Distance minimale proposée |
|---|---|
| décor — roncier | 3,0 |
| décor — point de départ | 5,0 |
| décor — autre décor | 1,5 |
| décor — mur | 3,0 (marge actuelle inchangée) |

- Un décor rejeté est retiré au sort jusqu'à 50 tentatives ; au-delà, il n'est pas placé et
  l'événement est journalisé (même principe que les zones dangereuses).
- L'exclusion s'applique aux rochers comme aux arbres (décision du 2026-10-03). Les références
  `automate` et `llm_survie` sont donc rompues.
- Contrainte à tenir en Phase 1 : les positions des ronciers ne doivent pas changer. Le décor doit
  être construit après les ronciers sans consommer le RNG global.

## Seuils du gate de Phase 3

- N = 3 s : durée maximale de blocage frontal contre un tronc en ciblage de roncier (même ordre que
  le blocage de `llm_survie` : 3 s sous 0,5 m).
- M = 12 cartes, seeds 26103001 à 26103012 (nouvelles : absence d'usage antérieur à contrôler avant
  la première exécution).

## Indicateurs journalisés

- Contacts obstacle (par agent, par type : tronc, rocher, mur).
- Contournements : nombre, durée, réussis ou échoués.
- Blocages : blocage frontal de plus de N s, avec la cible concernée.
- Durée de vie par agent (secondes simulées, bornée à 1200) et durée moyenne par carte.
- Pour `llm_survie` : cibles et directions retirées par `blocked_targets`, replis, refus.

## Critère de succès de la Phase 5 (proposé)

Protocole : 6 cartes (seeds 26103101 à 26103106), `game_speed = 1.0`, `max_simulation_seconds = 1200`,
même configuration que `experiments/llm_survie_v1.json`. Comparaison appariée, sur les mêmes cartes,
avec et sans `decor_collisions`. Unité d'analyse : la carte.

1. Automate (nécessaire) : durée de vie moyenne avec collisions supérieure ou égale à 90 % de celle
   sans collisions ; zéro blocage frontal de plus de N s ; zéro roncier inaccessible.
2. `llm_survie` (nécessaire si l'automate est viable) : durée de vie moyenne avec collisions
   supérieure ou égale à 80 % de celle sans collisions ; replis au plus 5 % des tours ; zéro blocage
   de cible à tort imputable à un tronc.
3. Décision : activation par défaut de `decor_collisions` seulement si les critères 1 et 2 sont
   atteints ; sinon l'option reste désactivée et l'écart est consigné.

Limites annoncées : 6 cartes, un modèle (`gemma3:1b`), stock fini de mûres sans repousse (durée de
vie plafonnée par la carte), pas de test statistique ; le résultat ne vaut pas généralisation.

## Points à trancher par l'utilisateur

1. Rayons d'exclusion (3,0 / 5,0 / 1,5 m) : acceptés ou à modifier.
2. N = 3 s et M = 12 cartes.
3. Seuils 90 % (automate) et 80 % (`llm_survie`) ; l'écart 90/80 est volontaire, la mesure LLM
   étant plus bruitée.
4. Rochers : exclusion de 3 m d'un roncier, au prix d'une rupture supplémentaire des références.
