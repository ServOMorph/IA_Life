# IA_Life

## Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack
Godot 4.5 (GDScript), scène construite entièrement par code. LLM local via Ollama
(`gemma3:1b` en référence pour les campagnes).

## Structure
- `project.godot`, `scenes/Main.tscn` : projet Godot.
- `scripts/main.gd` : construction de la scène (terrain procédural avec relief, murs,
  décor, caméra, personnages, ronces, UI).
- `scripts/character.gd` : comportement des personnages (déplacement, collisions, faim,
  vieillissement, mort, cueillette/consommation de mûres, mémoire des ronciers, orientation
  et animation procédurale). Mode `manual_control`/`immortal` pour le personnage de test
  (mode dev). Personnage de test uniquement : modèle riggé (`AnimationPlayer`, animations
  Idle/Walk/Death) à la place de l'animation procédurale.
- `tools/blender/build_character.py` : génère le personnage riggé (armature, skinning,
  animations) et l'exporte en `assets/models/character.glb`, via Blender en ligne de
  commande (`blender --background --python`).
- `scripts/ronce.gd` : roncier (détection + cueillette, mûres visuelles retirées une à
  une à chaque cueillette).
- `scripts/triplanar.gdshader` : shader triplanar pour les matériaux PBR (sol/murs).
- `scripts/free_camera.gd` : caméra libre (ZQSD/E/C, souris) + cycle 3 clics par personnage
  (3e personne / 1re personne contrainte / retour) + mode orbite 3e personne pilotable
  (personnage de test, mode dev).
- `scripts/ui_manager.gd` : menu bas d'écran, panneaux persos, modale "Données du jeu",
  vitesse de simulation, reset.
- `scripts/game_speed.gd` : autoload `GameSpeed`, facteur de vitesse global.
- `scripts/game_config.gd` : autoload `GameConfig`, réglages du jeu configurables.
- `scripts/game_logger.gd` : autoload `GameLogger`, archive chaque partie dans `logs/`.
- `run.py` : lance le jeu (pas l'éditeur).
- `run_headless.py` : lance une partie sans fenêtre avec overrides JSON, pour tests
  automatisés (aucun rendu GPU en mode `--headless`, inutilisable pour une capture
  d'écran).
- `run_screenshot.py` : lance une partie en fenêtre réelle, capture le viewport en PNG
  après un délai configurable, puis quitte — vérification visuelle automatisée.
- `run_dev.py` : lance le jeu en mode dev (`IA_LIFE_DEV_MODE=1`), avec raccourcis clavier
  de déclenchement contrôlé des mécaniques (roadmap terminée :
  `_docs/archives/2026-08-23_roadmap_mode-dev.md`).
- `.claude/skills/analyse-partie/`, `.claude/skills/experimentation-headless/`,
  `.claude/skills/synthese-projet/` : skills d'analyse de logs, de campagnes de tests
  headless, et de génération d'un état des lieux complet du projet.
- `_docs/decisions/` : archive des décisions d'évolution du projet.
- `_docs/*_synthese-projet.md` : dernier état des lieux complet généré (archives dans
  `_docs/archives/`).
- `DESIGN/` : zone dédiée à la conception graphique (pistes et roadmap).

## État actuel
Le prototype est un laboratoire reproductible : configurations versionnées et hashées,
logs JSONL, résumés par run, agrégation et campagnes headless. Les expériences utilisent
une durée simulée déterministe et distinguent configuration fixe et état initial dynamique.
Les Phases 1 à 8 du laboratoire sont closes : trois campagnes de référence (mémoire, rareté
des ressources, profils contrastés), un Inspecteur générique piloté par le registre, des
interactions sociales avancées (communication, coopération, agressivité), un décideur
interchangeable automate/LLM (Ollama local, repli automatique sur erreur), et une vision
générique (portée, angle, occlusion) qui remplace la découverte par contact seul et absorbe
la perception sociale par code partagé (`Character._perceive`). Aucune Phase 9 définie pour
l'instant.
