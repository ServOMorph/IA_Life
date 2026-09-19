# Gate T0 v2 non atteint (correction du 2026-09-18)

Date : 2026-09-19. Statut : invalidé — la clôture du 2026-09-18 avait déclaré le gate atteint.

## Décision

Le gate T0 v2 (Phase 2 de `roadmap_apprentissage_fonctionnel_proposition.md`) n'est pas atteint.
Le critère « gain d'au moins 0,30 contre `random_valid` » échoue, sur les mêmes 1 248 résultats
que ceux ayant servi à la clôture précédente (`experiments/t0_v2_results.jsonl`).

## Justification

Recalcul direct sur le fichier de résultats :

- Agrégé (96 paires) : `trained`@checkpoint 1000 = 1,000, `random_valid` = 0,729 (70/96), gain =
  0,271 < 0,30.
- Par lignée d'initialisation (32 paires chacune) : gain de 0,281 (310001001), 0,250 (310001002)
  et 0,281 (310001003) contre `random_valid` — les trois sous le seuil.

Le reste du gate (réussite ≥ 0,90, gain ≥ 0,30 contre `initial_frozen`, conservation après
recharge via `reset_each_episode`) est confirmé correct.

La cause structurelle probable : le contrat v2 rapproche la ronce à 2 m pour éviter la rareté du
signal en v1 (8 m), mais cette distance rend `random_valid` déjà performant (0,729) par simple
proximité, ce qui plafonne mathématiquement le gain atteignable pour `trained` (déjà à 1,000) sous
le seuil requis. Une calibration complémentaire de `random_valid` seul (sans entraînement, seeds
310000301-332, hors seeds de validation verrouillés) donne 0,73 à 2 m, ~0,31-0,47 à 3 m, ~0,22 à
4 m et ~0,09 à 5-6 m (3 seeds RNG testés à 3 m). Une distance de l'ordre de 3 m dégagerait une
marge confortable sans revenir à la rareté du contrat v1.

## Conséquences

- La roadmap repasse Phase 2 en `[EN COURS]` ; le statut global n'est plus `[EN ATTENTE —
  confirmation avant Phase 3]`.
- Aucun contrat T0 v3 n'est rédigé ni verrouillé à ce jour ; la distance candidate (3 m) est une
  piste de calibration, pas une valeur figée.
- Le travail T1 déjà engagé (`experiments/apprentissage_t1_contrat_v1.md`,
  `scripts/t1_scenario.gd`, `scripts/t1_q_table.gd`, `tools/t1_campaign.gd`, etc., non commités au
  moment de cette décision) repose sur la prémisse que la Phase 2 était close ; cette prémisse ne
  tient plus et doit être réexaminée par la session qui porte ce travail.
