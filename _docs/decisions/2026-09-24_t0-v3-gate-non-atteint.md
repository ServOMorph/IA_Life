# Gate T0 v3 non atteint

Date : 2026-09-24. Statut : invalidé.

## Décision

La correction T0 v3 — ronce à 3 m, avec nouvelles seeds — n'atteint pas le gate de la Phase 2.
T1 reste gelé ; aucune nouvelle distance ou variante T0 ne sera mesurée sans hypothèse et contrat
versionnés.

## Résultats

Le lot contient 1 248 résultats conformes. `scripted` réussit 96/96. Après sélection
préenregistrée des checkpoints (1000, 200, 1000), `trained` atteint 44/96 (0,458), contre
12/96 (0,125) pour `initial_frozen` et 58/96 (0,604) pour `random_valid`.

Le gain agrégé contre l'initialisation est 0,333, mais le gain contre l'aléatoire vaut −0,146.
Chaque lignée entraînée reste sous l'aléatoire (−0,125, −0,125, −0,188) et sous le seuil absolu
de réussite de 0,90. Le gate échoue donc indépendamment de la vérification de rechargement.

## Conséquence

La distance seule n'établit pas une tâche T0 où la table surpasse l'aléatoire. La prochaine
décision doit diagnostiquer cette limite ou écarter T0 ; elle ne peut pas ouvrir T1 ni modifier
les critères après lecture de ce lot.
