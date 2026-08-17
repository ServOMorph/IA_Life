# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Scaffold Godot fonctionnel : map 160x160, 4 personnages lowpoly, caméra libre/suivi+zoom,
menu bas avec panneaux perso permanents, cueillette/consommation de mûres (ronces avec
collision physique), mémoire spatiale des ronciers par personnage, vitesse de simulation
x50, logging complet de session, mode headless + skills d'analyse/expérimentation.
Aucune mécanique encore validée par test utilisateur manuel en jeu (`python run.py`).

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-16 : Initialisation du protocole vibecoding.
- 2026-08-16 : Scaffold Godot (map, 4 persos, caméra libre, run.py) + map x4 (160x160).
- 2026-08-16 : Menu bas + panneaux persos par coin + focus caméra au clic.
- 2026-08-17 : Vitesse de simulation globale, faim/vieillissement/mort, reset complet.
- 2026-08-17 : Cueillette de mûres (ronces), consommation auto, modale "Données du jeu".
- 2026-08-17 : Mode headless + skills `analyse-partie`/`experimentation-headless`.
- 2026-08-17 : Mémoire spatiale des ronciers par personnage + collision physique des ronces.
