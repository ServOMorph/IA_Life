# Déplacement des personnages sur toute la map + rebond aux collisions

**Date :** 2026-08-16
**Statut :** validé

## Décision
Les personnages doivent pouvoir se déplacer sur toute la surface de la map (jusqu'aux murs),
au lieu d'être cantonnés à une zone réduite en son centre. Au contact d'un mur ou d'un autre
personnage, le personnage repart en arrière (inversion de la direction de déplacement) au
lieu de repartir dans une direction aléatoire.

## Implémentation
- `scripts/character.gd` : sur collision (`get_slide_collision_count() > 0`), la direction est
  inversée (`_direction = -_direction`) au lieu d'être retirée au hasard.
- `scripts/main.gd` : `map_half_size` élargi pour se rapprocher de la face intérieure des murs.

## Commentaire
Validé par test manuel en jeu le 2026-08-17.
