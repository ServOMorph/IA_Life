# Durée simulée déterministe et état initial séparé

Date : 2026-08-24
Statut : validé

## Décision

Les expériences comparables sont limitées par `simulation.max_simulation_seconds`, compté
sur les ticks physiques, plutôt que par le temps mural. Les variables fixes restent sous
`agents.defaults` et `agents.individual`, tandis que les variables dynamiques de départ sont
placées sous `agents.initial_state`.

## Motif

Le temps mural varie avec la charge machine et ne garantit pas les mêmes résultats à seed
fixe. La séparation d'état évite aussi de comparer des profils fixes avec des valeurs de faim
initiales implicites ou invalides.

## Validation

`tools/check_reproducibility.py` confirme deux summaries identiques, hors `session_id`, pour
une même configuration et seed. Les contrôles manuels couvrent les valeurs par défaut,
overrides et le rejet d'une variable dynamique dans la configuration fixe.
