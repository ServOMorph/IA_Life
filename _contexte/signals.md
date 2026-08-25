# Signals — ia_life (MAJ 2026-08-25)

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
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de `/close` non exécutable) — reconfirmé le 2026-08-25.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `ROBERTO/com_telephone/` (assistant vocal `voice-code-bridge`, hors périmètre Phase 4) : dossier entièrement non tracké git (node_modules, `.env` avec secrets, voix, logs) — seul `_commands/com_manager.md` a été modifié et committé cette session. Les 3 process (node/stt/tts) et le Monitor sur `messages.log` sont actifs en fin de session (task_id dans `_commands/monitor.lock`), à revalider en début de session suivante.

## Dernière session (2026-08-25)

# Session du 2026-08-25

## Décisions prises
- `com_manager.md` libère désormais le port 5000 (taskkill) avant tout démarrage/redémarrage de `node`, pour prévenir l'échec EADDRINUSE.

## Livrables produits ou modifiés
- `ROBERTO/com_telephone/_commands/com_manager.md` : nouvelle étape de libération du port 5000, procédure renumérotée.
- Assistant vocal ROBERTO : relancé (node/stt/tts) après nettoyage d'un `node.exe` orphelin non tracké ; Monitor `messages.log` relancé.

## Hypothèses validées / invalidées
- VALIDE : l'échec de démarrage de `node` provenait d'un process orphelin occupant le port 5000, pas du script lui-même.

## Prochaine étape exacte
Aucune action ia_life issue de cette session ; reprendre la Phase 4 (campagnes de référence) au prochain `/start`.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
