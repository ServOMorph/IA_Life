# Inspecteur générique remplace les sliders dupliqués

Date : 2026-08-25
Statut : validé

## Décision

Un panneau Inspecteur unique (sélecteur d'agent + filtre par catégorie), généré depuis
`VariableRegistry.CHARACTER`, remplace les sliders Vitesse, Vieillissement, Capacité à se
nourrir et Mémoire auparavant dupliqués dans chacun des quatre panneaux de coin. Ces
panneaux ne conservent que Exploration (hors registre), la faim, l'état de vie et
l'historique. Chaque champ affiche un tag ("live", "dynamique" ou "nécessite Relancer")
selon `live_editable`/`dynamic`. Une confirmation est désormais demandée avant "Relancer".

## Motif

La roadmap (`roadmap_experimentation.md`, Phase 5) visait à permettre l'observation/réglage
sans encombrer les panneaux des quatre agents à mesure que le nombre de variables augmente.

## Conséquence

Toute variable ajoutée au registre `CHARACTER` devient disponible dans l'Inspecteur sans
code UI spécifique. Validé manuellement par l'utilisateur (tests_manuels.md, tests 15/16,
retirés après validation).
