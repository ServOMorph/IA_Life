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

## Bug de culling corrigé + relief plus marqué (2026-08-17)
Le mesh de terrain généré par `SurfaceTool` avait un ordre de winding inversé : Godot le
traitait comme face arrière et le culled par défaut, le rendant invisible depuis le dessus
(seule la nappe "ground" du ciel procédural était visible en arrière-plan, confondue avec un
bug de texture). Diagnostiqué par capture d'écran automatisée (`run_screenshot.py`, nouveau)
en isolant la variable relief (test à amplitude 0). Corrigé par `render_mode cull_disabled`
sur `scripts/triplanar.gdshader`. À cette occasion, le relief a été rendu plus marqué
(`TERRAIN_AMPLITUDE` 1.2 -> 5.0, `TERRAIN_NOISE_FREQUENCY` 0.025 -> 0.045) et des cuvettes de
spawn ont été ajoutées (`_valley_offset`, rayon 20, profondeur 3.5) autour des 4 points
d'apparition des personnages.

## Commentaire
Choix d'approche validé explicitement par l'utilisateur. Bug de rendu majeur (terrain
invisible) corrigé et vérifié par capture d'écran automatisée. Validation visuelle manuelle
en jeu toujours en attente (`tests_manuels.md`), notamment l'impact du relief plus escarpé
et des cuvettes de spawn sur le déplacement des personnages.
