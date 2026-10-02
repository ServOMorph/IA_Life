# Mémoire cartographique de llm_survie (2026-10-02)

Statut : validé (périmètre), révisé le même jour — mémoire seule, utilisée uniquement pour exclure les directions « bord » (voir Révision).

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

## Décision complémentaire (2026-10-02, validée par l'utilisateur)

- Contrainte moteur : les directions marquées « bord » par la carte sont retirées de l'énumération
  `direction` d'`explorer` dans le schéma Ollama, comme les directions bloquées
  (`LLMSurieOllamaBackend.excluded_directions`). Si les 8 directions sont exclues, le schéma retombe
  sur les 8. Test ajouté dans `tools/run_manual_checks.gd`.
- Banc rejoué après la contrainte : inexplorée 5/8 contre 1/8 ; bord 4/4 contre 3/4 (gate formel
  toujours non atteint, code inchangé). La famille « bord » est désormais garantie par construction :
  elle ne mesure plus l'usage par le LLM, seulement le bon fonctionnement de la contrainte. Elle
  n'était déjà pas discriminante (le témoin répond N dans les 12 situations).

## Révision (2026-10-02, demande de l'utilisateur) : carte sans influence stratégique

La carte ne doit pas orienter la stratégie de survie ; elle sert uniquement à empêcher le LLM de
demander une direction hors de la carte. Un usage stratégique viendra plus tard.

- Le prompt n'intègre plus la carte (section « CARTE MÉMORISÉE » et consignes d'exploration retirées) :
  il est identique à la v1, carte active ou non. `map_lines` est conservé, non injecté.
- La découverte d'un bord ne déclenche plus de tour de décision (journalisée seulement).
- Seul effet restant : l'exclusion des directions bord dans le schéma.
- Le banc `tools/check_llm_survie_map_usage.gd` mesurait l'usage de la carte dans le prompt : il est
  sans objet pour cette version (seule la famille bord, garantie par construction, diffère du témoin).
- Config de référence : la carte reste active par défaut. Son seul effet sur le comportement est
  l'exclusion des directions bord, qui n'existe pas dans les runs de la Phase 5 : une comparaison
  stricte avec la Phase 5 exige toujours `llm_survie_map_memory: false`.
