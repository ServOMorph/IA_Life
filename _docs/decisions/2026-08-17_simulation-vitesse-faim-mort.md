# Vitesse de simulation globale, faim/vieillissement/mort, reset complet

**Date :** 2026-08-17
**Statut :** proposé

## Décision
- Un slider "Vitesse jeu" (0.1x à 5x) dans le menu bas contrôle un facteur global
  (`GameSpeed.time_scale`) câblé sur tout ce qui dépend du temps chez les personnages
  (mouvement, gravité, déplétion de la faim), plutôt que d'utiliser `Engine.time_scale`.
- Chaque personnage a une barre de faim/PV (100 -> 0) qui diminue avec le temps. Un
  facteur de vieillissement réglable (`aging_factor`, slider par personnage) multiplie
  cette déplétion. À 0, le personnage meurt : il se couche au sol et son panneau affiche
  "DEAD" à la place de ses stats/sliders.
- Un bouton "Relancer" dans le menu bas recharge la scène (`reload_current_scene`) et
  remet `GameSpeed.time_scale` à 1.0 pour un reset complet.

## Implémentation
- `scripts/game_speed.gd` (nouveau, autoload `GameSpeed`) : `time_scale`.
- `scripts/character.gd` : `hunger`, `hunger_depletion_rate`, `aging_factor`, `is_dead`,
  `_die()` ; tous les calculs temporels multipliés par `GameSpeed.time_scale`.
- `scripts/ui_manager.gd` : slider vitesse jeu, barre de faim (rouge, fine, 4px), sliders
  vitesse/zone/vieillissement par personnage, bascule d'affichage "DEAD", bouton
  "Relancer".
- `project.godot` : déclaration de l'autoload `GameSpeed`.

## Commentaire
(à compléter lors de la validation/invalidation)
