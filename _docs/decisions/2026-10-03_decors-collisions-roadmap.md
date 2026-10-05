# Décors avec collisions : roadmap et cadrage (2026-10-03)

Statut : validé — Phases 0 à 5 terminées ; décision d'activation par défaut dans
`2026-10-03_decor_collisions_gate.md`.

## Décision

Les collisions des arbres (108) ne sont pas simplement réactivées. Elles passent par
une variable `decor_collisions` (défaut `true` après le gate de Phase 5) qui pilote aussi les futurs décors bloquants. Les
rochers gardent leur collision en permanence. Le placement des rochers suit la même règle d'exclusion
que celui des arbres (distance aux ronciers, aux points de départ et aux autres décors). Travail
planifié dans `roadmap_decor_collisions.md` (Phases 0 à 5).

## Motifs

- Les agents ne contournent aucun obstacle : l'automate fait demi-tour en errance mais, en ciblage
  de roncier, `baseline_decider.gd` recalcule la direction vers la cible à chaque image ; `llm_survie`
  abandonne après 3 s sous 0,5 m de progression et marque la cible comme bloquée. Des collisions
  mesureraient la navigation plutôt que les décisions.
- Les collisions sont voulues pour le réalisme et d'autres décors bloquants sont prévus.
- Les rochers sont déjà bloquants dans toutes les mesures passées : retirer leur collision serait
  contraire à la règle de la mémoire projet du 2026-08-17.

## Réserves

- Rupture assumée des références (automate 292 s, `llm_survie` 542 s) : le placement des rochers
  change ; nouvelle référence mesurée en Phase 5.
- Gate atteint : automate à 102,02 % et `llm_survie` à 100,84 % de la référence sans collisions ;
  zéro échec de contournement et zéro repli LLM. Détail et limites dans
  `2026-10-03_decor_collisions_gate.md`.
