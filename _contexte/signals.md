# Signals — ia_life (MAJ 2026-09-30)

## Actions ouvertes

- [P1|ouvert] Décider de la suite de la confirmation T3 v3 : contrat de confirmation v2 ou arrêt de l'axe alimentaire.
  fait quand: un contrat v2 est gelé (nouvelles cartes et graines, solvabilité définie sur un échantillon dédié, seuil de survie 0,60 tranché) ou l'arrêt est consigné.
  réf: `_docs/decisions/2026-09-30_t3-v3-confirmation-critere-non-atteint.md`, `experiments/apprentissage_t3_confirmation_contrat_v1.md`.
- [P2|ouvert] Réaliser la démonstration fenêtrée du décideur `politique_apprise` sur le bureau virtuel IA_Life.
  fait quand: les 4 contrôles de la section Phase 5 de `tests_manuels.md` sont validés et la section supprimée.
  réf: `tests_manuels.md`, `run_applied_demo.py`, `experiments/t3_applied_demo_v1.json`.
- [P2|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; non traité en Phase 5.
- [P3|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P4|dormant] Axe danger v3 en pause pendant l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Confirmation T3 v3 : critère non atteint (7/8). `trained` 201/320 (0,628), initial 40/320, aléatoire 31/320, reset 37/320 ; scripté 280/320 (0,875 < 0,90). Gel commité `c31c0520`.
- Les cartes finales `410000201..264` sont consommées ; le lot ne peut ni être rejoué ni servir à choisir un correctif.
- Généralisation inférieure à la validation (0,72 en essai à blanc) ; marge de 0,028 sur le seuil de 0,60.
- Le décideur `politique_apprise` est livré et testé (équivalence d'actions, repli, figé) mais non validé statistiquement.
- Les modifications ROBERTO/com_telephone, `AGENTS.md`, `GEMINI.md`, `.claude/CLAUDE.md` et `.claude/commands/roberto.md` du working tree ne font pas partie de cette clôture.

## Dernière session (2026-09-30)

# Session du 2026-09-30

## Décisions prises
- Phase 5 exécutée : contrat de confirmation T3 v3 gelé (commit `c31c0520`) puis lot final unique lancé.
- Résultat consigné : critère non atteint (7 critères sur 8) ; aucune requalification ni nouvelle exécution.

## Livrables produits ou modifiés
- `experiments/apprentissage_t3_confirmation_contrat_v1.md`, outillage `tools/*t3_confirmation*` : gel, lanceur, validateur, analyse, rejeu.
- `scripts/t3_applied_controller.gd`, `character.gd`, `main.gd`, `variable_registry.gd` : décideur `politique_apprise` ; `tools/t3_delivery_tests.gd` : tests verts.
- Résultats, analyse et rejeux du lot final et de l'essai à blanc dans `experiments/` ; décision et index mis à jour.

## Hypothèses validées / invalidées
- VALIDE : l'apprentissage améliore la survie dans les 5 lignées indépendantes (gain 0,47 à 0,56) ; l'ablation par remise à zéro ne le rattrape pas.
- INVALIDE : le gate de confirmation complet (solvabilité scriptée 0,875 sous 0,90).
- EN ATTENTE : cause de l'écart de solvabilité (variation de tirage de cartes, non établie) et démonstration fenêtrée.

## Prochaine étape exacte
Décider entre un contrat de confirmation v2 avec nouvelles cartes et graines, ou l'arrêt ; faire ensuite la démonstration fenêtrée.

## Question bloquante pour la session suivante
Le seuil de survie de 0,60 est-il un objectif réaliste pour une confirmation v2, sachant que la généralisation mesurée est à 0,628 ?
