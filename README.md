# IA_Life

## Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack
Godot 4.5 (GDScript), scène construite entièrement par code. LLM externe à définir.

## Structure
- `project.godot`, `scenes/Main.tscn` : projet Godot.
- `scripts/main.gd` : construction de la scène (map, murs, caméra, personnages, UI).
- `scripts/character.gd` : comportement des personnages (déplacement, collisions, faim,
  vieillissement, mort).
- `scripts/free_camera.gd` : caméra libre (ZQSD/E/C, souris).
- `scripts/ui_manager.gd` : menu bas d'écran, panneaux persos, vitesse de simulation,
  reset.
- `scripts/game_speed.gd` : autoload `GameSpeed`, facteur de vitesse global.
- `run.py` : lance le jeu (pas l'éditeur).
- `_docs/decisions/` : archive des décisions d'évolution du projet.
- `DESIGN/` : zone dédiée à la conception graphique (pistes et roadmap).

## État actuel
Scaffold fonctionnel : map 160x160, 4 personnages lowpoly en déplacement aléatoire avec
rebond, caméra libre, menu bas avec panneaux de stats/édition par personnage, vitesse de
simulation globale, système de faim/vieillissement/mort, bouton reset. Aucune mécanique
encore validée par test utilisateur en jeu. Une roadmap graphisme est en cours
(`DESIGN/roadmap_graphisme.md`) : lumière/post-traitement, matériaux PBR, animation des
personnages, terrain/décor, personnages riggés.
