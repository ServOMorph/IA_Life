# Signals — ia_life (MAJ 2026-09-01)

## Actions ouvertes

- [P1|ouvert] Exécuter `roadmap_apprentissage_v2.md`. Phases 0 (débit expérimental) et 1
  (calibrage environnement + oracle) closes. Environnement de référence gelé, gate Phase 1
  franchi à n=12, mesure M0 prise. Prochaine phase : Phase 2 (refonte du signal : récompense
  événementielle + amorçage TD), après checkpoint /compact.
  fait quand: Mf pris et verdict M0 -> Mf prononcé (succès / succès partiel / échec).
  réf: roadmap_apprentissage_v2.md, _docs/decisions/2026-08-31_calibrage-environnement-oracle.md
- [P2|surveillance] `aleatoire` (survie M0 0,92) plafonne au-dessus d'`adaptatif_v1` (0,83) :
  la bande utile pour le critère de succès Mf sur la métrique primaire (survie) est étroite en
  haut. Les métriques secondaires (mûres mangées, vie médiane) devront porter la comparaison.
  fait quand: statué à M1 (Phase 2) — soit la survie discrimine encore, soit bascule explicite
  sur une métrique secondaire consignée dans la décision de phase.
  réf: _docs/decisions/2026-08-31_calibrage-environnement-oracle.md (section Angles morts),
  results/_benchmark_apprentissage_m0/oracle_report.json

## Contexte chaud

- `roadmap_apprentissage_v2.md` : Phases 0 et 1 [FAIT], Phase 2 [TODO] (prochaine). Benchmark :
  `politique_fixe_max_v1` identifié = `pf_er_rm` (S1 errance / S2 souvenir), survie M0 0,83.
  `pf_rv_rm` ≡ `automate` bit à bit (ne pas le compter comme bras distinct). Bit apprenable
  identifié = décision S2 (« souvenir utilisable, pas de roncier visible → viser le souvenir »
  vs errer) : `pf_er_rm` 0,83 vs `pf_er_er` 0,17.
- Environnement gelé `experiments/apprentissage_env_ref.json` : `vision_range` 15,
  `hunger_depletion_rate` 0,7, `ronce_count` 30, 300 s. Toute mesure M0..Mf tourne dessus ;
  tout changement invalide les comparaisons et doit être consigné.
- `experiments/campaigns/benchmark_apprentissage.json` : 9 bras, seeds d'entraînement
  20260901-12, seeds réservés 20270101-12 (non joués avant Phases 3-4). Fichier non modifiable
  une fois écrit.
- Note parquée dans `roadmap_apprentissage_v2.md` (Phase 1) : « manger au contact » (retrait
  consommation différée, Variante C = `eat_hunger_threshold` = `pickup_hunger_threshold`).
  Conditionnelle à un échec de gate ; gate franchi donc inactive, la Phase 2 gère le timing.
- `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) — mode d'échec Phase 0.
  Contourné par `--retries` + `--jobs` réduit. 10 cellules `pf_er_er` de la campagne de
  faisabilité (environnements non retenus) laissées non rejouées.
- `results/` gitignoré : `_p1_oracle_probe/`, `_p1_oracle_feasibility/`,
  `_benchmark_apprentissage_m0/` conservés (données M0). Anciens dossiers purgeables inchangés.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée comme limite connue
  (`.claude/memory.md`, note 2026-08-31). Hors chemin critique v2. Action P2 précédente close.
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 13e confirmation.
- Résidus non trackés à nettoyer manuellement : `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`,
  `.rl_godot_pid`, `_docs/Analyse du projet/`, `DOCUMENTATION/RL/report-source.md`.

## Dernière session (2026-09-01)

# Session du 2026-09-01

## Décisions prises
- Phase 1 v2 close : environnement de référence gelé (`vision` 15 / `hunger` 0,7 / `ronce` 30),
  gate franchi à n=12, mesure M0 prise. Décision
  `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md` (proposé).
- Phase 0 v2 close (parallélisme reproductible + gel `adaptatif_v1`) — reportée de la session
  précédente, actée formellement ici.

## Livrables produits ou modifiés
- `scripts/fixed_policy_decider.gd`, `scripts/adaptive_decider_v1.gd` : créés (bras oracle + gelé).
- `scripts/variable_registry.gd`, `scripts/character.gd` : `politique_fixe`, `adaptatif_v1`,
  `fixed_policy_s1/s2`.
- `tools/run_campaign.py` : parallélisme (`--jobs/--retries/--warmup`) + bras nommés (`arms`).
- `tools/oracle_report.py`, `check_fixed_policy.py`, `check_campaign_parallelism.py`,
  `check_adaptive_v1_equivalence.py` : créés. `aggregate_results.py` : `arm` au regroupement.
- `experiments/apprentissage_env_ref.json` (gelé), `experiments/campaigns/benchmark_apprentissage.json`.
- `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md` + INDEX. `.claude/memory.md`
  (note game_speed). `roadmap_apprentissage_v2.md` (statuts + note « manger au contact »).

## Hypothèses validées / invalidées
- VALIDE : la tâche est apprenable dans un environnement calibré — `pf_er_rm` 0,83 vs
  `pf_er_er` 0,17, écart 0,67, accord 9/12. Bit apprenable = décision S2.
- VALIDE : `pf_rv_rm` ≡ `automate` bit à bit (n=12) ; `automate` code une mauvaise priorité.
- EN ATTENTE : `aleatoire` (0,92) > `adaptatif_v1` (0,83) → bande Mf étroite sur la survie.

## Prochaine étape exacte
Phase 2 v2 : récompense événementielle (+1 cueillette, coût survie −c·Δt, −1 terminal) +
amorçage TD (Q(s,a) += α[r + γ·maxQ(s',·) − Q(s,a)], γ ~0,9) + versionnage format de table.
Tests d'attribution du crédit + mesure M1.

## Question bloquante pour la session suivante
Aucune — checkpoint Phase 1 posé, /compact fait, Phase 2 prête.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
