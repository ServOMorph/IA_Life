# Signals — ia_life (MAJ 2026-09-24)

## Actions ouvertes

- [P1|ouvert] Décider du pivot de la Phase 2 après les échecs T0 v2 et v3.
  fait quand: une hypothèse de remplacement est écrite et un contrat versionné est gelé, ou T0 est explicitement abandonné.
  réf: `roadmap_apprentissage_fonctionnel_proposition.md` (Phase 2), `_docs/decisions/2026-09-19_gate-t0-non-atteint.md`, `_docs/decisions/2026-09-24_t0-v3-gate-non-atteint.md`.
- [P2|ouvert] Décider du sort du travail T1 engagé avant l'échec T0 v3.
  fait quand: l'utilisateur décide de l'écarter, de le conserver gelé ou de l'adapter à un nouveau contrat T0.
  réf: `experiments/apprentissage_t1_contrat_v1.md`, `scripts/t1_scenario.gd`, `scripts/t1_q_table.gd`, `tools/t1_campaign.gd`, `_docs/decisions/2026-09-24_t0-v3-gate-non-atteint.md`.
- [P3|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P4|dormant] Axe danger v3 en pause pendant la Phase 2 de l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Les campagnes T0 v2 et v3 sont complètes et conformes (1 248 résultats chacune), mais les deux
  gates échouent contre `random_valid`. En v3 à 3 m : `trained` 0,458 contre `random_valid` 0,604 ;
  le gain est −0,146 et les trois lignées restent sous le contrôle.
- T1 demeure gelé ; les seeds de test T0 v3 et de T1 restent fermées.
- Une autre session (codex) travaille en parallèle sur ce même dépôt : au 2026-09-19, elle a des
  fichiers non commités (retrait de l'intégration ROBERTO/com_telephone, préparation T1
  — `experiments/apprentissage_t1_contrat_v1.md`, `scripts/t1_*.gd`, `scripts/rl_protocol.gd`).
  Cette session de clôture n'y touche pas ; ne pas supposer ces fichiers commités avant vérification.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `scripts/check_kit.py` est absent : écart connu à corriger avant la Phase 3 de la roadmap alimentaire, non bloquant pour les livrables applicatifs.

## Dernière session (2026-09-24)

# Session du 2026-09-24

## Décisions prises
- T0 v3 à 3 m est invalidé : il ne rend pas `trained` supérieur à `random_valid`.

## Livrables produits ou modifiés
- `experiments/apprentissage_t0_contrat_v3.md`, campagne/validateur T0 v3 et 1 248 résultats : créés.
- `_docs/decisions/2026-09-24_t0-v3-gate-non-atteint.md` : décision d'invalidation.

## Hypothèses validées / invalidées
- VALIDE : le scénario et le contrôle scripté T0 v3 sont solvables (96/96).
- INVALIDE : déplacer la ronce à 3 m suffit à créer la marge d'apprentissage requise.

## Prochaine étape exacte
Décider le pivot de la Phase 2 avant toute nouvelle campagne T0 ou reprise de T1.

## Question bloquante pour la session suivante
Aucune.
