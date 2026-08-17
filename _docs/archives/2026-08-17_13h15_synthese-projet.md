# Synthèse du projet — IA_Life

Date : 2026-08-17 13h15

## Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

But global : faire évoluer des IA dotées d'un corps dans un jeu vidéo, relever et
analyser leurs comportements, évaluer l'impact des modifications du jeu sur ces
comportements (ex. ajout de nourriture + système de vie).

## Stack
Godot 4.5 (GDScript), scène construite entièrement par code. LLM externe à définir
(aucune IA n'est encore branchée : la cueillette/consommation de mûres est simulée par
seuils automatiques en attendant).

## Structure du projet
- `project.godot`, `scenes/Main.tscn` : projet Godot.
- `scripts/main.gd` : construction de la scène (terrain procédural avec relief et
  cuvettes de spawn, murs, décor, caméra, personnages, ronces, UI).
- `scripts/character.gd` : comportement des personnages (déplacement, collisions, faim,
  vieillissement, mort, cueillette/consommation de mûres, mémoire spatiale des
  ronciers, orientation et animation procédurale).
- `scripts/ronce.gd` : roncier (détection Area3D + collision physique + cueillette).
- `scripts/triplanar.gdshader` : shader triplanar pour les matériaux PBR (sol/murs).
- `scripts/free_camera.gd` : caméra libre (ZQSD/E/C, souris) + cycle 3 clics par
  personnage (3e personne / 1re personne contrainte / retour).
- `scripts/ui_manager.gd` : menu bas d'écran, panneaux persos permanents, modale
  "Données du jeu", vitesse de simulation, reset.
- `scripts/game_speed.gd` : autoload `GameSpeed`, facteur de vitesse global (x1 à x80).
- `scripts/game_config.gd` : autoload `GameConfig`, réglages du jeu configurables
  (seuils faim, capacité de mûres, nombre de ronces, etc.).
- `scripts/game_logger.gd` : autoload `GameLogger`, archive chaque partie dans `logs/`.
- `run.py` : lance le jeu (fenêtré, pas l'éditeur).
- `run_headless.py` : lance une partie sans rendu avec overrides JSON, pour tests
  automatisés (le vrai `--headless` Godot ne fait aucun rendu GPU).
- `run_screenshot.py` : lance une partie en fenêtre réelle, capture un screenshot PNG
  après un délai puis quitte — permet une vérification visuelle automatisée.
- `.claude/skills/analyse-partie/`, `.claude/skills/experimentation-headless/` : skills
  d'analyse de logs et de campagnes de tests headless.
- `_docs/decisions/` : archive des décisions d'évolution du projet (statut
  proposé/validé/invalidé).
- `DESIGN/` : zone dédiée à la conception graphique (pistes et roadmap).

## Mécaniques de simulation en place
- 4 personnages (Rouge, Bleu, Vert, Jaune) répartis aux 4 coins d'une map 160x160.
- Faim décroissante dans le temps, indexée sur la vitesse de jeu ; mort si faim à 0.
- Ronces à mûres disséminées à parts égales par quadrant ; cueillette et consommation
  automatiques par seuils configurables (LLM non encore branché).
- Mémoire spatiale des ronciers par personnage (capacité configurable, renforcement/
  oubli au fil du temps), orientant la marche vers un roncier connu plutôt qu'aléatoire.
- Reset complet de la partie ("Relancer").

## Rendu graphique
Roadmap dédiée : `DESIGN/roadmap_graphisme.md`.
- Phase 1 (lumière/post-traitement, ciel procédural, ACES) : validée.
- Phase 2 (textures PBR triplanar sol/murs, ronces en buisson) : implémentée.
- Phase 3 (orientation + animation procédurale des personnages) : implémentée.
- Phase 4 (relief procédural par bruit simplex, décor rochers/arbres, cuvettes de
  spawn) : implémentée ; un bug de culling de mesh (winding inversé, terrain invisible)
  a été identifié et corrigé (`render_mode cull_disabled` sur le shader triplanar).
- Phase 5 (personnages riggés, animation squelettique) et 6 (roadmap suivante) : à
  venir.
- Aucune phase graphique n'est encore validée par test manuel en jeu.

## Outillage de vérification
Ajout récent de `run_screenshot.py` : lance Godot en fenêtre réelle (pas headless),
capture le viewport en PNG après un délai, permet une vérification visuelle directe
des rendus sans intervention manuelle systématique.

## Points ouverts
- Aucune mécanique de jeu, ni aucune phase graphique, validée par test manuel complet
  en jeu à ce jour (file d'attente : `tests_manuels.md`).
- Bug connu non résolu : clignotement occasionnel de la texture d'herbe (aliasing
  spéculaire probable).
- LLM pilotant les personnages : non branché, à définir.
- Communication inter-IA loguée : non implémentée (prévue dans l'objectif initial).
