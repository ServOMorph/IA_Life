# Signals — ia_life (MAJ 2026-09-10)

## Actions ouvertes

- [P1|ouvert] Décider la suite de l'axe danger : mécanisme de contournement stateful, ou abandon de l'axe.
  fait quand: décision utilisateur consignée et, si retenue, nouvelle mécanique et campagne versionnées avant tout accès aux seeds réservés.
  réf: `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`, `roadmap_environnement_apprenable_v3.md` (Phase 3).
- [P3|dormant] Axe apprentissage v2 suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT] et gate réservé Phase 4 passé.
  réf: `roadmap_environnement_apprenable_v3.md`, `roadmap_apprentissage_v2.md`.

## Contexte chaud

- Le placement `approche_roncier` est déterministe, couvre 12/12 zones sur les 12 seeds de calibration et préserve le placement aléatoire historique. Sa calibration v2 (192 runs) ne passe aucun point du gate causal ; les 1 728 zones demandées sont toutes posées.
- La portée de réaction 10/12/15 m (144 runs) ne passe aucun gate. La fuite rectiligne détourne l'agent de la ressource sans lui fournir de contournement ; augmenter la portée aggrave même la survie d'`eviter` à 12 m et 15 m. Ne plus faire de balayage numérique sur ce mécanisme.
- Les seeds réservés n'ont jamais été ouverts. Aucun raccord du danger au learner n'est autorisé.
- `scripts/check_kit.py` est absent : écart connu de la procédure `/close`, non bloquant pour les livrables applicatifs.
- `AGENTS.md` et `GEMINI.md` sont des résidus utilisateur hors périmètre, non inclus au commit.

## Dernière session (2026-09-10)

# Session du 2026-09-10

## Décisions prises
- Le placement sur approche de roncier est validé ; la fuite rectiligne est invalidée comme réponse suffisante au danger pour créer une tâche apprenable.

## Livrables produits ou modifiés
- `approche_roncier` : placement déterministe, télémétrie, smoke et sweep de seeds.
- Campagnes v2 de placement et de portée de réaction : exécutées sur les seeds de calibration.

## Hypothèses validées / invalidées
- VALIDE : 1 728/1 728 zones de la campagne v2 sont placées.
- INVALIDE : augmenter la portée de réaction suffit à faire battre `aleatoire` par `eviter`.
- EN ATTENTE : un contournement stateful peut-il créer la séparation causale exigée ?

## Prochaine étape exacte
Demander la décision entre un contournement stateful et l'abandon de l'axe danger ; ne pas ouvrir les seeds réservés avant un gate de calibration franchi.

## Question bloquante pour la session suivante
Faut-il implémenter un contournement stateful ou abandonner l'axe danger ?
