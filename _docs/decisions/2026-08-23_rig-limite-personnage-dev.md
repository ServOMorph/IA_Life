# Rig limité au personnage de développement

Date : 2026-08-23
Statut : validé

## Décision

Le modèle riggé assets/models/character.glb et ses animations Idle, Walk et Death restent
réservés au personnage de test du mode développement.

## Motif

Les quatre agents normaux conservent une représentation légère afin que le travail
graphique ne ralentisse pas la reproductibilité, les campagnes headless et l'étude des
comportements émergents.

## Conséquence

Toute extension future du rig aux agents normaux nécessite une nouvelle décision et une
validation dédiée des collisions, couleurs, hauteurs terrain et animations.
