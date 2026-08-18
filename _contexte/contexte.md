# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Mode dev : Phases 1-3 de `roadmap_mode-dev.md` faites (raccourcis clavier, checklist en jeu
sauvegardant `logs/dev_session_*.json`), Phase 4 en cours (1er cycle traité). Pivot : un 5ème
personnage de test contrôlable manuellement (F5, ZQSD + souris, immortel) remplace F1-F4 seul
pour observer cueillette/collision en direct — contrôle clavier pas encore confirmé
fonctionnel par l'utilisateur. Bugs connus : personnages enfoncés visuellement dans le sol ;
correctif luminosité de la veille toujours pas confirmé en jeu par l'utilisateur.

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
- 2026-08-18 : Checklist en jeu (Phase 3 mode dev) + pivot vers un personnage de test
  contrôlable manuellement (remplace F1-F4 seul), voir `_docs/decisions/2026-08-18_*.md`.
