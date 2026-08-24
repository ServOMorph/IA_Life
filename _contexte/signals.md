# Signals — ia_life (MAJ 2026-08-24)

## Actions ouvertes

- [P1|ouvert] Vérifier la reproductibilité seed-à-seed avant d'ajouter une nouvelle variable.
  fait quand: deux runs headless (même config, même seed) produisent des résultats agrégés strictement identiques, ou l'écart observé (faim finale 98.19 vs 99.09 sur un épisode RL identique) est expliqué et corrigé.
  réf: roadmap_experimentation.md (Phase 1 critère de reproductibilité, "Prochain sprint recommandé" item 5), rl/client_random.py
- [P2|ouvert] Formaliser les trois campagnes de référence sur plusieurs seeds et produire leurs graphiques.
  fait quand: les trois campagnes sont exécutables, reproductibles et agrégées.
  réf: roadmap_experimentation.md (Phase 4), tools/run_campaign.py

## Contexte chaud

- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de `/close` non exécutable).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers abandonnés (GDRL, godot-native-rl) et des lancements `run_rl.py` de cette session ; non trackés, à nettoyer manuellement si souhaité.

## Dernière session (2026-08-24)

# Session du 2026-08-24

## Décisions prises
- Cadre non historique retenu (île isolée), sans ancrage temporel — voir `DOCUMENTATION/orientation_contexte.md`.
- Rig Blender confirmé limité au personnage de développement ; Phase 5 graphisme close dans ce périmètre.

## Livrables produits ou modifiés
- `run_rl.py` : créé (lançait manquait pour armer `IA_LIFE_RL_MODE`) ; épisode RL complet validé via `rl/client_random.py`.
- `DESIGN/roadmap_graphisme.md`, `DESIGN/_contexte/*.md` : réconciliés avec l'état réel (Phases 2-5 [FAIT]).
- `_docs/2026-08-24_16h11_synthese-projet.md` : synthèse régénérée, ancienne archivée.
- `scripts/variable_registry.gd` : enrichi (libellé, description, portée, catégorie, défaut, dynamique, live_editable).
- `scripts/game_config.gd`, `scripts/character.gd` : valeurs par défaut migrées vers `VariableRegistry`.
- `tools/run_manual_checks.gd` : tests `ExperimentConfig` (défauts, overrides, validation) ajoutés.
- `roadmap_experimentation.md` : Phases 0 et 1 complétées (actions et statuts).

## Hypothèses validées / invalidées
- VALIDE : le blocage RL venait de l'absence de launcher, pas du bridge lui-même.
- EN ATTENTE : écart de faim finale entre deux runs à seed identique (98.19 vs 99.09), non expliqué.

## Prochaine étape exacte
Vérifier la reproductibilité seed-à-seed (deux runs identiques comparés) avant d'ouvrir la Phase 2 ; celle-ci est déjà partiellement avancée (traits comportementaux).

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
