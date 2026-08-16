# Signals — ia_life   (MAJ 2026-08-17)

## Actions ouvertes
- [P1|ouvert] Retester en jeu (`python run.py`) les mécaniques ajoutées cette session
  (menu bas, panneaux persos, vitesse de simulation, faim/vieillissement/mort, reset) et
  valider/invalider les décisions archivées.
  fait quand: l'utilisateur confirme le comportement observé pour chaque mécanique
  réf: `_docs/decisions/INDEX.md`, `scripts/main.gd`, `scripts/character.gd`, `scripts/ui_manager.gd`

## Dernière session (2026-08-17)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-17

## Décisions prises
- Scaffold Godot complet (map, 4 persos lowpoly, caméra libre ZQSD, run.py)
- Map agrandie x4 (160x160), 4 personnages/4 zones conservés
- Menu bas + panneaux persos par coin + focus caméra au clic
- Vitesse de simulation globale, faim/vieillissement/mort, reset complet

## Livrables produits ou modifiés
- project.godot, scenes/Main.tscn : créés
- scripts/main.gd, character.gd, free_camera.gd : créés/modifiés
- scripts/ui_manager.gd, scripts/game_speed.gd : créés
- run.py : créé
- _docs/decisions/ : 4 décisions archivées (statut proposé)
- .gitignore, README.md, CHANGELOG.md : créés

## Hypothèses validées / invalidées
- EN ATTENTE : aucune confirmation explicite reçue en session -> toutes les décisions
  restent au statut "proposé"

## Prochaine étape exacte
Retester l'ensemble via `python run.py` puis valider/invalider les décisions dans
`_docs/decisions/`.

## Question bloquante pour la session suivante
Aucune
