# Critère de succès — survie pilotée par LLM (v1, Phase 5)

Statut : proposé par l'assistant, gelé avant toute mesure de Phase 5. Validé par l'utilisateur le
2026-10-03 avec trois amendements (section « Amendements du 2026-10-03 »). Le texte d'origine
des critères est conservé ci-dessous ; les amendements prévalent.

## Amendements du 2026-10-03 (post-mesure, validés par l'utilisateur)

Posés après la mesure de la Phase 5 : ils sont donc posthoc et signalés comme tels. Ils ne changent
pas le verdict.

1. Comparateur principal : l'`automate` à cueillette libre (`pickup_hunger_threshold` = 100,
   « témoin »), seul apparié à `llm_survie` sur la règle de cueillette. L'`automate` de référence
   (seuil 90) reste rapporté. Les critères 2 et 3 s'évaluent contre le témoin.
2. Libellé du succès : « exécuteur viable d'une stratégie décrite dans le prompt », et non
   « raisonnement spatial autonome » ni « le LLM sait survivre ».
3. Portée de l'exploitation : un modèle (`gemma3:1b`), une version de prompt, 6 cartes, stock fini
   de mûres sans repousse. Le résultat ne sert pas à conclure sur l'évolution des comportements
   ni à généraliser à d'autres modèles ou prompts.

## Protocole (figé)

- Deux bras appariés sur les mêmes cartes : `automate` et `llm_survie` (config
  `experiments/llm_survie_v1.json`, seule différence : `decider_type` des quatre agents).
- 6 seeds de carte : 26093001 à 26093006, jamais utilisées auparavant.
- `game_speed = 1.0`, `max_simulation_seconds = 1200`, `quit_on_all_dead` actif, danger désactivé,
  vision 25 m, mémoire illimitée sans oubli pour les deux bras.
- Bras `llm_survie` : `--jobs 1`, aucun autre processus lourd concurrent. Bras `automate` :
  déterministe et indépendant du temps réel, peut tourner en parallèle.
- Unité d'analyse : la carte. Indicateur par carte : durée de vie moyenne des quatre agents, en
  secondes simulées, bornée à 1200 (les survivants sont censurés à 1200 et comptés).

## Critères

1. Robustesse (nécessaire) : les 6 runs `llm_survie` se terminent sans crash ni blocage, et les
   replis représentent au plus 5 % des tours.
2. Performance : moyenne sur les 6 cartes de la durée de vie `llm_survie` supérieure ou égale à
   80 % de celle de l'`automate`.
3. Lecture forte (informative) : `llm_survie` supérieur ou égal à l'`automate` sur au moins 4
   cartes sur 6.

Succès = critères 1 et 2 ; le critère 3 qualifie la portée du succès.

## Indicateurs rapportés (non décisionnels)

Mûres ramassées et mangées, faim perdue en attente, latence moyenne, distribution des actions,
refus par code, replis, matériel (processeur, mémoire, version Ollama). L'écart d'équité
(l'automate décide instantanément) est documenté : la faim perdue en attente est rapportée à côté
de la survie.
