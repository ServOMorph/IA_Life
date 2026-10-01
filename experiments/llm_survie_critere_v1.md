# Critère de succès — survie pilotée par LLM (v1, Phase 5)

Statut : proposé par l'assistant, gelé avant toute mesure de Phase 5. Non validé par l'utilisateur :
la roadmap demandait de le définir avec lui ; il doit être confirmé ou remplacé avant toute
interprétation des résultats.

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
