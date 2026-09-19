# Signals — ia_life (MAJ 2026-09-19)

## Actions ouvertes

- [P1|ouvert] Décider de la correction du contrat T0 (distance de la ronce) avant toute reprise de Phase 2 ou de T1.
  fait quand: un contrat T0 v3 (ou une justification de rester en v2) est rédigé et verrouillé, avec une campagne complète concluante sur le gate.
  réf: `roadmap_apprentissage_fonctionnel_proposition.md` (Phase 2), `_docs/decisions/2026-09-19_gate-t0-non-atteint.md`, `experiments/apprentissage_t0_contrat_v2.md`.
- [P2|ouvert] Réexaminer le travail T1 déjà engagé (non commité au 2026-09-19) à la lumière du gate T0 non atteint.
  fait quand: la session portant T1 a lu `_docs/decisions/2026-09-19_gate-t0-non-atteint.md` et décidé de poursuivre, geler ou adapter ce travail.
  réf: `experiments/apprentissage_t1_contrat_v1.md`, `scripts/t1_scenario.gd`, `scripts/t1_q_table.gd`, `tools/t1_campaign.gd`, `_docs/decisions/2026-09-18_interface-entrainement-tcp.md`.
- [P3|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P4|dormant] Axe danger v3 en pause pendant la Phase 2 de l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Le gate T0 v2 (Phase 2) n'est PAS atteint, contrairement à la clôture du 2026-09-18 : gain
  `trained`@1000 contre `random_valid` = 0,271 agrégé (0,25-0,28 par lignée), sous le seuil de 0,30.
  Reste correct : réussite ≥ 0,90, gain ≥ 0,30 contre `initial_frozen`, conservation confirmée.
- Calibration complémentaire (aléatoire seul, hors seeds de validation) : `random_valid` passe de
  0,73 à 2 m à ~0,31-0,47 à 3 m, ~0,22 à 4 m, ~0,09 à 5-6 m. 3 m est une piste, pas un contrat verrouillé.
- `tools/t0_campaign.gd` et `scripts/t0_scenario.gd` exposent désormais un mode `--calibrate-random <distance> <rng_seed>` pour ce type de mesure (32 seeds dédiés 310000301-332, hors seeds réservés).
- Une autre session (codex) travaille en parallèle sur ce même dépôt : au 2026-09-19, elle a des
  fichiers non commités (retrait de l'intégration ROBERTO/com_telephone, préparation T1
  — `experiments/apprentissage_t1_contrat_v1.md`, `scripts/t1_*.gd`, `scripts/rl_protocol.gd`).
  Cette session de clôture n'y touche pas ; ne pas supposer ces fichiers commités avant vérification.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `scripts/check_kit.py` est absent : écart connu à corriger avant la Phase 3 de la roadmap alimentaire, non bloquant pour les livrables applicatifs.

## Dernière session (2026-09-19)

# Session du 2026-09-19

## Décisions prises
- Correction : le gate T0 v2 n'est pas atteint (gain contre `random_valid` sous le seuil de 0,30) ; la clôture du 2026-09-18 est invalidée sur ce point.

## Livrables produits ou modifiés
- `scripts/t0_scenario.gd`, `tools/t0_campaign.gd` : mode de calibration `--calibrate-random` (distance paramétrable, seeds dédiés), sans changer le comportement des lignées T0 existantes.
- `_docs/decisions/2026-09-19_gate-t0-non-atteint.md` + `_docs/decisions/INDEX.md` : décision d'invalidation.
- `roadmap_apprentissage_fonctionnel_proposition.md`, `_contexte/contexte.md`, `_contexte/signals.md`, `_contexte/archive_sessions.md`, `_contexte/archive_decisions.md`, `README.md`, `CHANGELOG.md` : statut Phase 2 corrigé.

## Hypothèses validées / invalidées
- INVALIDE : « le gate T0 v2 est atteint » (clôture 2026-09-18) — le gain contre `random_valid` est sous le seuil requis, agrégé et pour chacune des 3 lignées.
- EN ATTENTE : une distance de ronce ~3 m (au lieu de 2 m) suffit-elle à dégager la marge de 0,30 sur une campagne complète ? Seule une calibration `random_valid` seul (3 seeds RNG, sans entraînement) a été faite.

## Prochaine étape exacte
Décider (P1) : rédiger et verrouiller un contrat T0 v3 (distance candidate ~3 m) avant toute nouvelle campagne complète, ou trancher autrement.

## Question bloquante pour la session suivante
Aucune.
