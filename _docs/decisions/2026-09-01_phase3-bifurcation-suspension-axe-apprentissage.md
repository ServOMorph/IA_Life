# Phase 3 + bifurcation environnement — suspension de l'axe apprentissage

Date : 2026-09-01
Statut : validé (décision utilisateur de suspendre l'axe, prise le 2026-09-01)
Roadmap : `roadmap_apprentissage_v2.md`, Phase 3 et branche « Échec » du critère de succès
Succède à : `_docs/decisions/2026-09-01_phase2-signal-recompense-td.md` (Phase 2, M1)

## Résumé

L'axe apprentissage individuel est **suspendu** (décision utilisateur, conforme à la branche
« Échec » écrite à l'avance dans la roadmap). Après refonte du signal (Phase 2), élargissement de
l'espace d'action (Phase 3) et enrichissement de l'environnement gelé, le décideur adaptatif
`adaptatif_courant` **ne se sépare pas de la sélection d'action aléatoire** ni du décideur gelé
`adaptatif_v1` sur les seeds appariés. Le code Phases 2-3 est conservé ; M2 v2 / M3 et les
Phases 4-5 ne sont pas exécutées ; la Phase 6 (approximation de fonction) n'est pas engagée.

## Phase 3 — ce qui a été livré

Espace d'action élargi là où les décisions se prennent (défaut 1 du diagnostic) :

- `scripts/adaptive_decider.gd` : S3 (inconnu) passe de 1 à 5 actions — `errance`, `cap_maintenu`,
  `demi_tour`, `zone_inconnue`, `zone_connue` ; S2 gagne `souvenir_ancien` (souvenir le plus
  estompé, distinct de `ronce_memorisee` = le plus proche). `available_actions` filtre par
  faisabilité (direction de zone exploitable, souvenir présent). `cap_maintenu` / `demi_tour`
  s'ancrent sur le cap figé à la décision (`_engaged_reference_direction`) — sans ça, `demi_tour`
  recalculé par frame oscille à 180°/frame. `TABLE_SCHEMA_VERSION` → `phase3-actions-1`.
  `apprentissage_decision` journalise `available_count`.
- `scripts/character.gd` : observation enrichie de `old_memory_direction`, `unknown_zone_direction`,
  `known_zone_direction` (calculées par frame, pures : aucun RNG, aucune mutation d'état — vérifié
  par non-régression bit à bit des bras gelés). `@export fixed_policy_s3`.
- `scripts/fixed_policy_decider.gd` : `fixed_action_s3`, `configure_fixed` à 3 situations.
- `scripts/variable_registry.gd` : `fixed_policy_s3` (enum), `fixed_policy_s2` + `souvenir_ancien`.
- `tools/benchmark_report.py` : part multi-action réelle via `available_count` (repli sur
  l'approximation par situation pour `adaptatif_v1` qui n'émet pas le champ).
- `tools/run_manual_checks.gd` : tests de l'espace S3 (5 actions, ancrage cap, dispatch politique
  fixe S3). `SUCCÈS`.
- `tools/check_reproducibility.py experiments/p3_adaptive_selftest.json` : `REPRODUCTIBLE`.

## Phase 3 — gate sur l'environnement v1 : (b) en échec

Oracle `experiments/campaigns/p3_oracle.json` (S1=errance, S2=ronce_memorisee, S3 balayé,
env gelé v1, 12 seeds) :

| S3 | survie | vie médiane | mûres |
|---|---|---|---|
| errance (incumbent, = politique_fixe_max_v1) | 0,83 | 300 | 7,83 |
| zone_inconnue | 0,75 | 300 | 7,17 |
| cap_maintenu | 0,67 | 300 | 7,17 |
| demi_tour | 0,58 | 300 | 6,33 |
| zone_connue | 0,58 | 300 | 6,17 |

- (a) part des décisions ≥ 2 actions : acquise (S3 = 63 % des décisions, toujours ≥ 3 actions).
- (b) écart significatif entre ≥ 2 nouvelles actions S3 : **non** sur l'env v1 — vie médiane
  saturée à 300 pour toutes les politiques fixes, survie séparée de 2 seeds sur 12 (non
  significatif). Aucune nouvelle action ne bat `errance`.

Non-régression : `pf_er_rm` (S3=errance) reproduit M0 v1 bit à bit sur 12 seeds.

## Tripwire Phase 2 → enrichissement de l'environnement

La décision Phase 2 (option 1 retenue) avait pré-enregistré : « si M2 est également saturé sur
toutes les métriques de résultat, l'option 2 (enrichir l'environnement, invalider M0) redevient la
seule voie ». C'est le cas (env v1 saturé dans la bande haute à M1, sur le choix S3 à M2-oracle).

Probe `experiments/campaigns/p3b_env_probe.json` (`eat_hunger_threshold = 90` — Variante C,
supprime le tampon de digestion différée qui amortissait le signal — × `hunger_depletion_rate`
balayé, 6 seeds) :

| rate | meilleure fixe | vie médiane (meilleure) |
|---|---|---|
| 0,7 | pf_er_rm 0,67 | 300 (saturée) |
| **0,9** | pf_er_rm / pf_rm_er 0,50 | 242-282 (décollée) |
| 1,1 | 0,17 (effondrement) | 203 |
| 1,3 | 0,00 | 151 |

Point retenu : **`hunger_depletion_rate = 0,9`, `eat_hunger_threshold = 90`**, reste identique.
Gelé dans `experiments/apprentissage_env_ref_v2.json`. **Rupture de comparaison M0 v1 → Mf v1
assumée** (risque principal de la roadmap) : remplacée par M0 v2 → Mf v2.

## M0 v2 — nouvel « avant » (env v2, 12 seeds)

`experiments/campaigns/benchmark_apprentissage_m0_v2.json` :

| bras | survie | vie médiane | mûres |
|---|---|---|---|
| aleatoire | 0,58 | 300 | 12,4 |
| pf_rm_er (= politique_fixe_max_v1 v2) | 0,58 | 300 | 11,25 |
| adaptatif_v1 | 0,50 | 276 | 11,8 |
| pf_rm_rm | 0,50 | 271 | 10,0 |
| pf_er_rm | 0,25 | 197 | 6,1 |
| automate | 0,08 | 176 | 5,8 |
| pf_er_er | 0,00 | 128 | 1,9 |

L'enrichissement décomprime la survie (0,00 → 0,58, contre 0,17 → 0,83 en v1). La meilleure
politique fixe **bascule** de `pf_er_rm` (v1) à `pf_rm_er` (v2). `automate` s'effondre à 0,08.
Réserve conservée : la vie médiane reste saturée à 300 dès que survie ≥ 0,5 (couple survie/mort +
horizon fixe) — métriques de résultat exploitables : **survie et mûres mangées**. Et `aleatoire`
(0,58) égale la meilleure politique fixe et dépasse `adaptatif_v1` (0,50) — le learner gelé fait
moins bien que l'aléatoire, comme en v1.

## M1 v2 — décideur adaptatif (Phase 2 + Phase 3) sur env v2

`experiments/campaigns/benchmark_apprentissage_m1_v2.json` :

| bras | survie | vie médiane | mûres | part ≥2 actions |
|---|---|---|---|---|
| **adaptatif_courant** | **0,67** | 300 | **12,9** | 1,00 |
| aleatoire | 0,58 | 300 | 12,4 | — |
| pf_rm_er | 0,58 | 300 | 11,25 | — |
| adaptatif_v1 | 0,50 | 276 | 11,8 | — |
| automate | 0,08 | 176 | 5,8 | — |

Non-régression : 48/48 cellules bras gelés reproduisent M0 v2 bit à bit.

Gates Phase 3 sur env v2 :
- (a) : `adaptatif_courant` part multi-action = **1,00** (contre ~37 % avant). Acquis.
- (b) : **oui** sur env v2 — `cap_maintenu` (0,50) vs `demi_tour` (0,17) = 9-1/12 ;
  `zone_inconnue` (0,42) vs `demi_tour` = 9-1/12. Les nouvelles actions ne sont pas cosmétiques.
  Réserve : aucune ne bat `errance` (0,58) en politique fixe.

Tests des signes appariés au seed, `adaptatif_courant` champion (victoires-défaites, nuls) :

| vs | survie | vie | mûres mangées |
|---|---|---|---|
| aleatoire | 4-3 (5) | 5-3 (4) | 4-6 (perd) |
| adaptatif_v1 | 3-1 (8) | 4-3 (5) | 6-5 |
| pf_rm_er | 1-0 (11) | 3-2 (7) | 7-5 |

`adaptatif_courant` est le meilleur bras en agrégat mais **ne se sépare d'aucune référence** au
seed apparié. L'écart 0,67 vs 0,58 = un seul seed sur 12. Face à l'aléatoire, pile ou face sur la
survie, défaite sur les mûres.

## Verdict — branche « Échec » du critère écrit à l'avance

Critère de succès de la roadmap (section Benchmark, écrit avant la première mesure) :
- Succès : bat `adaptatif_v1` **et** `automate` sur ≥ 9/12. → bat `automate` (0,67 vs 0,08),
  **ne bat pas `adaptatif_v1`** (3-1/12, 8 nuls).
- **Échec : « ne bat pas `adaptatif_v1`. La roadmap n'a rien produit de mesurable ; suspendre
  l'axe apprentissage plutôt que lancer une v3. »** — c'est ce cas.
- « Si M1, M2 et M3 sont plates, inutile d'attendre Mf pour le savoir. » — M1 v2 est plate.

Confirme le diagnostic §4 de la roadmap : ~1 bit apprenable par vie, la variance inter-seed
l'écrase. Trois phases (signal événementiel, amorçage TD, espace d'action ×5) font passer le
learner de « sous l'aléatoire » à « à égalité statistique avec l'aléatoire ». La tâche ne
récompense pas assez une politique de déplacement apprise pour qu'une table discrète batte le
hasard.

## Décision

1. **Suspendre l'axe apprentissage individuel.** Ne pas exécuter M2 v2 / M3 ni les Phases 4-5.
2. **Conserver le code Phases 2-3** : signal événementiel + amorçage TD (correct, plus propre que
   la moyenne mobile de variation de faim), espace d'action S3 élargi (gates (a) et (b) passés sur
   env v2, actions non cosmétiques). Aucune raison de revenir en arrière.
3. **Ne pas engager la Phase 6** (approximation de fonction linéaire). C'est le seul levier non
   essayé, mais le prior est faible : si une table discrète ne bat pas l'aléatoire avec un signal
   propre et un espace d'action large, le continu ne créera pas une politique là où il n'y en a
   pas. À rouvrir seulement sur décision explicite.
4. **Ne pas supprimer `scripts/adaptive_decider_v1.gd`** pour l'instant (la roadmap le prévoyait à
   la clôture) : le garder tant que la suspension n'est pas confirmée comme définitive.

## Angle mort / ce qu'exigerait une reprise

- La tâche « survivre en cueillant » avec vision 15 et 30 ronces est trop peu exigeante en
  politique de déplacement : l'aléatoire suffit à frôler la meilleure politique fixe. Une reprise
  demanderait une tâche où le *choix de direction* est décisif (ressources hétérogènes, coûts de
  déplacement, dangers localisés) — c'est un changement de simulation, pas de learner.
- La vie médiane est structurellement inutilisable comme métrique de résultat (saturée dès
  survie ≥ 0,5). Seules survie et mûres discriminent, et sur un intervalle étroit.
- `souvenir_ancien` (S2) n'a pas été mesuré isolément (l'oracle S3 ne balaye que S3).

## Livrables de session (non commités — `/close`)

- Code : `scripts/adaptive_decider.gd`, `scripts/character.gd`, `scripts/fixed_policy_decider.gd`,
  `scripts/variable_registry.gd`, `tools/run_manual_checks.gd`, `tools/check_fixed_policy.py`,
  `tools/benchmark_report.py`.
- Configs : `experiments/apprentissage_env_ref_v2.json`, `experiments/p3_adaptive_selftest.json`,
  `experiments/p3b_env_probe.json`, `experiments/campaigns/{p3_oracle,p3b_env_probe,
  benchmark_apprentissage_m0_v2,benchmark_apprentissage_m1_v2}.json`.
- Résultats : `results/_p3_oracle`, `results/_p3b_env_probe`,
  `results/_benchmark_apprentissage_m0_v2`, `results/_benchmark_apprentissage_m1_v2`.
- Décision Phase 2 (créée en session précédente, non encore dans `INDEX.md`) :
  `_docs/decisions/2026-09-01_phase2-signal-recompense-td.md`.
