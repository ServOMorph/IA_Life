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
- [P2|ouvert] Décider si le reste de `ROBERTO/com_telephone` (jamais commité avant ce jour, hors
  les 3 fichiers modifiés cette session) doit être ajouté au dépôt git en bloc ou zone par zone.
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

## Contexte chaud

- Phase 7 (LLM) implémentée et validée le 2026-08-26 : décideur interchangeable (`automate`/
  `llm`/`llm_mock`) via `scripts/llm_decider.gd`, backend Ollama local, repli automatique sur
  erreur, campagne comparative exécutée deux fois (voir décision
  `2026-08-26_decideurs-interchangeables-llm.md` pour l'historique complet).
- Résultat de référence (5 seeds, `gemma3:1b`) : survie automate 65% / llm_mock 40% / llm 40%,
  distance et alimentation du LLM dans un ordre de grandeur cohérent — voir
  `results/llm_vs_automate_v1/report.json` (non tracké git, `results/` dans .gitignore).
- Bridge ROBERTO (`com_telephone`) opérationnel de bout en bout, validé en conditions réelles
  (iPhone verrouillé) : reconnexion WebSocket, notification push de secours confirmées. Cause du
  bug "injoignable" constaté le 2026-08-25 : la constante `VAPID_PUBLIC_KEY` codée en dur dans
  `app.js` ne correspondait pas à `VAPID_PUBLIC` de `.env` côté serveur (pas un problème de
  cache navigateur comme supposé initialement) — toute souscription échouait donc
  systématiquement (`VapidPkHashMismatch`).
- Convention `!<commande>` (commande à distance depuis le téléphone, git compris) et règle des
  deux canaux désormais inlinées dans `.claude/CLAUDE.md` (section "Bridge ROBERTO") en plus du
  README — une simple référence au README s'est avérée insuffisante (deux oublis dans la même
  session malgré la règle déjà écrite).
- Le classificateur de sécurité du mode auto de Claude Code bloque systématiquement l'édition de
  `.claude/CLAUDE.md`, même après confirmation terminal explicite répétée ; une confirmation
  reçue uniquement via le téléphone (bridge) n'a jamais suffi. Contournement utilisé le
  2026-08-26 : demander à l'utilisateur de coller lui-même le texte fourni, puis nettoyer les
  doublons introduits par le collage manuel.
  `ROBERTO/com_telephone/` : seuls les 3 fichiers modifiés le 2026-08-26 (server.js, app.js,
  README.md) ont été committés cette session — le reste de l'arborescence (jamais tracké avant
  ce jour) reste volontairement non ajouté (voir action ouverte).
- Écart connu : `scripts/check_kit.py` est absent (contrôle d'intégrité de l'étape 10 de
  `/close` non exécutable) — reconfirmé le 2026-08-26 (cinquième fois).
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
- Bug ROBERTO "injoignable" résolu : cause racine = clé `VAPID_PUBLIC_KEY` obsolète dans
  `app.js` (pas un problème de cache navigateur comme supposé initialement).
- Convention `!<commande>` créée : commande à distance depuis le téléphone, autorisation
  permanente actée pour les actions git qu'elle déclenche.
- Règle "deux canaux" + convention `!<commande>` inlinées dans `CLAUDE.md` (référence seule au
  README insuffisante, prouvé deux fois cette session).
- Seuls les fichiers ROBERTO modifiés cette session sont committés ; pas d'ajout en bloc de
  l'arborescence jamais trackée avant ce jour (décision distincte à prendre).

## Livrables produits ou modifiés
- `ROBERTO/.../server.js` : logging des échecs push, purge auto souscription VAPID obsolète,
  détection ping/pong des connexions mortes.
- `ROBERTO/.../mobile/app.js` : reconnexion WS auto (visibilitychange/pageshow), correctif clé
  `VAPID_PUBLIC_KEY`, réinscription push systématique au chargement.
- `ROBERTO/.../README.md` : sections "Commandes à distance (préfixe !)" et "Ajouts dans
  CLAUDE.md".
- `.claude/CLAUDE.md` : section "Bridge ROBERTO" (règle deux canaux + convention `!<commande>`).
- `tests_manuels.md` : tests ROBERTO validés en direct retirés ; test Inspecteur Phase 7
  conservé.

## Hypothèses validées / invalidées
- VALIDE : reconnexion WebSocket après coupure, notification push bout en bout — confirmées en
  direct par l'utilisateur sur le téléphone (écran verrouillé).
- INVALIDE puis corrigée : hypothèse "souscription push en cache" -> vraie cause = clé VAPID
  codée en dur désynchronisée du serveur.
- INVALIDE : comparaison `sub.options.applicationServerKey` pour détecter le désaccord de clé ->
  API non exposée par Safari sur cette version, remplacée par désinscription systématique.

## Prochaine étape exacte
Décider si le reste de `ROBERTO/com_telephone` doit être ajouté au dépôt git, et nettoyer les
souscriptions push dupliquées dans `push_subs.json`.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
