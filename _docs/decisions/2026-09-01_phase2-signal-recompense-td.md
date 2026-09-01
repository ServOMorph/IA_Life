# Phase 2 v2 — Refonte du signal : récompense événementielle et amorçage TD

Date : 2026-09-01
Statut : validé (mécanisme retenu et conservé dans le code ; voir suite ci-dessous)
Roadmap : `roadmap_apprentissage_v2.md`, Phase 2
Succède à : `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md` (Phase 1, M0)
Suite : `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`
(Phase 3 + enrichissement env + **suspension de l'axe apprentissage**). Le signal
événementiel + amorçage TD est conservé dans `scripts/adaptive_decider.gd` — il franchit
le plateau sans-apprentissage — mais le learner ne bat pas la sélection aléatoire au seed
apparié même sur l'environnement enrichi ; l'axe est suspendu avant Mf.

## Ce qui a été fait

Corrige les défauts 2 et 3 du diagnostic de `roadmap_apprentissage_v2.md`.

### Récompense événementielle (`scripts/adaptive_decider.gd`)

- La récompense d'une fenêtre d'engagement n'est plus la variation de faim normalisée
  (`REWARD_HUNGER_SCALE` supprimé) mais :
  `r = PICK_REWARD * (cueillettes survenues dans la fenêtre) - survival_cost_rate * durée`,
  bornée à `[-1, 1]` (`_window_reward`).
- `PICK_REWARD = 1.0` (constante). `survival_cost_rate` (défaut 0,05) et
  `td_discount_gamma` (défaut 0,9) sont des variables par agent du `VariableRegistry`,
  transmises au décideur par `character.gd::_build_decider` pour le seul `decider_type`
  "adaptatif".
- Signal de cueillette : `berries_picked_total` ajouté à l'observation construite par
  `character.gd::_apply_decision` ; le décideur compare à sa valeur à l'ouverture de la
  fenêtre.
- Pénalité terminale inchangée dans son effet (`TERMINAL_REWARD = -1.0`, une seule fois,
  sur la dernière cellule tenue), mais sans amorçage : un état terminal n'a pas de suite.

### Amorçage par différence temporelle

- `_commit_reward` : `cible = r + td_discount_gamma * max Q(s', .)` (0 si terminal),
  puis `score += learning_rate * (cible - score)`. La moyenne mobile de la récompense
  immédiate est remplacée par cette cible amorcée.
- `s'` = situation discrétisée dans laquelle l'agent entre au moment de la reprise de
  décision ; `max Q(s', .)` porte sur ses actions valides (`_max_score`).
- Traces d'éligibilité (TD(λ)) non nécessaires : la chaîne d'états propage déjà le
  crédit sur les tests scriptés.

### Clôture de fenêtre à la sortie de la situation de faim (`_flush_pending`)

Ajout hors périmètre littéral de la roadmap, imposé par la cohérence de la récompense
événementielle : quand l'agent quitte la situation de faim exploitable (inventaire
plein après cueillette, faim remontée), la fenêtre en cours est créditée immédiatement
sur ses conséquences réelles (cueillettes faites, coût de survie écoulé), sans
amorçage. Sans cette clôture, la fenêtre restait en attente et était créditée bien plus
tard sur une durée gonflée et sans ses cueillettes : l'action qui venait de réussir
était pénalisée. Le mécanisme d'avant Phase 2 (variation de faim) masquait ce défaut
en créditant accidentellement cette fenêtre en positif (la faim avait monté).

### Versionnage du format de table

`apprentissage_table` porte `schema_version = "phase2-td-1"` (constante
`TABLE_SCHEMA_VERSION`). La Phase 4 vérifiera ce tag au chargement d'une table amorcée.

### Bras gelé

`scripts/adaptive_decider_v1.gd` n'est pas modifié. `FixedPolicyDecider` (partagé par
héritage) neutralise les nouvelles signatures (`_apply_online_reward`, `_commit_reward`,
`_flush_pending` -> `pass`).

## Tests

- `tools/run_manual_checks.gd` : réécriture de `_test_adaptive_online_reward`, ajout de
  `_test_adaptive_credit_assignment_approach` (une approche en S1 terminée par une
  cueillette rend la cellule (S1, ronce_visible) positive — nulle ou négative avant),
  `_test_adaptive_td_bootstrap` (une fenêtre sans repas hérite de `gamma * max Q(s')`),
  `_test_adaptive_flush_on_hunger_exit`. `SUCCÈS`.
- `tools/check_reproducibility.py experiments/p2_adaptive_selftest.json` : `REPRODUCTIBLE`.
- Non-régression du bras gelé : `adaptatif_v1`, `automate`, `aleatoire`, `pf_er_rm`
  rejoués aux 12 seeds d'entraînement à M1 reproduisent leur trace M0 **bit à bit**
  (comportement) — l'ajout de `berries_picked_total` à l'observation n'a rien perturbé.
- `tools/check_adaptive_v1_equivalence.py` diverge désormais pour toute config
  "adaptatif" (attendu : le learner a changé). Ce test ne compare plus `adaptatif` à
  `adaptatif_v1` mais reste utilisable inversé (V1 vs sa trace M0).

## Mesure M1

Campagne `experiments/campaigns/benchmark_apprentissage_m1.json` (mêmes 12 seeds
d'entraînement que M0, environnement gelé `apprentissage_env_ref.json`, 60 runs).
Rapport : `results/_benchmark_apprentissage_m1/m1_report.json`.

| Bras | Survie | Vie médiane | Mûres mangées (moy.) |
|---|---|---|---|
| **adaptatif_courant** | **1,00** (12/12) | 300 (max) | **9,5** |
| aleatoire | 0,92 (11/12) | 300 | 9,2 |
| adaptatif_v1 | 0,83 (10/12) | 300 | 8,6 |
| pf_er_rm (= politique_fixe_max_v1) | 0,83 (10/12) | 300 | 7,8 |
| automate | 0,50 (6/12) | 269 | 5,2 |

Tests des signes appariés au seed, `adaptatif_courant` vs référence (victoires /
défaites / égalités sur 12) :

| vs | survie | vie | mûres mangées |
|---|---|---|---|
| aleatoire | 1 / 0 / 11 | 1 / 0 / 11 | 2 / 0 / 10 |
| adaptatif_v1 | 2 / 0 / 10 | 2 / 0 / 10 | 3 / 2 / 7 |
| pf_er_rm | 2 / 0 / 10 | 2 / 0 / 10 | 5 / 1 / 6 |
| automate | 6 / 0 / 6 | 6 / 0 / 6 | 10 / 1 / 1 |

## Lecture du gate Phase 2

Gate : « les deux tests d'attribution du crédit passent, **et** `adaptatif_courant` bat
`aleatoire` **et** `adaptatif_v1` sur ≥ 9 seeds sur 12 (métrique de résultat), **sans
être pire** que `politique_fixe_max_v1` ».

- Tests d'attribution du crédit : **passent** (2/2).
- Pas pire que `politique_fixe_max_v1` : **oui** — strictement meilleur (1,00 vs 0,83,
  zéro défaite sur 12 seeds, toutes métriques).
- Bat `aleatoire` et `adaptatif_v1` en **agrégat** sur toutes les métriques de résultat
  et **ne perd aucun seed** — mais **pas « sur ≥ 9 seeds sur 12 »** au sens du test des
  signes apparié strict (1 à 3 victoires, 7 à 11 égalités).

Cause : la survie **et** la vie médiane sont **saturées au plafond** dans
l'environnement gelé (`adaptatif_courant` : 12/12 survie, 12/12 vie à 300 s ; 0 mort,
donc la pénalité terminale ne s'exerce jamais à M1). Le test des signes « strictement
meilleur sur ≥ 9/12 » est structurellement inatteignable en régime saturé, quelle que
soit la qualité du learner. Aucune métrique de résultat (survie, vie, mûres mangées) ne
discrimine sur cette base.

C'est le scénario anticipé par l'action `P2|surveillance` de `signals.md`
(« la bande utile est étroite en haut ; les métriques secondaires devront porter la
comparaison »). Ici les métriques secondaires sont saturées elles aussi.

## Ce que la Phase 2 a produit de mesurable

- La refonte du signal fait passer `adaptatif_courant` de 0,83 (= `adaptatif_v1`) à
  **1,00** de survie : il franchit le plafond `aleatoire` (0,92, meilleur bras M0) et
  devient le bras unique en tête sur toutes les métriques de résultat, dominant seed
  par seed.
- L'action utile n'est plus systématiquement pénalisée pendant son exécution
  (récompense événementielle + `_flush_pending`).

## Angle mort / réserve

Les tables apprises restent **bruitées et incohérentes entre seeds** : en S1
(roncier visible), l'action au meilleur score est tantôt `ronce_visible`, tantôt
`ronce_memorisee` (contradictoire) ; 2 seeds sur 12 laissent toutes les cellules S1
négatives. Le gain agrégé ne vient pas d'une politique apprise nette mais d'un signal
moins trompeur dans un environnement très permissif. Défaut 4 du diagnostic (une vie
ne fournit pas assez d'échantillons) non traité — c'est l'objet des Phases 3-4.

## Blocage pour la suite

L'environnement gelé n'a plus assez de dynamique dans ses métriques de résultat pour
faire tourner le test pré-enregistré du gate. Les Phases 3-5 ont des gates de même
nature (métrique de résultat) : si survie et vie médiane restent saturées, aucun de
ces gates ne pourra passer proprement. Décision utilisateur requise (c'est le risque
principal de la roadmap) :

1. Lire le gate comme franchi sur l'intention (learner au plafond, dépasse le plateau
   sans-apprentissage, domination seed-par-seed sans défaite), acter succès partiel,
   passer à la Phase 3 ; consigner que la métrique de gate bascule sur « domination
   seed-par-seed sans défaite + agrégat » pour M2..Mf.
2. Constater que l'environnement gelé ne discrimine plus et l'enrichir (survie plus
   dure) avant les Phases 3-5 — mais cela touche l'environnement gelé depuis la Phase 1
   et invalide la comparaison à M0.

### Décision retenue (2026-09-01, utilisateur)

**Option 1.** Gate Phase 2 lu comme franchi sur l'intention. Succès partiel acté.
Passage à la Phase 3 autorisé après `/compact`.

Modification du critère de gate pour M2..Mf, datée et justifiée ici (le critère
original ci-dessus reste visible) : `adaptatif_courant` doit **dominer seed par seed
sans aucune défaite** sur la métrique de résultat considérée, **et** être en tête en
agrégat, face à `aleatoire` et `adaptatif_v1`. La clause « strictement meilleur sur
≥ 9 seeds sur 12 » est abandonnée tant que survie et vie médiane restent saturées au
plafond dans l'environnement gelé. Tripwire : si M2 est également saturé sur toutes
les métriques de résultat, l'option 2 (enrichir l'environnement, invalider M0)
redevient la seule voie et devra être tranchée à ce moment.
