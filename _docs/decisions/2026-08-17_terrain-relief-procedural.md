# Relief procédural par code plutôt que le plugin Terrain3D

**Date :** 2026-08-17
**Statut :** validé

## Décision
- Phase 4 de la roadmap graphisme (terrain/décor) : relief léger généré par bruit simplex
  (`FastNoiseLite`) et maillage procédural, plutôt que le plugin Terrain3D prévu initialement.
- Motif : Terrain3D est un GDExtension binaire tiers, dont l'usage normal passe par un éditeur
  de sculpture en scène — incohérent avec le projet, construit entièrement par code, sans
  scène éditée manuellement. Choix arbitré par l'utilisateur entre 3 options proposées
  (relief procédural, Terrain3D, décor seul sans relief).
- Décor (rochers, arbres) généré procéduralement pour la même raison, plutôt que via des
  packs CC0 externes (Kenney/Quaternius).

## Implémentation
- `scripts/main.gd` : `_terrain_height()` (bruit simplex + aplanissement en bordure de map),
  `_build_terrain_mesh()` (grille de vertices via `SurfaceTool`), `_build_terrain_collision_shape()`
  (`HeightMapShape3D` calé sur la même grille), `_build_decor()`/`_add_rock()`/`_add_tree()`.
- Personnages et ronces repositionnés dynamiquement sur la hauteur du terrain à leur spawn.

## Commentaire
Choix d'approche validé explicitement par l'utilisateur. Implémentation vérifiée sans erreur
en headless ; validation visuelle manuelle en attente (`tests_manuels.md`).
