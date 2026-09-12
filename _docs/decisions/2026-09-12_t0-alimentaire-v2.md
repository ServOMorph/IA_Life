# T0 alimentaire v2

Date : 2026-09-12. Statut : validé pour la campagne T0.

## Décision

La micro-tâche alimentaire T0 utilise une ronce à 2 m de Rouge, au lieu de 8 m. La récompense
reste exclusivement la cueillette réelle par `try_pick_berry_from_ronce` ; aucune récompense de
distance ni macro-action n'est ajoutée.

## Justification

Le contrat v1 imposait à une table Q initialement nulle de découvrir une longue séquence de
directions avant son premier retour positif. Cette exploration est inadaptée au budget de
1 000 épisodes. La v2 conserve huit directions, 15 ticks physiques à 1/60 s et toutes les
comparaisons préenregistrées, mais rend le premier succès accessible sans changer sa nature.

## Conséquences

`experiments/apprentissage_t0_contrat_v2.md` remplace v1 avant toute mesure. Le scénario et les
lignées sont exécutables en processus Godot isolés, avec `game_speed = 1`. La campagne complète
reste à lancer ; aucun gain d'apprentissage n'est établi.
