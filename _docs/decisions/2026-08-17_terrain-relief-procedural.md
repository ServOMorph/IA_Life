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
invisible) corrigé et vérifié par capture d'écran automatisée.

Validation manuelle en jeu (2026-08-17) : relief, aplanissement en bordure de murs,
cuvettes de spawn, position des ronces/rochers/arbres sur le relief, absence de blocage
sur les pentes — tous confirmés OK par l'utilisateur. Clignotement de la texture d'herbe
(bug connu documenté dans `tests_manuels.md`) : non reproduit, considéré résolu.

Bug détecté : les personnages suivent bien la hauteur du terrain en déplacement mais
restent visuellement enfoncés dans le sol. Reporté dans `tests_manuels.md` (section "Bug
connu — enfoncement des personnages dans le sol"), correctif non encore fait.

Bug détecté et corrigé (2026-08-17) : malgré l'augmentation de luminosité de la session
précédente, la scène ressemblait à une scène de nuit (ciel orange sombre, terrain terne).
Correctif dans `scripts/main.gd` (`_build_environment`, `_build_light`) : ciel bleu clair
au lieu d'orange (`sky_top_color`/`sky_horizon_color`/`ground_horizon_color`),
`sun_angle_max` 30 -> 50, lumière plus haute et plus intense (`rotation_degrees.x` -50 ->
-65, `light_energy` 2.2 -> 3.0), `tonemap_exposure` 1.6 -> 2.0. Vérifié par capture d'écran
automatisée (`run_screenshot.py`) avant/après.
