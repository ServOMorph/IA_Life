# Signals — ia_life (MAJ 2026-08-26)

## Actions ouvertes

- [P2|ouvert] Décider si un prompt few-shot est nécessaire pour la robustesse multi-modèles du
  décideur LLM, ou si `gemma3:1b` suffit comme référence stable (`gemma3:4b` s'est effondré sur
  une réponse fixe "manger"/"E" ce jour, indépendante de l'observation).
  fait quand: décision actée et documentée dans _docs/decisions/2026-08-26_decideurs-interchangeables-llm.md.
  réf: scripts/llm_decider.gd, experiments/llm_vs_automate_v1.json
- [P2|ouvert] Décider si une campagne multi-seeds est nécessaire pour valider statistiquement
  la coopération (fonctionne mais observée seulement en configuration généreuse à ce stade).
  fait quand: campagne lancée et documentée, ou décision explicite de considérer la validation
  fonctionnelle actuelle suffisante.
  réf: experiments/social_cooperation_smoke_v1.json, tools/aggregate_results.py (mean_food_shared)
- [P3|ouvert] Contrôle visuel manuel de l'affichage `decider_type`/`llm_*` dans l'Inspecteur
  (non vérifiable en headless).
  fait quand: test validé et retiré de tests_manuels.md.
  réf: tests_manuels.md, scripts/ui_manager.gd (_build_variable_field)

## Contexte chaud

- Phase 7 (LLM) implémentée et validée ce jour : décideur interchangeable (`automate`/`llm`/
  `llm_mock`) via `scripts/llm_decider.gd`, backend Ollama local, repli automatique sur erreur,
  campagne comparative exécutée deux fois (voir décision `2026-08-26_decideurs-interchangeables-llm.md`
  pour l'historique complet : bug HTTPRequest threadé, effondrement gemma3:4b, pivot gemma3:1b).
- Résultat de référence (5 seeds, `gemma3:1b`) : survie automate 65% / llm_mock 40% / llm 40%,
  distance et alimentation du LLM dans un ordre de grandeur cohérent — voir
  `results/llm_vs_automate_v1/report.json` (non tracké git, `results/` dans .gitignore).
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de
  `/close` non exécutable) — reconfirmé le 2026-08-26 (quatrième fois).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `ROBERTO/com_telephone/` reste entièrement non tracké git — ne pas `git add` ce dossier en
  bloc. Cette session : bridge relancé via `/com_manager start` (port 5000 libéré, Monitor
  recréé, task_id `b14pc3rlz` dans `monitor.lock`) ; l'appli téléphone a répondu au tout premier
  message puis est restée injoignable (`POST /send` -> `sent:0`) pour tous les envois suivants
  de la session malgré les 3 process actifs — à investiguer en début de session suivante si le
  bridge est réutilisé (piste : reconnexion WebSocket appli non rétablie automatiquement).
- Ollama tourne en arrière-plan (démarré cette session, `ollama serve` via l'app tray) avec
  `gemma3:1b` désormais utilisé par la campagne de référence.

## Dernière session (2026-08-26)

# Session du 2026-08-26

## Décisions prises
- Phase 7 (décideurs interchangeables) implémentée : décideur LLM via Ollama local, action
  "manger" routée via `memory_direction` (même précision de visée que l'automate), repli sur
  l'automate en cas d'erreur/timeout/indisponibilité.
- Modèle par défaut de la campagne `llm_vs_automate_v1` : `gemma3:1b` (gemma3:4b s'effondrait
  sur une réponse fixe indépendante du contexte).

## Livrables produits ou modifiés
- `scripts/llm_decider.gd` (nouveau) : décideur async, schéma JSON contraint, logging
  prompt/réponse, compteurs appels/erreurs/latence.
- `scripts/character.gd`, `scripts/main.gd`, `scripts/ui_manager.gd`,
  `scripts/variable_registry.gd` : décideur interchangeable, support enum/string, correctif UI.
- `tools/aggregate_results.py` : métriques LLM agrégées (mean_llm_calls, llm_error_rate, mean_llm_latency_ms).
- `experiments/llm_mock_smoke_v1.json`, `llm_vs_automate_v1.json` (+campagne) : scénarios.
- `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md` : décision + historique complet.

## Hypothèses validées / invalidées
- VALIDE : architecture async robuste, aucun run bloqué (timeout/erreur/indisponibilité gérés).
- INVALIDE puis corrigée : `HTTPRequest` threadé restait bloqué dans la scène complète
  (contention `WorkerThreadPool`) -> `use_threads = false`.
- INVALIDE puis corrigée : `gemma3:4b` répond quasi systématiquement "manger"/"E" quel que
  soit le contexte -> pivot vers `gemma3:1b` (résultats redevenus cohérents).
- EN ATTENTE : contrôle visuel manuel de l'Inspecteur (voir actions ouvertes).

## Prochaine étape exacte
Décider si un prompt few-shot est nécessaire pour la robustesse multi-modèles, ou si
`gemma3:1b` suffit comme référence stable pour la suite de la Phase 7.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
