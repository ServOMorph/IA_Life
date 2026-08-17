# Agrandissement de la map x4 (surface), 4 personnages/4 zones conservés

**Date :** 2026-08-16
**Statut :** validé

## Décision
La map est agrandie deux fois (MAP_SIZE 40 -> 80 -> 160, soit x4 la surface à chaque
étape) tout en conservant exactement 4 personnages, un par zone/quadrant. Une tentative
intermédiaire de passer à une grille 2x4 (8 carrés) a été explicitement écartée par
l'utilisateur au profit du maintien à 4 personnages.

## Implémentation
- `scripts/main.gd` : `MAP_SIZE := 160.0`, spawn aux centres de zone `(±40, ±40)`,
  caméra repositionnée en `(0, 60, 80)`.
- `scripts/character.gd` : clamp de déplacement scindé en `map_half_x` / `map_half_z`
  (refactor conservé bien que la map soit restée carrée).

## Commentaire
Validé par test manuel en jeu le 2026-08-17.
