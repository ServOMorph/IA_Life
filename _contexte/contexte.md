# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot (GDScript), LLM externe (à définir)

## État actuel (réécrit intégralement à chaque /close)
Le prototype est un laboratoire headless reproductible : configurations versionnées, logs JSONL,
résumés et campagnes. Les Phases 1 à 5 sont closes : temps simulé déterministe, configuration
fixe distincte de l'état initial dynamique, traits comportementaux mesurés, trois campagnes de
référence (mémoire, rareté des ressources, profils contrastés) exécutées/agrégées/graphiques et
validées par l'utilisateur, Inspecteur générique piloté par le registre en jeu. Phase 6 (social
avancé : coopération/communication/agressivité) en attente de décision ; Phase 7 (LLM) bloquée
tant que Phase 6 n'est pas close.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-18 : Personnage riggé (Phase 5 graphisme, Blender custom généré par script)
  branché uniquement sur le personnage de test, validé — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- 2026-08-22 : Refonte visuelle des ronces (buisson vert fixe + mûres noires visibles,
  retrait à la cueillette) ; test manuel 5 validé — voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
- 2026-08-23 : Le rig Blender reste un outil du personnage de développement ; les quatre
  agents normaux conservent un rendu léger afin de préserver la priorité expérimentale.
- 2026-08-23 : Après échec des bridges tiers, le projet retient provisoirement un bridge
  TCP/JSONL maison pour le premier RL.
- 2026-08-24 : Cadre non historique (île isolée) retenu pour l'identité du jeu, sans ancrage
  temporel — voir `DOCUMENTATION/orientation_contexte.md`.
- 2026-08-24 : `VariableRegistry` devient la source unique des valeurs par défaut/bornes de
  `GameConfig` et `Character` ; bridge RL TCP/JSONL maison validé (épisode complet).
- 2026-08-24 : Les expériences comparables sont bornées par `max_simulation_seconds` et non
  par le temps mural ; la configuration fixe est séparée de `agents.initial_state`.
- 2026-08-25 : `ROBERTO/com_telephone/_commands/com_manager.md` libère désormais le port 5000
  (taskkill) avant tout démarrage/redémarrage de `node`, pour prévenir l'échec EADDRINUSE causé
  par un process orphelin non tracké.
- 2026-08-25 : Phase 4 close — 3 campagnes de référence (`memory_capacity`,
  `resource_scarcity`, `contrasted_profiles`) formalisées, exécutées sur seeds 1/2/3,
  agrégées (`tools/aggregate_results.py`) et graphiques (`tools/plot_campaign.py`, SVG sans
  dépendance). Résultats documentés dans `experiments/README.md`, validés par l'utilisateur.
- 2026-08-25 : Phase 5 close — Inspecteur générique dans `ui_manager.gd` piloté par
  `VariableRegistry` (sélecteur agent/catégorie, tags live/dynamique/nécessite-relancer),
  sliders dupliqués retirés des panneaux de coin, confirmation avant Relancer. Validé
  manuellement par l'utilisateur (tests 15/16).
- 2026-08-25 : ROBERTO (`voice-code-bridge`, hors git) — script de salutation automatique
  retiré (le message "salut" remonte désormais normalement vers l'agent) ; bouton copier
  ajouté sur les bulles de réponse de l'appli mobile. Les deux validés en direct par
  l'utilisateur via le bridge.
