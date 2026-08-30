# Signals — ia_life (MAJ 2026-08-30)

## Actions ouvertes

- [P1|ouvert] Trancher la bifurcation de l'axe apprentissage. Phase 4 montre que 1B
  « heuristiques apprises » ne rend pas de façon robuste en une seule vie (avantage ~0,05
  de `reward`, s'inverse sur le 2e seed ; `learning_rate` sans effet mesurable). Deux voies :
  (1) affiner la discrétisation (sous-situations : porte des mûres, distance au roncier
  visible, fraîcheur mémoire) puis re-tester le couplage `learning_rate` → comportement ;
  (2) acter que 1B ne rend pas en une vie ici et arbitrer entre 1A (sélection entre vies,
  la table devient un génotype) et 1C (RL).
  fait quand: voie choisie et consignée dans `contexte.md` (décisions structurantes) ; si
  voie 1, nouvelle roadmap ou avenant ; si voie 2, décision d'axe actée.
  réf: _docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md (sections Phase 4),
  roadmap_apprentissage.md
- [P2|ouvert] Investiguer la divergence `game_speed` x4 vs x1. Un test A/B (config adaptative
  identique, seed fixe) donne des simulations différentes : séries de récompense divergentes
  dès la 2e décision, spans de temps simulé différents. Contredit la note mémoire projet
  `2026-08-17 — Vitesse de jeu = accélérateur de temps pur`. Impact : les campagnes doivent
  tourner à `game_speed` 1,0 (headless ~temps réel → 2 h pour 24 runs de 300 s).
  fait quand: cause identifiée (accumulation de pas physiques, aléa indexé sur delta, ou
  autre) et soit corrigée, soit documentée comme limite connue dans la note mémoire.
  réf: `.claude/memory.md` (note 2026-08-17), scripts/character.gd::_physics_process,
  scripts/main.gd (boucle headless), scripts/game_speed.gd

## Contexte chaud

- **Roadmap `roadmap_apprentissage.md` terminée côté code (4 phases).** Phase 2
  (récompense + MAJ en ligne + pénalité terminale + logs `apprentissage_*`) faite, tests
  verts. Phase 3 : gate franchi sur un seed (learner ε 0,2 `reward` −0,203 > contrôle
  ε 1,0 −0,250, reproductible ; table S1 `ronce_visible` devient +0,106 ; learner survit,
  contrôle meurt). Phase 4 : l'effet **ne généralise pas** sur 2 seeds. Statut de la
  décision : `proposé`. Détail : `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`.
- `llm_vs_automate_v1` rejoué post-correction (Ollama redémarré) : 15/15 runs OK. `automate`
  et `llm_mock` suivent les 6 autres campagnes (cueillette/survie en hausse). `llm` réel :
  la correction du seuil ne le touche pas (par conception, son prompt ignore le seuil), les
  écarts sont dans le bruit d'un modèle 1 B sur 5 seeds, **aucune régression**. Tableau
  ajouté à `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md`. La
  revalidation des corrections de mécanique du 2026-08-29/30 est complète.
- Ollama : n'était pas lancé en début de session, redémarré via `ollama serve` (binaire
  `D:\Ollama\ollama.exe`, `gemma3:1b` présent). Ne pas supposer qu'il tourne — le
  `com_manager.py status` de Roberto ne le couvre pas.
- Écart connu : `scripts/check_kit.py` toujours absent (étape 10 de `/close` non
  exécutable) — reconfirmé le 2026-08-30 (onzième fois).
- `results/` (gitignoré) : `apprentissage_faim_v1/` (Phase 3, 4 runs) et
  `apprentissage_faim_v2_sweep/` (Phase 4, 24 runs) conservés. Les dossiers
  `__pre_correction` / `__seuil_seul` des 6 campagnes de référence + `llm_vs_automate_v1/`
  (état pré-correction) peuvent être purgés : la revalidation est close.
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL
  tiers abandonnés ; non trackés, à nettoyer manuellement si souhaité.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) : non tracké, ne pas committer.
- `DOCUMENTATION/RL/report-source.md` : non tracké, à trier avec l'agent documentaire.

## Dernière session (2026-08-30)

# Session du 2026-08-30

## Décisions prises
- Phase 3 recalibrée (option C) : le gate absolu de pente est remplacé par une comparaison
  à un bras de contrôle `exploration_epsilon` 1,0 (sélection aléatoire, table jamais lue)
  au même seed ; `vision_range` de l'apprenant ramenée à 15 pour exercer S1/S2/S3.
- `REWARD_HUNGER_SCALE` : constante (5,0) dans `adaptive_decider.gd`, non promue au registre
  (Phase 4 montre que `learning_rate` n'a pas d'effet, la régler seule est peu utile).

## Livrables produits ou modifiés
- `scripts/adaptive_decider.gd` : Phase 2 — `_apply_online_reward`, `_commit_reward`,
  `on_terminal_starvation`, `log_table`, logs `apprentissage_decision/maj/table`.
- `scripts/character.gd`, `scripts/main.gd` : hooks fin de vie (MAJ terminale + dump table).
- `tools/run_manual_checks.gd` : 2 tests Phase 2 (reward en ligne, pénalité terminale) ; suite verte.
- `tools/aggregate_results.py` : mode `--learning-curve` (fenêtre glissante, pentes,
  volatilité, demi-vies, `params` du bras, reproductibilité par bras).
- `tools/plot_learning_curve.py` : créé (2 SVG, sans dépendance).
- `experiments/apprentissage_faim_v{1,2}.json`, `experiments/campaigns/apprentissage_faim_v1.json`,
  `experiments/campaigns/apprentissage_faim_v2_sweep.json` : créés.
- `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md` : créé (Phases 3-4) + INDEX.
- `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md` : tableau
  `llm_vs_automate_v1` post-correction ajouté.
- `experiments/README.md` : section « Courbe d'apprentissage du décideur adaptatif ».

## Hypothèses validées / invalidées
- VALIDE : le mécanisme Phase 2 (récompense, MAJ moyenne mobile, pénalité terminale unique)
  est correct et reproductible (tests + smoke headless).
- VALIDE : la correction de mécanique du 2026-08-29/30 tient aussi avec le vrai LLM
  (`llm_vs_automate_v1` rejoué, pas de régression).
- INVALIDE : « l'apprentissage intra-vie 1B améliore la survie de façon robuste » — vrai sur
  le seed 20260830, faux sur 20260831 (le contrôle aléatoire fait mieux). `learning_rate`
  sans couplage au comportement → discrétisation probablement trop grossière pour apprendre
  en une vie. Pivot recommandé (voir action P1).
- INVALIDE : « `game_speed` est un pur accélérateur de temps » — x4 diverge de x1 sur le
  chemin du décideur adaptatif (voir action P2).

## Prochaine étape exacte
Trancher la bifurcation de l'axe apprentissage (action P1) : affiner la discrétisation 1B,
ou basculer vers 1A / 1C. En parallèle, investiguer la divergence `game_speed` (action P2).

## Question bloquante pour la session suivante
Bifurcation d'axe : affiner 1B (sous-situations plus fines) ou acter que 1B ne rend pas en
une vie et arbitrer 1A vs 1C ?

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
