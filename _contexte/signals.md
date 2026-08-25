# Signals — ia_life (MAJ 2026-08-25)

## Actions ouvertes

- [P2|ouvert] Décider de la suite de la Phase 6 (coopération, communication, agressivité)
  ou basculer vers la Phase 7 (LLM), toujours bloquée tant que Phase 6 n'est pas close.
  fait quand: décision actée et documentée dans roadmap_experimentation.md (Phase 6/7).
  réf: roadmap_experimentation.md (Phase 6 — action sociale non cochée, Phase 7)

## Contexte chaud

- Phases 1 à 5 closes et validées par l'utilisateur. Phase 4 : trois campagnes de référence
  (mémoire, rareté des ressources, profils contrastés) exécutées sur seeds 1/2/3, agrégées
  et graphiques (`experiments/README.md`). Phase 5 : Inspecteur générique dans `ui_manager.gd`
  piloté par `VariableRegistry`, sliders dupliqués retirés des panneaux de coin, confirmation
  avant Relancer.
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de
  `/close` non exécutable) — reconfirmé le 2026-08-25 (deuxième fois dans la journée).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `ROBERTO/com_telephone/` reste entièrement non tracké git (node_modules, `.env` avec
  secrets, voix, logs) — ne pas `git add` ce dossier en bloc. Cette session : script de
  salutation automatique retiré (`voice-code-bridge/server/server.js`) et bouton copier
  ajouté (`voice-code-bridge/mobile/index.html`, `app.js`), tous deux validés en direct par
  l'utilisateur via le bridge. Les 3 process (node/stt/tts) et le Monitor sur `messages.log`
  restent actifs en fin de session (task_id dans `ROBERTO/com_telephone/_commands/monitor.lock`),
  à revalider en début de session suivante.

## Dernière session (2026-08-25)

# Session du 2026-08-25

## Décisions prises
- Script de salutation automatique de ROBERTO retiré : "salut" remonte comme un message normal.
- Phase 4 (roadmap_experimentation.md) close : 3 campagnes de référence formalisées, exécutées, validées.
- Phase 5 close : Inspecteur générique, sliders dupliqués retirés, confirmation avant Relancer.

## Livrables produits ou modifiés
- `experiments/campaigns/*_campaign_v1.json` + configs associées : 3 nouvelles campagnes.
- `tools/plot_campaign.py` (nouveau), `tools/aggregate_results.py` (métriques mémoire/cueillette).
- `experiments/README.md` : documentation des 3 campagnes et résultats.
- `scripts/ui_manager.gd` : Inspecteur (Phase 5).
- `roadmap_experimentation.md` : Phases 4 et 5 marquées [FAIT].
- `tests_manuels.md` : vidé (tests 15/16 validés par l'utilisateur).
- ROBERTO (hors git) : script salutation retiré, bouton copier ajouté — validés en direct.

## Hypothèses validées / invalidées
- INVALIDE puis corrigée : premiers scénarios mémoire/rareté (60 s, faim initiale 100) ne
  produisaient aucune différenciation entre groupes -> durée et faim initiale ajustées.
- VALIDE : `memory_capacity` limite le nombre de ronciers retenus simultanément ; la rareté
  des ressources réduit la survie (8 % vs 33 %) ; des profils comportementaux contrastés
  produisent des distances parcourues différentes.

## Prochaine étape exacte
Décider si Phase 6 (coopération/communication/agressivité) est abordée maintenant ou si la
priorité passe ailleurs ; Phase 7 (LLM) reste bloquée tant que Phase 6 n'est pas close.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
