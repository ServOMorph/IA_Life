# Signals — ia_life (MAJ 2026-08-24)

## Actions ouvertes

- [P1|ouvert] Clore la Phase 4 par les trois campagnes de référence et leur restitution visuelle.
  fait quand: les trois campagnes sont exécutables, reproductibles et agrégées.
  réf: roadmap_experimentation.md (Phase 4), tools/run_campaign.py

## Contexte chaud

- Phases 1 à 3 closes : limite `max_simulation_seconds` déterministe ; séparation de la
  configuration fixe et de `agents.initial_state` ; traits `goal_persistence`,
  `known_zone_preference` et `curiosity` validés par scénario ; cohérence JSONL/summary
  contrôlée par `tools/check_telemetry.py`. `risk_tolerance` reste reporté tant qu'aucun
  danger environnemental mesurable n'existe.
- Reproductibilité headless validée : `python tools/check_reproducibility.py experiments/telemetry_smoke_v1.json` exécute deux runs identiques et compare leurs summaries hors `session_id`. `max_simulation_seconds` remplace la limite murale non déterministe ; `max_wall_seconds` reste accepté en migration.
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l’étape 10 de `/close` non exécutable).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers abandonnés (GDRL, godot-native-rl) et des lancements `run_rl.py` de cette session ; non trackés, à nettoyer manuellement si souhaité.

## Dernière session (2026-08-24)

# Session du 2026-08-24

## Décisions prises
- La durée comparable d'une expérience est le temps simulé, non le temps mural.
- Les états dynamiques de départ sont isolés dans `agents.initial_state`.

## Livrables produits ou modifiés
- Contrat `ExperimentConfig`, moteur Godot et fixtures : exécution déterministe et état initial validés.
- `scripts/character.gd`, registre et trois scénarios : nouveaux traits mesurables ajoutés.
- `tools/check_reproducibility.py`, `tools/check_telemetry.py`, agrégateur : contrôles de résultats ajoutés.

## Hypothèses validées / invalidées
- VALIDE : deux runs headless de même configuration et seed produisent le même summary hors identifiant de session.
- VALIDE : les trois traits ajoutés produisent une différence mesurable à seed fixe.
- EN ATTENTE : `risk_tolerance`, faute de danger environnemental mesurable.

## Prochaine étape exacte
Finaliser la Phase 4 : formaliser les campagnes mémoire, rareté et profils, puis produire leur tableau et leurs graphiques.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
