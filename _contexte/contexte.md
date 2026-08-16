# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Scaffold Godot fonctionnel : map 160x160, 4 personnages lowpoly en déplacement aléatoire
avec rebond, caméra libre ZQSD, menu bas avec panneaux de stats/édition par personnage,
vitesse de simulation globale, système de faim/vieillissement/mort, bouton reset. Lancement
via `python run.py`. Aucune mécanique encore validée par test utilisateur en jeu.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-16 : Initialisation du protocole vibecoding.
- 2026-08-16 : Scaffold Godot (map, 4 persos, caméra libre, run.py) + map x4 (160x160).
- 2026-08-16 : Menu bas + panneaux persos par coin + focus caméra au clic.
- 2026-08-17 : Vitesse de simulation globale, faim/vieillissement/mort, reset complet.
