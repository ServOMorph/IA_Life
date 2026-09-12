# Signals — ia_life (MAJ 2026-09-12)

## Actions ouvertes

- [P1|ouvert] Réexécuter puis analyser la campagne T0 v2 en processus isolés après correction de l'évaluation figée.
  fait quand: les 1 248 résultats attendus sont complets, validés sans doublon et le gate T0 est conclu.
  réf: `experiments/apprentissage_t0_contrat_v2.md`, `tools/run_t0_campaign.py`, `tools/t0_results.py`.
- [P2|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P3|dormant] Axe danger v3 en pause pendant la Phase 2 de l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Les Phases 0 et 1 de la roadmap alimentaire sont closes : contrat T0 v2, table persistante et validateur de résultats sont en place.
- T0 v2 conserve la récompense de cueillette réelle et rapproche la ronce à 2 m ; une première exécution a échoué avant agrégation car l'évaluation modifiait la table.
- L'évaluation T0 ne crée plus de cellule Q ni ne modifie le RNG ; les lanceurs Godot utilisent `--log-file` dans `logs/` pour éviter l'échec sur `user://logs`.
- Une exécution T0 à l'horizon prend 11,92 s réelles et environ 24 Mo statiques ; `tools/run_t0_campaign.py --jobs 3` sépare les neuf lignées sans modifier `game_speed`.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `IA_LIFE_HEADLESS_FIXED_FPS=60` accélère les campagnes sans changer le pas de simulation : 8/8 summaries complets identiques hors `session_id`, et 4/4 comparaisons séquentiel/parallèle identiques.
- `scripts/check_kit.py` est absent : écart connu à corriger avant la Phase 3 de la roadmap alimentaire, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des changements utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-12)

# Session du 2026-09-12

## Décisions prises
- Aucun paramètre ni critère expérimental T0 n'est modifié : le correctif restaure seulement l'invariant d'évaluation figée.

## Livrables produits ou modifiés
- `scripts/t0_q_table.gd` : sélection figée sans écriture de RNG ni création de cellule Q.
- `tools/t0_campaign.gd` et lanceurs T0 : échec explicite des lignées et journaux Godot redirigés dans `logs/`.
- `tools/t0_transition_tests.gd` : régression de l'évaluation après entraînement ajoutée.

## Hypothèses validées / invalidées
- VALIDE : l'évaluation T0 préserve désormais le checksum de la table ; tests de transitions, scénario et plan Python passent.
- INVALIDE : l'implémentation précédente de l'évaluation était figée ; elle modifiait le RNG et créait des états Q absents.
- EN ATTENTE : la table persistante atteint-elle le gate T0 sur les 96 validations ?

## Prochaine étape exacte
Exécuter `python tools/run_t0_campaign.py --output experiments/t0_v2_results.jsonl --jobs 3`, puis valider et conclure le gate T0 sur le lot complet.

## Question bloquante pour la session suivante
Aucune.
