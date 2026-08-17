# IA_Life

## Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack
Godot 4.5 (GDScript), scène construite entièrement par code. LLM externe à définir.

## Structure
- `project.godot`, `scenes/Main.tscn` : projet Godot.
- `scripts/main.gd` : construction de la scène (terrain procédural avec relief, murs,
  décor, caméra, personnages, ronces, UI).
- `scripts/character.gd` : comportement des personnages (déplacement, collisions, faim,
  vieillissement, mort, cueillette/consommation de mûres, mémoire des ronciers, orientation
  et animation procédurale).
- `scripts/ronce.gd` : roncier (détection + cueillette).
- `scripts/triplanar.gdshader` : shader triplanar pour les matériaux PBR (sol/murs).
- `scripts/free_camera.gd` : caméra libre (ZQSD/E/C, souris) + cycle 3 clics par personnage
  (3e personne / 1re personne contrainte / retour).
- `scripts/ui_manager.gd` : menu bas d'écran, panneaux persos, modale "Données du jeu",
  vitesse de simulation, reset.
- `scripts/game_speed.gd` : autoload `GameSpeed`, facteur de vitesse global.
- `scripts/game_config.gd` : autoload `GameConfig`, réglages du jeu configurables.
- `scripts/game_logger.gd` : autoload `GameLogger`, archive chaque partie dans `logs/`.
- `run.py` : lance le jeu (pas l'éditeur).
- `run_headless.py` : lance une partie sans fenêtre avec overrides JSON, pour tests
  automatisés.
- `.claude/skills/analyse-partie/`, `.claude/skills/experimentation-headless/` : skills
  d'analyse de logs et de campagnes de tests headless.
- `_docs/decisions/` : archive des décisions d'évolution du projet.
- `DESIGN/` : zone dédiée à la conception graphique (pistes et roadmap).

## État actuel
Roadmap graphisme (`DESIGN/roadmap_graphisme.md`) : Phase 1 (lumière/post-traitement)
validée. Phases 2 (matériaux PBR, ronces en buisson), 3 (animation procédurale des
personnages) et 4 (terrain à relief procédural + décor) implémentées, sans erreur en
headless, en attente de validation manuelle en jeu (`tests_manuels.md`). Cycle caméra 3
clics par personnage (3e personne / 1re personne contrainte / retour) ajouté. Bug connu non
résolu : clignotement occasionnel de la texture d'herbe. Mécaniques de simulation (faim,
mémoire des ronciers, cueillette) inchangées depuis la session précédente.
