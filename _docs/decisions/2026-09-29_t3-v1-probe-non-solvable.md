# T3 v1 — contrôle scripté sous le seuil sur entraînement

Date : 2026-09-29. Statut : invalidé avant validation ; réserves de validation fermées.

Le contrat T3 v1 a été testé uniquement sur ses 32 cartes d'entraînement. Le contrôle scripté
survit 28/32 épisodes, contre 3/32 pour la table initiale et 1/32 pour l'aléatoire. Les quatre
échecs scriptés (`390000008`, `390000019`, `390000021`, `390000027`) meurent à 50 primitives sans
cueillette ni consommation.

Le seuil de solvabilité scriptée préenregistré est 0,90, soit au moins 29/32 sur ce probe. V1 est
donc arrêté avant entraînement et avant toute lecture de validation.

## Hypothèse de diagnostic

Avec une faim initiale de 50 et une déplétion de 4,0/s, un agent dispose de 12,5 secondes avant la
mort. Sur les quatre échecs, le contrôleur local ne rencontre aucune ressource dans ce délai. La
première hypothèse à tester est une couverture perceptive insuffisante à 25 m, pas un défaut de
consommation : les 28 autres cartes produisent 108 repas et les tests verrouillés couvrent les
repas non terminaux.

Un seul probe comparatif est autorisé sur les mêmes cartes d'entraînement : portée de vision 40 m,
tous les autres paramètres v1 inchangés. Si le scripté atteint au moins 29/32 sans saturation de
l'aléatoire, un contrat v2 utilisera de nouvelles réserves. Sinon, il faudra revoir l'horizon ou la
pression de faim dans une nouvelle hypothèse, sans ouvrir la validation v1.

Le comparatif atteint 29/32 pour le scripté, 3/32 pour l'initial et 1/32 pour l'aléatoire. Le
contrat T3 v2 est donc gelé avec une portée de 40 m et les nouvelles réserves `400...` avant tout
probe ou entraînement v2.
