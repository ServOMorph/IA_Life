# Mémoire cartographique de llm_survie (2026-10-02)

Statut : proposé (livré, gate d'usage non atteint, effet sur la survie non mesuré).

## Décision

Chaque agent `llm_survie` mémorise les cases de 10 m qu'il parcourt et les bords de carte qu'il a
touchés. La vue envoyée au LLM porte les bords découverts (avec distance) et l'état de chacune des
8 directions jusqu'à 30 m (explorée, partielle, inexplorée, bord). Découvrir un bord déclenche un
tour de décision. Variable `llm_survie_map_memory` (défaut actif) ; désactivée, le prompt est celui
de la v1 (campagne de la Phase 5).

## Mesure d'usage (gate fixé avant la première mesure)

`tools/check_llm_survie_map_usage.gd`, `gemma3:1b`, 12 situations, avec et sans carte :
direction inexplorée 5/8 contre 1/8 ; bord 3/4 contre 3/4. Gate (>= 6/8, 4/4, supérieur au témoin)
non atteint. Un seul ajustement de prompt (consigne explicite dans la ligne des actions) a fait
passer l'exploration de 1/8 à 5/8.

## Réserves

- Le modèle choisit encore une direction marquée bord près d'un bord.
- Aucune campagne de survie rejouée : l'effet sur la durée de vie est inconnu.
- Les runs avec carte ne sont plus comparables à la Phase 5 (mettre `llm_survie_map_memory: false`).

## Suite

Retirer du choix les directions « bord » (contrainte moteur, comme les directions bloquées), réviser
le prompt, ou accepter l'état informatif.
