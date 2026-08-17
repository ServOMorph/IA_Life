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
Analyse du rendu graphique actuel réalisée (pistes_graphisme.md). Roadmap graphisme créée
(roadmap_graphisme.md, 6 phases) : Phase 1 (lumière/post-traitement) en cours, aucune
implémentation de code encore réalisée. Contrainte "sans animation" levée.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-17 : Initialisation du protocole vibecoding.
- 2026-08-17 : Levée de la contrainte "sans animation" — les personnages auront des animations (marche/idle a minima). Impacte piste D de `pistes_graphisme.md`.
- 2026-08-17 : Roadmap graphisme créée, trajectoire validée A → B+E → D1 → C → D2 → écriture de la roadmap suivante.
