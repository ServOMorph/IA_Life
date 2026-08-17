# Tests manuels en attente

Les tests marqués BLOQUÉ et les mécaniques de jeu jamais testées manuellement seront pris
en charge par le mode dev (voir `roadmap_mode-dev.md`).

## Rendu graphique — Phase 2 (matériaux PBR et ressources visuelles)
1. Vérifier que la bascule plein/vide des ronces (récolte de mûres) reste visuellement
   lisible. BLOQUÉ : nécessite d'observer un personnage cueillir une mûre en direct.

## Rendu graphique — Phase 3 (animation procédurale des personnages)
2. Valider sur les 4 personnages simultanément, pas de comportement erratique (rotation
   qui vibre, bobbing qui persiste à l'arrêt). BLOQUÉ : pas de moyen actuel d'observer les
   4 personnages en détail simultanément.

## Bug connu — enfoncement des personnages dans le sol (Phase 4 terrain)
- Constaté 2026-08-17 : les personnages suivent bien la hauteur du terrain lors de leurs
  déplacements, mais restent visuellement enfoncés dans le sol.
- À investiguer : offset Y au spawn/déplacement (`_terrain_height`) vs. position réelle du
  mesh du corps / capsule de collision (hauteur 1.4).

## Mécaniques de jeu — cueillette et consommation de mûres (jamais testées manuellement)
3. Un personnage cueille une mûre au contact d'une ronce uniquement si sa faim dépasse le
   seuil configuré (90 par défaut) et qu'il n'a pas atteint le max porté (3).
4. Un personnage mange une mûre portée dès que sa faim descend sous le seuil configuré
   (50 par défaut), gain de PV cohérent avec `pv_per_berry`.
5. Le slider "Capacité à se nourrir" modifie effectivement le gain de PV par mûre mangée.
6. La modale "Données du jeu" applique immédiatement les seuils/max mûres modifiés ;
   `ronce_count`/`berries_per_ronce` ne s'appliquent qu'au "Relancer".
7. Les compteurs "Mûres ramassées/mangées (total)" restent corrects et visibles après la
   mort du personnage.

## Mécaniques de jeu — mémoire spatiale des ronciers (jamais testée manuellement)
8. Un personnage se dirige vers le roncier mémorisé le plus proche quand sa faim dépasse
   le seuil de cueillette.
9. Un souvenir se renforce en cas de revisite, décroît sinon, et disparaît à force nulle.
10. Mémoire pleine : le souvenir le plus faible est remplacé par un nouveau roncier
    découvert.
11. Le slider "Mémoire" modifie effectivement le nombre de souvenirs simultanés.

## Mécaniques de jeu — collision physique des ronces (jamais testée manuellement)
12. Un personnage ne traverse pas une ronce : il est bloqué ou contourne l'obstacle
    physiquement.

