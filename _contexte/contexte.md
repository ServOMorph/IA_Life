# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Mode dev clôturé (roadmap : `_docs/archives/2026-08-23_roadmap_mode-dev.md`) : tests 6, 8,
9, 10 et 11 automatisés avec `tools/run_manual_checks.py`, rendu ronces/mûres validé.
Le personnage de test peut ramasser une mûre proche avec E ; l'enfoncement visuel est résolu.
Personnage riggé validé uniquement sur le personnage de test ; extension aux quatre personnages
normaux encore à décider.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-16 : Menu bas + panneaux persos par coin + focus caméra au clic.
- 2026-08-17 : Vitesse de simulation globale, faim/vieillissement/mort, reset complet.
- 2026-08-17 : Cueillette de mûres (ronces), consommation auto, modale "Données du jeu".
- 2026-08-17 : Mode headless + skills `analyse-partie`/`experimentation-headless`.
- 2026-08-17 : Mémoire spatiale des ronciers par personnage + collision physique des ronces.
- 2026-08-17 : Correctif bug terrain invisible (culling) + relief escarpé + cuvettes de
  spawn + capture d'écran automatisée (`run_screenshot.py`) + skill `synthese-projet`.
- 2026-08-17 : Validation manuelle terrain/relief/faim-mort + correctif luminosité (scène
  de jour) ; mode dev (roadmap depuis archivée dans
  `_docs/archives/2026-08-23_roadmap_mode-dev.md`) en cours de construction (Phases 1-2 faites).
- 2026-08-18 : Checklist en jeu (Phase 3 mode dev) + pivot vers un personnage de test
  contrôlable manuellement (remplace F1-F4 seul), voir `_docs/decisions/2026-08-18_*.md`.
- 2026-08-18 : Personnage riggé (Phase 5 graphisme, Blender custom généré par script)
  branché uniquement sur le personnage de test, validé — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- 2026-08-22 : Refonte visuelle des ronces (buisson vert fixe + mûres noires visibles,
  retrait à la cueillette) ; test manuel 5 validé — voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
