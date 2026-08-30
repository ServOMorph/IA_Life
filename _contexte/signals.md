# Signals — ia_life (MAJ 2026-08-30)

## Actions ouvertes

- [P1|ouvert] Rejouer `experiments/campaigns/llm_vs_automate_v1.json` (15 runs, dont 5 appels
  Ollama réels) avec les corrections de mécanique du 2026-08-29/30, pour compléter la
  revalidation des campagnes de référence. Ollama injoignable en fin de session
  (`127.0.0.1:11434` refuse la connexion) — vérifier qu'il tourne avant de lancer.
  fait quand: campagne rejouée, résultats comparés à `results/llm_vs_automate_v1/` (état
  pré-correction, conservé), tableau ajouté à la décision référencée.
  réf: _docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md, experiments/campaigns/llm_vs_automate_v1.json
- [P1|ouvert] Démarrer la Phase 2 de `roadmap_apprentissage.md` (récompense et mise à jour en
  ligne de la table adaptative) — Phase 1 faite et validée, checkpoint atteint, feu vert
  utilisateur en attente pour la phase suivante.
  fait quand: Phase 2 faite, tests verts, checkpoint `/compact` atteint.
  réf: roadmap_apprentissage.md (Phase 2), scripts/adaptive_decider.gd

## Contexte chaud

- **Deux bugs de mécanique corrigés (2026-08-29/30), affectant automate et LLM mock, pas
  seulement l'axe apprentissage** : (1) `baseline_decider.gd` ciblait un roncier au-dessus du
  seuil de faim au lieu d'en dessous — l'automate ne cherchait jamais sa nourriture en ayant
  faim ; (2) aucune condition ne faisait sortir un agent d'un objectif de cueillette atteint
  (cueillette une fois sur `body_entered`, pas de check d'inventaire plein dans les décideurs) —
  un agent qui ciblait enfin un roncier s'y figeait. Corrigés ensemble (cueillette continue au
  contact + `max_berries_carried` dans l'observation). Six campagnes de référence rejouées à
  seeds identiques : toutes les métriques reviennent dans la plage d'origine ou la dépassent
  (`social_cooperation_multiseed_v1` : 75 % → 85 % de survie). Détail complet et tableau :
  `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md`. `llm_vs_automate_v1`
  reste à rejouer (action P1 ci-dessus).
- Décideur adaptatif (`scripts/adaptive_decider.gd`, Phase 1 de `roadmap_apprentissage.md`) :
  fait et vert. Ajout non prévu au périmètre initial : engagement sur l'action
  (`adaptive_decision_interval_seconds`, défaut 2,0 s) — sans lui, l'ε-greedy à chaque frame
  changeait d'avis ~60 fois/s, rendant la récompense de Phase 2 inexploitable. Décision :
  `_docs/decisions/2026-08-29_engagement-decision-adaptatif.md`.
- Ollama ne répondait plus en fin de session (`127.0.0.1:11434` refuse la connexion) — ne pas
  supposer qu'il tourne sans revérifier ; la note précédente de ce fichier l'affirmait à tort.
- Écart connu : `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) —
  reconfirmé le 2026-08-30 (dixième fois).
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés ; non trackés, à nettoyer manuellement si souhaité.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) : non tracké, ne pas committer.
- `DOCUMENTATION/RL/report-source.md` : non tracké, à trier avec l'agent documentaire.
- `results/` (gitignoré) contient les dossiers de comparaison avant/pendant/après correction de
  chaque campagne rejouée (suffixes `__pre_correction`, `__seuil_seul`) — utiles pour la session
  suivante, à purger une fois `llm_vs_automate` traité et la décision validée.

## Dernière session (2026-08-30)

# Session du 2026-08-30

## Décisions prises
- Correction du seuil de recherche de nourriture (automate + LLM mock) : `hunger <=
  pickup_hunger_threshold` au lieu de `>`, alignée sur la mécanique de cueillette réelle.
- Correction de la mécanique de cueillette : cueillette continue tant que l'agent est au contact
  d'un roncier (`ronce.gd`), et les trois décideurs cessent de cibler un roncier quand
  l'inventaire est plein (`max_berries_carried` ajouté à l'observation).
- Décideur adaptatif : l'action choisie est tenue pendant un intervalle de décision
  (`adaptive_decision_interval_seconds`) plutôt que retirée à chaque frame physique.
- `_docs/captures/` purgé (3 captures, non versionnées) ;
  `ROBERTO/com_telephone/voice-code-bridge/` retiré du disque, `.gitignore` local mis à jour.

## Livrables produits ou modifiés
- `scripts/adaptive_decider.gd` : créé (Phase 1 complète de `roadmap_apprentissage.md`).
- `scripts/baseline_decider.gd`, `scripts/llm_decider.gd`, `scripts/character.gd`,
  `scripts/ronce.gd`, `scripts/variable_registry.gd`, `scripts/main.gd` : corrections seuil +
  mécanique de cueillette + engagement adaptatif.
- `tools/run_manual_checks.gd` : 15 nouvelles vérifications (adaptatif, engagement, cueillette
  continue, gating inventaire) ; suite complète verte.
- `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md`,
  `_docs/decisions/2026-08-29_engagement-decision-adaptatif.md` : créés, indexés.
- `roadmap_apprentissage.md` : Phase 1 passée à [FAIT], correctif documenté, risques mis à jour.

## Hypothèses validées / invalidées
- VALIDE : la correction de mécanique (seuil + cueillette continue + inventaire) restaure ou
  dépasse les six campagnes de référence rejouées à seeds identiques.
- EN ATTENTE : `llm_vs_automate_v1` non rejoué (Ollama injoignable) — pas de garantie que la
  correction se comporte de même avec le vrai LLM.
- EN ATTENTE (reportée de la session précédente) : la discrétisation en 3 situations est-elle
  assez fine pour l'apprentissage (gate Phase 3) — non réévaluée, Phase 2 non démarrée.

## Prochaine étape exacte
Vérifier qu'Ollama tourne, rejouer `llm_vs_automate_v1`. Puis, sur confirmation utilisateur,
démarrer la Phase 2 de `roadmap_apprentissage.md` (récompense et mise à jour en ligne).

## Question bloquante pour la session suivante
Aucune (prochaine étape actée ; feu vert Phase 2 à recueillir en séance).

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
