# Signals — ia_life (MAJ 2026-09-01)

## Actions ouvertes

- [P2|ouvert] Nettoyer les résidus non trackés à la racine (manuel, sans lien avec une session) :
  `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid`, `_docs/Analyse du projet/`,
  `DOCUMENTATION/RL/report-source.md`.
  fait quand: `git status --short` ne liste plus ces entrées.
  réf: présentes depuis plusieurs sessions, jamais générées par le protocole vibecoding.
- [P3|dormant] Axe apprentissage individuel suspendu (branche « Échec »). Réouverture possible
  via Phase 6 (approximation de fonction linéaire sur variables continues) ou une v3, mais
  seulement sur décision explicite — prior faible.
  fait quand: décision explicite de rouvrir, ou abandon définitif acté.
  réf: `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`,
  `roadmap_apprentissage_v2.md` (bandeau en tête).

## Contexte chaud

- `roadmap_apprentissage_v2.md` : Phases 0-3 [FAIT], Phases 4-6 [NON ENGAGÉE]. Bandeau
  « AXE SUSPENDU » en tête. Ne pas relancer M2 v2 / M3 / Phases 4-5.
- Résultat de suspension (M1 v2, env enrichi v2, 12 seeds) : `adaptatif_courant` survie 0,67 /
  mûres 12,9 = meilleur bras en agrégat, mais apparié au seed : 4-3/12 survie et 4-6/12 mûres
  vs `aleatoire` (0,58) ; 3-1/12 (8 nuls) vs `adaptatif_v1` (0,50). Non-séparable. `automate`
  s'effondre à 0,08 sur env v2.
- Deux environnements gelés coexistent :
  - `experiments/apprentissage_env_ref.json` (v1 : `hunger` 0,7, `eat_hunger_threshold` défaut
    50) — M0 v1 / M1 v1 (`results/_benchmark_apprentissage_m0`, `_m1`).
  - `experiments/apprentissage_env_ref_v2.json` (v2 : `hunger` 0,9, `eat_hunger_threshold` 90,
    supprime le tampon de digestion) — M0 v2 / M1 v2. Rupture M0 v1 → Mf v1 assumée.
- Code Phases 2-3 conservé et testé : `scripts/adaptive_decider.gd` (récompense événementielle
  +1/cueillette −c·Δt −1 terminal, amorçage TD γ 0,9, S3 = 5 actions, S2 + `souvenir_ancien`,
  `TABLE_SCHEMA_VERSION` `phase3-actions-1`). `tools/run_manual_checks.gd` : `SUCCÈS`.
- `politique_fixe_max_v1` dépend de l'environnement : `pf_er_rm` sur v1 (0,83), `pf_rm_er` sur
  v2 (0,58). `pf_rv_rm` ≡ `automate` bit à bit (les deux environnements).
- Vie médiane inutilisable comme métrique de résultat sur v2 : saturée à 300 dès que
  survie ≥ 0,5. Seules survie et mûres mangées discriminent.
- `results/` gitignoré. Dossiers de cette session conservés : `_p3_oracle`, `_p3b_env_probe`,
  `_benchmark_apprentissage_m0_v2`, `_benchmark_apprentissage_m1_v2`.
- `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) — contourné par `--retries`.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée (`.claude/memory.md`).
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 14e confirmation.
- `scripts/adaptive_decider_v1.gd` : ne pas supprimer tant que la suspension n'est pas définitive
  (la roadmap prévoyait sa suppression à la clôture).

## Dernière session (2026-09-01)

# Session du 2026-09-01

## Décisions prises
- Axe apprentissage individuel SUSPENDU (branche « Échec » du critère écrit à l'avance de
  `roadmap_apprentissage_v2.md`). `adaptatif_courant` ne bat ni `adaptatif_v1` ni la sélection
  aléatoire au seed apparié, même après enrichissement de l'environnement.
- Phase 2 (signal événementiel + amorçage TD) et Phase 3 (espace d'action S3 ×5 + `souvenir_ancien`)
  closes [FAIT], code conservé (gates (a)/(b) passés, tests verts). M2 v2 / M3 / Phases 4-6 non
  engagées.
- Environnement re-gelé en v2 (`eat_hunger_threshold` 90, `hunger_depletion_rate` 0,9) ; rupture
  M0 v1 → Mf v1 assumée, remplacée par M0 v2 / M1 v2.

## Livrables produits ou modifiés
- `scripts/` : `adaptive_decider.gd`, `character.gd`, `fixed_policy_decider.gd`,
  `variable_registry.gd` (S3 ×5, `souvenir_ancien`, `fixed_policy_s3`, `TABLE_SCHEMA_VERSION`).
- `tools/` : `run_manual_checks.gd` (tests nav S3), `benchmark_report.py` (part multi-action
  réelle via `available_count`), `check_fixed_policy.py` (`force_wander` s3).
- `experiments/` : `apprentissage_env_ref_v2.json` (gelé), `p3_adaptive_selftest.json`,
  `p3b_env_probe.json` + 4 campagnes (`p3_oracle`, `p3b_env_probe`, `benchmark m0_v2`, `m1_v2`) ;
  `p2_adaptive_selftest.json` + `benchmark_apprentissage_m1.json` (Phase 2, non commités avant).
- `_docs/decisions/` : `2026-09-01_phase2-signal-recompense-td.md` (validé),
  `2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md` (validé) + INDEX.
- `roadmap_apprentissage_v2.md` : bandeau suspension, statuts Phases 2-3 [FAIT], 4-6 non engagées.

## Hypothèses validées / invalidées
- VALIDE : signal événementiel + amorçage TD franchit le plateau sans-apprentissage
  (`adaptatif_v1` 0,50 < `aleatoire` 0,58 ; `adaptatif_courant` 0,67 = meilleur bras agrégé).
- VALIDE : actions S3 non cosmétiques sur env v2 (`cap_maintenu` 0,50 vs `demi_tour` 0,17 = 9-1/12).
- INVALIDE : une table discrète bat l'aléatoire. `adaptatif_courant` vs `aleatoire` = 4-3/12
  survie, 4-6/12 mûres (pile ou face). → suspension de l'axe.

## Prochaine étape exacte
Aucune sur l'axe apprentissage (suspendu). Nettoyer les résidus non trackés (P2) si souhaité.
Toute reprise (Phase 6 ou v3) exige une décision explicite.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
