# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Mode dev : Phases 1-3 de `roadmap_mode-dev.md` faites, Phase 4 en cours (2e cycle traité —
contrôle clavier du personnage de test confirmé, items 1-4 + rig Phase 5 validés, items 5, 6,
8-12 restent à valider). Personnage riggé (Blender, `assets/models/character.glb`) intégré et
validé sur le personnage de test uniquement (les 4 personnages normaux restent en box meshes).
Bug connu : personnages enfoncés visuellement dans le sol (Phase 4 terrain, non résolu).

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-16 : Scaffold Godot (map, 4 persos, caméra libre, run.py) + map x4 (160x160).
- 2026-08-16 : Menu bas + panneaux persos par coin + focus caméra au clic.
- 2026-08-17 : Vitesse de simulation globale, faim/vieillissement/mort, reset complet.
- 2026-08-17 : Cueillette de mûres (ronces), consommation auto, modale "Données du jeu".
- 2026-08-17 : Mode headless + skills `analyse-partie`/`experimentation-headless`.
- 2026-08-17 : Mémoire spatiale des ronciers par personnage + collision physique des ronces.
- 2026-08-17 : Correctif bug terrain invisible (culling) + relief escarpé + cuvettes de
  spawn + capture d'écran automatisée (`run_screenshot.py`) + skill `synthese-projet`.
- 2026-08-17 : Validation manuelle terrain/relief/faim-mort + correctif luminosité (scène
  de jour) ; mode dev (`roadmap_mode-dev.md`) en cours de construction (Phases 1-2 faites).
- 2026-08-18 : Checklist en jeu (Phase 3 mode dev) + pivot vers un personnage de test
  contrôlable manuellement (remplace F1-F4 seul), voir `_docs/decisions/2026-08-18_*.md`.
- 2026-08-18 : Personnage riggé (Phase 5 graphisme, Blender custom généré par script)
  branché uniquement sur le personnage de test, validé — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
