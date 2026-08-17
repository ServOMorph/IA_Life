# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Terrain/relief/cuvettes de spawn, faim/vieillissement/mort et vitesse de simulation
validés manuellement en jeu. Bug de luminosité (scène de nuit) corrigé (ciel/lumière/
exposition), vérifié par capture d'écran, en attente de confirmation utilisateur en jeu.
Mode dev en construction (`roadmap_mode-dev.md`, Phases 1-2 faites : `run_dev.py`,
raccourcis clavier, UX "MODE DEV") pour tester cueillette/mémoire/collision/4-personnages
simultanés, encore bloqués en observation directe. Bug connu : personnages enfoncés
visuellement dans le sol malgré un suivi correct de la hauteur du terrain.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-16 : Initialisation du protocole vibecoding.
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
