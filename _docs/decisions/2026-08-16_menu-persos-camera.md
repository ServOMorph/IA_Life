# Menu bas d'écran, panneaux persos par coin, focus caméra au clic

**Date :** 2026-08-16
**Statut :** validé

## Décision
Une barre de menu en bas d'écran liste les 4 personnages (nom coloré). Cliquer sur un nom
ouvre/ferme un panneau dans un coin d'écran dédié à ce personnage (cumulable, jusqu'à 4
simultanés), affichant ses stats en direct et des sliders pour modifier `move_speed` et la
zone de déplacement (`map_half_x`/`map_half_z`) en temps réel. Le même clic recentre aussi
la caméra sur le personnage en vue plongeante ("plan hélicoptère").

## Implémentation
- `scripts/ui_manager.gd` (nouveau) : menu bas, panneaux par coin, sliders, mise à jour
  des textes en `_process`.
- `scripts/free_camera.gd` : `focus_on(target)` positionne la caméra au-dessus de la
  cible et la fait regarder vers elle.
- `scripts/main.gd` : construction de la liste `{node, name, color, corner}` et appel
  `_build_ui`.

## Commentaire
Validé par test manuel en jeu le 2026-08-17.
