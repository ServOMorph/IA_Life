# Tests manuels en attente

Les tests marqués BLOQUÉ et les mécaniques de jeu jamais testées manuellement seront pris
en charge par le mode dev (voir `roadmap_mode-dev.md`).

## Bug connu — enfoncement des personnages dans le sol (Phase 4 terrain)
- Constaté 2026-08-17 : les personnages suivent bien la hauteur du terrain lors de leurs
  déplacements, mais restent visuellement enfoncés dans le sol.
- À investiguer : offset Y au spawn/déplacement (`_terrain_height`) vs. position réelle du
  mesh du corps / capsule de collision (hauteur 1.4).

## Mécaniques de jeu — cueillette et consommation de mûres (jamais testées manuellement)
6. La modale "Données du jeu" applique immédiatement les seuils/max mûres modifiés ;
   `ronce_count`/`berries_per_ronce` ne s'appliquent qu'au "Relancer".
   **Étapes :** ouvrir "Données du jeu" (bouton menu bas) -> modifier "Seuil cueillette
   (faim)", "Seuil consommation (faim)" ou "Mûres max portées" -> répéter la manip des
   items 3-4 (**ZQSD** + **G**/**H**) pour vérifier que le nouveau seuil s'applique sans
   redémarrage. Puis modifier "Nombre de ronces" ou "Mûres par ronce" -> vérifier en vue
   libre qu'aucune ronce n'apparaît/disparaît immédiatement -> cliquer "Relancer" ->
   vérifier que le nombre de ronces sur la carte correspond à la nouvelle valeur.

## Mécaniques de jeu — mémoire spatiale des ronciers (jamais testée manuellement)
8. Un personnage se dirige vers le roncier mémorisé le plus proche quand sa faim dépasse
   le seuil de cueillette.
   **Étapes :** **F5** (contrôle du personnage de test) -> **ZQSD** jusqu'au contact d'une
   ronce (crée un souvenir, log catégorie `memoire`) -> s'éloigner nettement -> **G** (force
   la faim à 95) -> **F5** à nouveau pour désactiver le contrôle manuel (le personnage
   reprend un comportement autonome). Vérifier qu'il se dirige vers la ronce mémorisée
   plutôt que de errer au hasard.
9. Un souvenir décroît avec le temps et disparaît à force nulle.
   **Étapes :** **F5** -> **ZQSD** au contact d'une ronce (souvenir créé, log `memoire`) ->
   s'éloigner -> monter la "Vitesse jeu" (menu bas, ex. x10) pour accélérer l'attente ->
   observer le log `memoire` ("oublie un roncier, mémoire estompée") et "Ronciers
   mémorisés" repasser à 0 dans le panneau "Personnage de test".
   *(Renforcement par revisite non testé ici : pas de log dédié pour l'observer facilement.)*
10. Mémoire pleine : le souvenir le plus faible est remplacé par un nouveau roncier
    découvert.
    **Étapes :** **F5** -> **ZQSD** au contact de 6 ronces distinctes différentes (mémoire
    par défaut du personnage de test = 5, `ronce_count` par défaut = 24, largement
    suffisant). Au 6e contact, vérifier le log `memoire` ("oublie un roncier pour en
    retenir un nouveau") et que "Ronciers mémorisés" reste plafonné à 5.
11. Le slider "Mémoire" modifie effectivement le nombre de souvenirs simultanés.
    **Étapes :** panneau "Personnage de test", réduire le slider "Mémoire" à 2 -> **F5** ->
    **ZQSD** au contact de 3 ronces distinctes -> au 3e contact, vérifier le log `memoire`
    ("oublie un roncier pour en retenir un nouveau") et que "Ronciers mémorisés" reste
    plafonné à 2 (au lieu de 5 par défaut).
