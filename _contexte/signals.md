# Signals — ia_life (MAJ 2026-08-26)

## Actions ouvertes

- [P2|ouvert] Décider si un prompt few-shot est nécessaire pour la robustesse multi-modèles du
  décideur LLM, ou si `gemma3:1b` suffit comme référence stable (`gemma3:4b` s'est effondré sur
  une réponse fixe "manger"/"E" ce jour, indépendante de l'observation). Point à trancher en même
  temps que l'extension du prompt LLM prévue en Phase 8 (même code touché).
  fait quand: décision actée et documentée dans _docs/decisions/2026-08-26_decideurs-interchangeables-llm.md.
  réf: scripts/llm_decider.gd, experiments/llm_vs_automate_v1.json, roadmap_experimentation.md (Phase 8)
- [P2|ouvert] Décider si une campagne multi-seeds est nécessaire pour valider statistiquement
  la coopération (fonctionne mais observée seulement en configuration généreuse à ce stade).
  fait quand: campagne lancée et documentée, ou décision explicite de considérer la validation
  fonctionnelle actuelle suffisante.
  réf: experiments/social_cooperation_smoke_v1.json, tools/aggregate_results.py (mean_food_shared)
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
- [P3|ouvert] Démarrer ou reporter explicitement la Phase 8 (vision et perception générique),
  ajoutée en [TODO] à la roadmap ; trois choix de conception à trancher avant l'implémentation
  (mémorisation par vision ou non, priorité visible/mémorisé, direction de référence du champ
  de vision).
  fait quand: Phase 8 passée [EN COURS] avec les choix tranchés, ou décision explicite de la
  reporter après les points ouverts Phase 7.
  réf: roadmap_experimentation.md (Phase 8)

## Contexte chaud

- Phase 7 (LLM) implémentée et validée le 2026-08-26 : décideur interchangeable (`automate`/
  `llm`/`llm_mock`) via `scripts/llm_decider.gd`, backend Ollama local, repli automatique sur
  erreur, campagne comparative exécutée deux fois (voir décision
  `2026-08-26_decideurs-interchangeables-llm.md` pour l'historique complet).
- Résultat de référence (5 seeds, `gemma3:1b`) : survie automate 65% / llm_mock 40% / llm 40%,
  distance et alimentation du LLM dans un ordre de grandeur cohérent — voir
  `results/llm_vs_automate_v1/report.json` (non tracké git, `results/` dans .gitignore).
- Défaut `llm_model` du registre corrigé (`scripts/variable_registry.gd`) : `gemma3:4b` ->
  `gemma3:1b`, trouvé désaligné avec la décision Phase 7 lors du contrôle manuel de l'Inspecteur.
- Roadmap : Phase 8 (Vision et perception générique de l'environnement) ajoutée en [TODO]. La
  vision remplace la découverte de ressources par contact seul, généralise à n'importe quelle
  entité perceptible, et absorbe `social_radius` sous condition d'équivalence démontrée sur les
  scénarios sociaux Phase 6. Recommandation : la traiter avant d'élargir les campagnes LLM (elle
  change l'observation transmise au décideur).
- `tests_manuels.md` vidé intégralement le 2026-08-26 : tous les tests en attente validés
  (Inspecteur Phase 7, reconnexion WebSocket ROBERTO, re-abonnement push VAPID).
- Bridge ROBERTO (`com_telephone`) opérationnel de bout en bout, validé en conditions réelles
  (iPhone verrouillé) : reconnexion WebSocket, notification push de secours confirmées. Cause du
  bug "injoignable" constaté le 2026-08-25 : la constante `VAPID_PUBLIC_KEY` codée en dur dans
  `app.js` ne correspondait pas à `VAPID_PUBLIC` de `.env` côté serveur (pas un problème de
  cache navigateur comme supposé initialement) — toute souscription échouait donc
  systématiquement (`VapidPkHashMismatch`).
- Convention `!<commande>` (commande à distance depuis le téléphone, git compris) et règle des
  deux canaux désormais inlinées dans `.claude/CLAUDE.md` (section "Bridge ROBERTO") en plus du
  README.
- Le classificateur de sécurité du mode auto de Claude Code bloque systématiquement l'édition de
  `.claude/CLAUDE.md`, même après confirmation terminal explicite répétée ; une confirmation
  reçue uniquement via le téléphone (bridge) n'a jamais suffi. Contournement utilisé le
  2026-08-26 : demander à l'utilisateur de coller lui-même le texte fourni.
- `ROBERTO/com_telephone/` : seuls les 3 fichiers modifiés le 2026-08-26 (server.js, app.js,
  README.md) ont été committés — le reste de l'arborescence (jamais tracké avant ce jour) reste
  volontairement non ajouté (voir action ouverte).
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de
  `/close` non exécutable) — reconfirmé le 2026-08-26 (sixième fois).
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- Ollama tourne en arrière-plan (`ollama serve` via l'app tray) avec `gemma3:1b` utilisé par la
  campagne de référence LLM.
- Quand un message "salut"/salutation arrive depuis `messages.log` (téléphone), répondre avec
  une phrase piochée dans `ROBERTO/com_telephone/voice-code-bridge/server/salutations.json`
  plutôt qu'une formule générique — préférence explicite de l'utilisateur, actée le 2026-08-26.

## Dernière session (2026-08-26)

# Session du 2026-08-26

## Décisions prises
- Défaut `llm_model` du registre corrigé (`gemma3:4b` -> `gemma3:1b`), aligné sur la décision
  Phase 7 déjà actée mais jamais reportée dans `variable_registry.gd`.
- Phase 8 (Vision et perception générique de l'environnement) ajoutée à la roadmap en [TODO],
  avec recommandation de la traiter avant d'élargir les campagnes LLM.

## Livrables produits ou modifiés
- `scripts/variable_registry.gd` : défaut `llm_model` corrigé (ligne 37).
- `tests_manuels.md` : vidé intégralement (tous les tests en attente validés).
- `roadmap_experimentation.md` : Phase 8 ajoutée, section "Prochain sprint recommandé" mise à
  jour.
- `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md` : commentaire ajouté sur le
  correctif du défaut `llm_model`.

## Hypothèses validées / invalidées
- VALIDE : affichage `decider_type`/`llm_*` dans l'Inspecteur conforme à l'attendu (test manuel
  Phase 7).
- INVALIDE : hypothèse que le défaut `llm_model` du registre était déjà aligné sur `gemma3:1b`
  -> resté sur `gemma3:4b`, corrigé.

## Prochaine étape exacte
Décider de l'ordre entre la Phase 8 (vision) et les points ouverts Phase 7 (few-shot, campagne
coopération multi-seeds) ; démarrer la Phase 8 si priorité confirmée.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
