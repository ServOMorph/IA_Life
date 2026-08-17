# IA_Life

## Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack
Godot 4.5 (GDScript), scène construite entièrement par code. LLM externe à définir.

## Structure
- `project.godot`, `scenes/Main.tscn` : projet Godot.
- `scripts/main.gd` : construction de la scène (map, murs, caméra, personnages, ronces, UI).
- `scripts/character.gd` : comportement des personnages (déplacement, collisions, faim,
  vieillissement, mort, cueillette/consommation de mûres, mémoire des ronciers).
- `scripts/ronce.gd` : roncier (détection + cueillette).
- `scripts/free_camera.gd` : caméra libre (ZQSD/E/C, souris), suivi + zoom molette.
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
Scaffold fonctionnel : map 160x160, 4 personnages lowpoly, caméra libre avec suivi/zoom,
menu bas avec panneaux de stats/édition par personnage toujours visibles, vitesse de
simulation jusqu'à x50, système de faim/vieillissement/mort, cueillette/consommation de
mûres (ronces avec collision physique), mémoire spatiale des ronciers par personnage,
logging complet de session, mode headless + skills d'analyse/expérimentation. Aucune
mécanique encore validée par test utilisateur manuel en jeu. Une roadmap graphisme est en
cours (`DESIGN/roadmap_graphisme.md`) : lumière/post-traitement, matériaux PBR, animation
des personnages, terrain/décor, personnages riggés.
