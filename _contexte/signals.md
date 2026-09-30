# Signals — ia_life (MAJ 2026-09-30)

## Actions ouvertes

- [P1|ouvert] Préparer la confirmation indépendante et la livraison de la Phase 5 sans ouvrir les graines finales avant gel du plan.
  fait quand: candidat et analyse sont gelés, lot final indépendant exécuté, intégration et démonstration réalisées.
  réf: `roadmap_apprentissage_fonctionnel_proposition.md` (Phase 5), `_docs/decisions/2026-09-29_t3-v3-gate-concurrence-atteint.md`.
- [P2|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; écart connu à corriger en Phase 5.
- [P3|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P4|dormant] Axe danger v3 en pause pendant l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Phase 4 terminée : T1 v5, T2 v1, T3 v2 et T3 v3 franchissent leurs gates ; les replays retenus sont stables après recharge.
- T1 v5 consomme 96/96 ; T2 v1 obtient 96/96 avec mémoire contre 12/96 sans mémoire ; T3 v2 obtient 76/96 et T3 v3 71/96 en politique entraînée.
- Les graines finales restent fermées. La Phase 5 n'est pas commencée ; `/compact` est requis au checkpoint.
- Les modifications ROBERTO/com_telephone, `AGENTS.md`, `GEMINI.md`, `.claude/CLAUDE.md` et `.claude/commands/roberto.md` présentes dans le working tree ne font pas partie de cette clôture.
- `scripts/check_kit.py` est absent : écart connu à corriger en Phase 5 ; le contrôle demandé par `/close` ne peut pas être exécuté.

## Dernière session (2026-09-30)

# Session du 2026-09-30

## Décisions prises
- La Phase 4 franchit son gate avec les validations successives T1 v5, T2 v1, T3 v2 et T3 v3.

## Livrables produits ou modifiés
- Contrats, scénarios, campagnes, analyses et replays T1 v5, T2 v1 et T3 v1–v3 produits.
- Tests de résultats, de scénarios et d'équivalence direct/bridge exécutés.
- Roadmap, décisions, contexte, README et CHANGELOG actualisés par `/close`.

## Hypothèses validées / invalidées
- VALIDE : la direction tenue résout T1 ; la mémoire explicite est causale sur T2 ; T3 passe sans puis avec concurrents.
- INVALIDE : le contrat T3 v1 à vision 25 est suffisamment solvable ; T3 v2 porte la vision à 40.
- RÉSERVE : ces résultats sont de validation ; les graines finales n'ont pas été ouvertes.

## Prochaine étape exacte
Faire `/compact`, puis engager la Phase 5 par le gel du candidat et du plan de confirmation indépendante.

## Question bloquante pour la session suivante
Aucune.
