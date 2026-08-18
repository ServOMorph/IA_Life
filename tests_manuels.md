# Tests manuels en attente

Les tests marqués BLOQUÉ et les mécaniques de jeu jamais testées manuellement seront pris
en charge par le mode dev (voir `roadmap_mode-dev.md`).

## Bug connu — enfoncement des personnages dans le sol (Phase 4 terrain)
- Constaté 2026-08-17 : les personnages suivent bien la hauteur du terrain lors de leurs
  déplacements, mais restent visuellement enfoncés dans le sol.
- À investiguer : offset Y au spawn/déplacement (`_terrain_height`) vs. position réelle du
  mesh du corps / capsule de collision (hauteur 1.4).

## Mécaniques de jeu — cueillette et consommation de mûres (jamais testées manuellement)
5. Le slider "Capacité à se nourrir" modifie effectivement le gain de PV par mûre mangée.
   **Étapes :** sur un personnage normal (Rouge/Bleu/Vert/Jaune, seuls à exposer ce slider
   dans leur panneau "Réglages") -> **Shift+F1** (Rouge), **Shift+F2** (Bleu), **Shift+F3**
   (Vert) ou **Shift+F4** (Jaune) pour le téléporter au contact de la ronce la plus proche
   -> **G** puis **H** comme aux items 3-4 pour lui faire cueillir et manger une mûre ->
   noter le gain de PV dans le log `repas` -> modifier le slider "Capacité à se nourrir" du
   même personnage -> répéter **Shift+F1..F4** + **G** + **H** -> comparer le nouveau gain
   de PV au précédent.
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
9. Un souvenir se renforce en cas de revisite, décroît sinon, et disparaît à force nulle.
   **Étapes :** **F5** -> **ZQSD** au contact d'une ronce (souvenir créé, force 10, log
   `memoire`) -> s'éloigner -> augmenter la "Vitesse jeu" (menu bas) pour accélérer la
   décroissance (0.15/s par défaut) -> observer dans le panneau "Personnage de test" que
   "Ronciers mémorisés" repasse à 0, avec le log `memoire` ("oublie un roncier, mémoire
   estompée"). Pour la revisite : recontacter la même ronce avant disparition complète du
   souvenir, puis revérifier que le délai avant disparition repart de 10 (pas de log dédié
   à la revisite : à déduire du délai observé, sensiblement identique au premier cycle).
10. Mémoire pleine : le souvenir le plus faible est remplacé par un nouveau roncier
    découvert.
    **Étapes :** **F5** -> **ZQSD** au contact de 6 ronces distinctes différentes (mémoire
    par défaut du personnage de test = 5, `ronce_count` par défaut = 24, largement
    suffisant). Au 6e contact, vérifier le log `memoire` ("oublie un roncier pour en
    retenir un nouveau") et que "Ronciers mémorisés" reste plafonné à 5.
11. Le slider "Mémoire" modifie effectivement le nombre de souvenirs simultanés.
    **Étapes :** sur un personnage normal -> réduire son slider "Mémoire" (panneau
    "Réglages", ex. 2) -> **Shift+F1..F4** répété pour le téléporter au contact de 3 ronces
    distinctes (revenir sur la carte entre deux **Shift+F1..F4** si besoin) -> vérifier via
    le log `memoire` que le plafond de remplacement se déclenche dès le 3e contact au lieu
    du 6e (comportement par défaut).

## Mécaniques de jeu — collision physique des ronces (jamais testée manuellement)
12. Un personnage ne traverse pas une ronce : il est bloqué ou contourne l'obstacle
    physiquement.
    **Étapes :** **F5** -> **ZQSD** droit sur le centre d'une ronce. Vérifier que le
    personnage s'arrête/rebondit avant le centre du buisson (collision cylindrique rayon
    1.0) plutôt que de traverser le mesh visuel.
