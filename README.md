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
Le prototype est un laboratoire headless reproductible avec configurations versionnées,
campagnes et résultats JSONL. L'apprentissage alimentaire a franchi la première preuve T0 v4 :
la politique entraînée réussit 96/96 validations, contre 12/96 avant entraînement et 57/96 pour
l'aléatoire. La recharge des checkpoints reproduit les décisions sur les huit secteurs T0.

La Phase 3 a validé un bridge TCP/JSONL local et deux adaptateurs Gymnasium, pour T0 et le monde
alimentaire. Le gate technique est atteint ; il ne valide pas l'apprentissage dans le monde complet.

La Phase 4 est terminée. T1 v5 atteint 96/96 consommations ; T2 v1 atteint 96/96 avec mémoire
contre 12/96 sans mémoire ; T3 v2 puis T3 v3 franchissent leurs gates sans puis avec trois
concurrents fixes. Les checkpoints retenus sont stables au replay et le chemin direct est équivalent
au bridge. La Phase 5 a exécuté un lot final indépendant (5 entraînements, 64 cartes nouvelles) : critère
non atteint, 7 critères sur 8. La politique entraînée survit à 201/320 contre 40/320 initial et
31/320 aléatoire, mais la solvabilité de référence est à 0,875 sous le seuil de 0,90. Les cartes
finales sont consommées ; une suite exige un contrat de confirmation v2. Un décideur
`politique_apprise` (table figée, repli compté) est livré en jeu à titre expérimental.
L'axe danger demeure en pause. Voir `roadmap_apprentissage_fonctionnel_proposition.md` et
`_docs/decisions/2026-09-30_t3-v3-confirmation-critere-non-atteint.md`.

L'axe apprentissage est en pause. La survie pilotée par LLM est livrée : les quatre personnages
autonomes (`gemma3:1b`) choisissent cibles et actions (ramasser, manger) avec mémoire des ronciers et
décision asynchrone sans pause. Sur 6 cartes à x1, vie moyenne 542 s contre 292 s pour l'automate,
sans repli ; critère non validé et prompt directif. Mode dev : F6 replie le panneau, F1-F4 suivent
un agent, marqueurs au-dessus des personnages ; lancement fenêtré maximisé. Roadmap
`roadmap_survie_llm.md` (Phases 0 à 5 faites) ; décision dans
`_docs/decisions/2026-09-30_survie-pilotee-par-llm.md`.
