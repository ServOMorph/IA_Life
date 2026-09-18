# Signals — ia_life (MAJ 2026-09-18)

## Actions ouvertes

- [P1|ouvert] Préparer la phase T1 après la preuve T0 v2.
  fait quand: le contrat T1 versionné définit observations, bras, seeds, tests et gate avant toute mesure.
  réf: `roadmap_apprentissage_fonctionnel_proposition.md`, `experiments/apprentissage_t0_contrat_v2.md`, `experiments/t0_v2_results.jsonl`.
- [P2|ouvert] Finaliser ou écarter le candidat v3 de contournement avant toute nouvelle campagne de danger.
  fait quand: le mécanisme a des tests verts et une campagne versionnée, ou son abandon est documenté.
  réf: `scripts/danger_detour.gd`, `experiments/campaigns/danger_zone_detour_v3.json`, `_docs/decisions/2026-09-10_contournement-stateful.md`.
- [P3|dormant] Axe danger v3 en pause pendant la Phase 2 de l'apprentissage alimentaire.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Les Phases 0 et 1 de la roadmap alimentaire sont closes : contrat T0 v2, table persistante et validateur de résultats sont en place.
- T0 v2 est complet et valide : 1 248 résultats sans doublon ni identifiant inattendu ; le gate est atteint au checkpoint 1 000.
- Contournement v2 : coût évité nul et 10/12 contre `viser`, mais 5/12 seulement contre `aleatoire` ; survie maximale 0,42. Le gate Phase 3 échoue, seeds réservés fermés.
- `IA_LIFE_HEADLESS_FIXED_FPS=60` accélère les campagnes sans changer le pas de simulation : 8/8 summaries complets identiques hors `session_id`, et 4/4 comparaisons séquentiel/parallèle identiques.
- `scripts/check_kit.py` est absent : écart connu à corriger avant la Phase 3 de la roadmap alimentaire, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des changements utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-18)

# Session du 2026-09-18

## Décisions prises
- Le gate T0 v2 est atteint ; la progression vers T1 reste soumise à un nouveau contrat préenregistré.

## Livrables produits ou modifiés
- `experiments/t0_v2_results.jsonl` : 1 248 résultats de la campagne T0 v2.
- `experiments/t0_v2_results.jsonl.workers/` : sorties isolées des neuf lignées.

## Hypothèses validées / invalidées
- VALIDE : le lot est complet et conforme ; `scripted` réussit 96/96 et `trained` 96/96 au checkpoint 1 000.
- VALIDE : chaque lignée entraînée dépasse `initial_frozen` (12/32) et `random_valid` (23-24/32) ; `reset_each_episode` reste à 12/32.

## Prochaine étape exacte
Écrire et verrouiller le contrat T1 avant toute nouvelle campagne.

## Question bloquante pour la session suivante
Aucune.
