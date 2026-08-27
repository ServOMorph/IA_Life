# Signals — ia_life (MAJ 2026-08-27)

## Actions ouvertes

- [P2|ouvert] Décider si le reste de `ROBERTO/com_telephone` (jamais commité avant le 2026-08-26,
  hors les 3 fichiers modifiés ce jour-là) doit être ajouté au dépôt git en bloc ou zone par zone.
  fait quand: décision actée (ajout complet, ajout partiel motivé, ou exclusion définitive
  documentée).
  réf: ROBERTO/com_telephone/ (DEPLOYMENTS.md, _commands/, specification pdf, reste de
  voice-code-bridge/)
- [P3|ouvert] Nettoyer les souscriptions push dupliquées dans `push_subs.json` (accumulation
  sans purge des entrées valides à chaque réinscription).
  fait quand: dédoublonnage effectué ou décision explicite de laisser tel quel (impact mineur :
  notifications dupliquées).
  réf: ROBERTO/com_telephone/voice-code-bridge/server/server.js (sendPushNotification, route
  /push/subscribe), push_subs.json
- [P2|ouvert] Décider de la Phase 9 (aucune définie à ce stade) ou d'un autre axe de travail.
  fait quand: nouvelle phase ajoutée à roadmap_experimentation.md et démarrée, ou décision
  explicite de ne pas en ajouter pour l'instant.
  réf: roadmap_experimentation.md (section "Prochain sprint recommandé")

## Contexte chaud

- Phase 8 (vision et perception générique) close le 2026-08-27 : primitive de perception
  générique (`get_perception_type`/`get_perception_state`, groupe `perceptible`), vision
  (portée/angle/occlusion via `Character._perceive`), 3 choix de conception tranchés
  (orientation visuelle, priorité visible > mémorisé, mémorisation par vision). `social_radius`
  absorbé comme cas particulier de la vision (code partagé, `_update_social_perception` réutilise
  `_perceive`) — équivalence stricte démontrée à seed fixe sur les 3 scénarios Phase 6. Détail :
  `_docs/decisions/2026-08-27_phase8-vision-perception.md`.
- Bug trouvé et corrigé pendant la validation Phase 8 : la mémorisation par vision se déclenchait
  à chaque frame pour chaque entité visible, ce qui faisait boucler indéfiniment l'éviction quand
  plus d'entités étaient visibles simultanément que `memory_capacity`
  (`ronces_discovered_by_vision_total` explosait, dizaines de milliers d'incréments sur une
  campagne courte). Corrigé (mémorisation une fois par apparition, pas par frame) ; test de
  non-régression dédié dans `tools/run_manual_checks.gd`.
- Points ouverts hérités de la Phase 7 clos le 2026-08-27 : prompt few-shot du décideur LLM jugé
  non nécessaire (`gemma3:1b` reste stable et conforme avec le prompt étendu par la Phase 8,
  testé contre Ollama réel) ; coopération sociale validée statistiquement (campagne 5 seeds,
  partage de nourriture observé sur 5/5, jamais nul). Décisions dans
  `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md` et
  `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`.
- Écart connu : `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) —
  reconfirmé le 2026-08-27 (septième fois).
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- Ollama tourne en arrière-plan (`gemma3:1b` référence stable pour le décideur LLM, y compris
  avec le prompt étendu par la Phase 8).
- Quand un message "salut"/salutation arrive depuis `messages.log` (téléphone), répondre avec
  une phrase piochée dans `ROBERTO/com_telephone/voice-code-bridge/server/salutations.json`
  plutôt qu'une formule générique — préférence explicite de l'utilisateur.
- Convention `!<commande>` (commande à distance depuis le téléphone, git compris) et règle des
  deux canaux : inlinées dans `.claude/CLAUDE.md` (section "Bridge ROBERTO") et
  `ROBERTO/com_telephone/README.md`.

## Dernière session (2026-08-27)

# Session du 2026-08-27

## Décisions prises
- Phase 8 (vision) complétée : direction de référence = orientation visuelle, priorité roncier
  visible > mémorisé, mémorisation par vision. `social_radius` absorbé comme cas particulier de
  la vision (code partagé), équivalence stricte démontrée sur les 3 scénarios Phase 6.
- Prompt few-shot LLM jugé non nécessaire (`gemma3:1b` stable avec le prompt étendu).
- Coopération validée statistiquement (5 seeds, partage de nourriture jamais nul).

## Livrables produits ou modifiés
- `scripts/character.gd`, `ronce.gd`, `baseline_decider.gd`, `llm_decider.gd`, `main.gd`,
  `variable_registry.gd`, `ui_manager.gd` : Phase 8.
- `tools/aggregate_results.py`, `tools/run_manual_checks.gd` (6 nouveaux tests vision).
- `experiments/vision_*.json` (4 scénarios), `campaigns/vision_range_campaign_v1.json`,
  `campaigns/social_cooperation_multiseed_v1.json` : créés.
- `_docs/decisions/2026-08-27_phase8-vision-perception.md` : créé ; deux décisions Phase 6/7
  complétées d'un commentaire de clôture.

## Hypothèses validées / invalidées
- VALIDE : coopération reproductible sur 5/5 seeds ; `gemma3:1b` stable avec le prompt étendu.
- INVALIDE : mémorisation par vision à chaque frame -> boucle infinie si plus d'entités visibles
  que `memory_capacity` -> corrigée (une fois par apparition), test de non-régression ajouté.
- INVALIDE (mineure) : distance horizontale pour l'absorption sociale -> corrigée (distance 3D
  préservée pour le social via un paramètre `flatten_vertical` sur `_perceive`).

## Prochaine étape exacte
Décider de la Phase 9 (aucune définie) ou d'un autre axe ; sinon traiter les points restants hors
code (inclusion git de `ROBERTO/com_telephone`, dédoublonnage `push_subs.json`).

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
