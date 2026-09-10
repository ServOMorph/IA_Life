# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 4 personnages lowpoly, dont un est piloté par le développeur et les autres par des LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible (configs versionnées, logs JSONL, campagnes parallélisées).
Phases 1 à 8 closes ; axe apprentissage v2 suspendu après égalité statistique avec le hasard.
`roadmap_environnement_apprenable_v3.md` : Phases 0-2 [FAIT], Phase 3 [EN COURS]. Le contournement
avec cible et côté mémorisés échoue à la calibration : 10/12 contre `viser`, 5/12 contre
`aleatoire`, survie maximale 0,42. Une récupération de collision v3 est écrite et testée, mais
non mesurée ; recherche d'alternatives en pause. Les seeds réservés restent fermés.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-08-30 : `roadmap_apprentissage.md` close côté code (Phases 2-4). Phase 2 : récompense sur
  la fenêtre d'engagement + MAJ en ligne + pénalité terminale + logs. Phase 3 : gate recalibré
  (bras de contrôle `exploration_epsilon` 1,0, même seed) franchi sur un seed. Phase 4 (balayage
  `learning_rate` × `exploration_epsilon`, 2 seeds) : l'avantage 1B ne généralise pas,
  `learning_rate` sans effet mesurable — discrétisation probablement trop grossière pour
  apprendre en une vie. Bifurcation d'axe à trancher (affiner 1B, ou 1A/1C). Voir
  `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`. `llm_vs_automate_v1` rejoué
  post-correction : pas de régression avec le vrai LLM.
- 2026-08-30 : bifurcation de l'axe apprentissage tranchée — approche par étapes plutôt que
  « affiner la discrétisation » seul ou bascule 1C immédiate. `roadmap_apprentissage_v2.md` créée
  (diagnostic en 5 défauts structurels, 7 phases gatées sur métrique de résultat, benchmark
  avant/après à 6 bras figés). `roadmap_apprentissage.md` close ; `roadmap_roberto_multiprojet.md`
  et `roadmap_experimentation.md` archivées dans `_docs/archives/`.
- 2026-09-01 : Phases 0-1 de `roadmap_apprentissage_v2.md` closes. Phase 0 : parallélisme
  reproductible de `run_campaign.py` (`--jobs/--retries`, bras nommés `arms`), bras gelé
  `adaptatif_v1`. Phase 1 : décideur `politique_fixe`, environnement de référence gelé
  (`vision` 15 / `hunger` 0,7 / `ronce` 30), gate franchi à n=12 (`pf_er_rm` 0,83 vs `pf_er_er`
  0,17 ; bit apprenable = décision S2), mesure M0 prise. `pf_rv_rm` ≡ `automate` ; `aleatoire`
  meilleur bras M0 (0,92). Voir `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md`.
- 2026-09-01 : Phases 2-3 closes + **axe apprentissage suspendu** (branche « Échec »). Phase 2 :
  récompense événementielle + amorçage TD (γ 0,9), franchit le plateau sans-apprentissage
  (`adaptatif_v1` 0,50 < `aleatoire` 0,58) — mécanisme conservé. Phase 3 : espace d'action S3
  ×5 + `souvenir_ancien` ; gates (a)/(b) passés (le second sur env v2 enrichi). Environnement
  re-gelé en v2 (`eat_hunger_threshold` 90, `hunger` 0,9), rupture M0 v1 assumée. M1 v2 :
  `adaptatif_courant` (0,67) ne se sépare pas de `aleatoire` (0,58) ni de `adaptatif_v1` au
  seed apparié → suspension, M2-M5 et Phase 6 non engagées. Voir
  `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`.
- 2026-09-01 : environnement apprenable v3 planifié avant toute reprise du learner. Zones
  dangereuses localisées avec coût de faim, oracle fixe `eviter|ignorer|viser`, calibration puis
  validation sur 12 seeds réservés. La v2 ne sera débloquée qu'après ce gate — voir
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
- 2026-09-06 : Phases 0-1 de `roadmap_environnement_apprenable_v3.md` closes — mécanique de zones
  dangereuses (Area3D statiques, RNG dérivé de la seed, coût de faim au temps simulé = taux max,
  télémétrie `danger_*`) validée headless + fenêtré. Outillage dev : autoload `DevState` (overrides
  seed / nb de zones), `run_danger_windowed.py`, panneau dev enrichi ; fix `AnimationPlayer.speed_scale`
  indexé sur `GameSpeed.time_scale`. Prochaine : Phase 2 (perception + oracle).
- 2026-09-07 : Phase 2 de `roadmap_environnement_apprenable_v3.md` close — perception du danger
  raccordée à `_perceive`, décideur `fixed_policy_danger` (ignorer/eviter/viser) en surcouche
  isolée de la politique alimentaire, événement scripté `teleport_agent`. Gate causal franchi sur
  scénario scripté (seed 2) : exposition eviter 0,75 s < ignorer 1,73/1,47 s < viser 11,98 s,
  reproductible ; aucune régression sur l'oracle Phase 1. Prochaine : Phase 3 (calibration).
- 2026-09-08 : Phase 3 engagée, gate causal jamais franchi mais 3 causes d'échec en cascade
  corrigées (bug tirage `aleatoire` par frame, surcouche danger bornée par
  `danger_reaction_range`, plafond de survie remonté par `hunger_depletion_rate` 0,70 —
  `danger_zone_oracle_base_v2.json`, v1 conservé). Densité de zones testée jusqu'à 20 (tendance
  monotone, pas encore suffisant). Voir
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
- 2026-09-10 : seconde itération de placement sur approche de roncier validée techniquement
  (smoke, sweep 12 seeds, 1 728/1 728 placements) mais gate causal toujours en échec. Le probe
  de portée 10/12/15 m invalide l'hypothèse d'une réaction trop tardive : une fuite rectiligne
  perturbe la ressource sans fournir de contournement. Voir
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
- 2026-09-10 : contournement stateful testé sur calibration — coût évité nul et 10/12 contre
  `viser`, mais 5/12 seulement contre `aleatoire`, survie maximale 0,42. Échec du gate ; v3
  propose une récupération de collision non mesurée. Voir
  `_docs/decisions/2026-09-10_contournement-stateful.md`.
