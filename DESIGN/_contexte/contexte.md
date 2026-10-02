# Contexte — design

## Objectif (immuable sauf décision explicite)
Concevoir et faire évoluer le design du jeu IA_Life : mécaniques de
simulation, environnement, systèmes de caméra et d'UI, en cohérence avec
l'objectif d'étude comportementale des IA pilotées par LLM.

## Stack / contraintes techniques (stable, rarement modifié)
- Godot 4.5 (GDScript), scène construite entièrement par code (pas d'édition via l'éditeur de scène).
- Personnages lowpoly, pilotés par un LLM externe (déplacement, communication écrite entre eux, loguée). Animation prévue (marche/idle a minima) — décision du 2026-08-17.
- Mécaniques actuelles : faim, vieillissement, mort, vitesse de simulation globale (autoload `GameSpeed`), reset.
- Caméra libre (`free_camera.gd`, ZQSD/E/C + souris) ; cameras par personnage (1re/3e personne) et vue du dessus prévues au but du projet.
- UI : menu bas d'écran, panneaux stats/édition par personnage (`ui_manager.gd`).
- But global : faire évoluer 2+ IA dotées d'un corps dans un jeu vidéo, relever et analyser leur comportement, évaluer l'impact des modifications du jeu (ex. ajout d'arbres à fruits + système de nourriture).
- Architecture pensée pour évoluer fortement — ne pas figer le design prématurément.

## État actuel (réécrit intégralement à chaque /close)
Direction Observatoire choisie ; ancienne roadmap graphisme archivée, nouvelle progression en trois phases.
Palette, IBM Plex, repères et états UI intégrés ; contrôle visuel de la phase 1 encore en attente.
Décor Kenney CC0, 108 arbres à collisions désactivées, mûres ancrées au feuillage et relief multi-échelle intégrés.
Tests automatisés ciblés passés ; contrôles visuels et de déplacement de la phase 2 encore en attente.
La phase 3 (personnages et états 3D) n'est pas commencée ; rig de développement toujours réservé au personnage de test.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-17 : Initialisation du protocole vibecoding.
- 2026-08-17 : Levée de la contrainte "sans animation" — les personnages auront des animations (marche/idle a minima). Impacte piste D de `pistes_graphisme.md`.
- 2026-08-17 : Roadmap graphisme créée, trajectoire validée A → B+E → D1 → C → D2 → écriture de la roadmap suivante.
- 2026-08-17 : Relief procédural par code (Phase 4) plutôt que le plugin Terrain3D — cohérence avec l'approche "tout par code" du projet.
- 2026-08-17 : Cycle caméra 3 clics sur le nom (3e personne/1re personne contrainte/retour) ajouté, hors séquence formelle de la roadmap.
- 2026-08-18 : Rig Blender custom (`tools/blender/build_character.py`) intégré, limité au personnage de test.
- 2026-08-22 : Ronces refondues visuellement (buisson vert + mûres noires visibles).
- 2026-08-23 : Rig Blender confirmé réservé au personnage de développement (les 4 agents normaux gardent la géométrie boîte).
- 2026-10-02 : Direction visuelle Observatoire retenue ; UI bleu nuit/IBM Plex, repères géométriques et modèles Nature Kit de Kenney (CC0) pour le décor.
- 2026-10-02 : Densité de 108 arbres confirmée par l'utilisateur, collisions d'arbres désactivées à sa demande ; relief multi-échelle remplace les cuvettes symétriques et rompt la comparabilité des anciens parcours.
