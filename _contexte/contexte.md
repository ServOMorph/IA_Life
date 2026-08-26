# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 2 personnages lowpoly pilotés chacun par un LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Le prototype est un laboratoire headless reproductible : configurations versionnées, logs JSONL,
résumés et campagnes. Les Phases 1 à 7 sont closes fonctionnellement : temps simulé déterministe,
traits comportementaux mesurés, interactions sociales avancées, Inspecteur générique, et
décideur interchangeable automate/LLM (Ollama local) avec repli automatique sur erreur, validé
par une campagne comparative de référence (survie automate 65% / llm 40%, `gemma3:1b`).

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
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
- 2026-08-25 : Phase 6 close — communication (partage inconditionnel de position mémorisée),
  coopération (partage de nourriture si faim critique de l'autre) et agressivité (répulsion
  imposée) implémentées, chacune validée par un scénario de simulation dédié — voir
  `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`. Phase 7 débloquée.
- 2026-08-26 : Phase 7 — décideur LLM interchangeable (`scripts/llm_decider.gd`), backend
  Ollama local (`gemma3:1b`, `gemma3:4b` écarté après effondrement), repli automatique sur
  l'automate en cas d'erreur, campagne comparative validée — voir
  `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`.
- 2026-08-26 : ROBERTO — cause racine du bug "injoignable" identifiée et corrigée (clé VAPID
  codée en dur désynchronisée du serveur, pas un cache navigateur) ; reconnexion WebSocket et
  notification push validées en conditions réelles. Convention `!<commande>` (commande à
  distance depuis le téléphone, git compris) créée et inlinée dans `CLAUDE.md` en plus du
  README — un simple renvoi au README s'est avéré insuffisant.
