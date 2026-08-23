# Refonte visuelle des ronces : buisson vert + mûres noires visibles

**Date :** 2026-08-22
**Statut :** validé

## Décision
- Le roncier (buisson) passe d'une palette violet/terre (bascule plein/vide par matériaux)
  à un buisson vert réaliste : mesh à 7 lobes irréguliers, couleur fixe
  `Color(0.16, 0.34, 0.12)`, qui ne change plus quand le roncier est vide.
- Les mûres sont désormais visibles : autant de petites sphères noires sur le buisson que
  de mûres restantes (`berries_per_ronce` au spawn), positionnées sur la surface des lobes
  de façon aléatoire. Chaque cueillette (`harvest_one()`) retire visuellement une mûre.
- Suppression de la bascule plein/vide `_full_mat`/`_empty_mat` dans `ronce.gd`.

## Implémentation
- `scripts/ronce.gd` : `setup_visual(berry_positions, berry_mat)` construit les sphères de
  mûres dans un conteneur dédié ; `harvest_one()` retire la dernière mûre (`queue_free()`).
- `scripts/main.gd` : `BUSH_LOBES` (const, 7 lobes), `_bush_berry_positions(count)`
  (positions sur la surface des lobes), matériaux buisson vert / mûres noires brillantes.

## Commentaire
Exercé en jeu lors de la validation du test manuel 5 (cueillette au contact d'une ronce
puis consommation, gain de PV proportionnel au slider "Capacité à se nourrir").
Validation visuelle globale du rendu (aspect du buisson, lisibilité des mûres) confirmée le
2026-08-23 (test manuel 15 validé).
