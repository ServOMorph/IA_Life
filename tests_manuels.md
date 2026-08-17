# Tests manuels en attente

## Rendu graphique — Phase 2 (matériaux PBR et ressources visuelles)
- Lancer le jeu, vérifier que le sol affiche la texture d'herbe (leafy_grass) sans étirement visible sur les bords de la map.
- Vérifier que les murs affichent la texture de brique (brick_wall_001), sans étirement, correctement mappée sur les 4 faces du pourtour.
- Vérifier que les ronces affichent un buisson (cluster de sphères) et non plus une sphère unique.
- Vérifier que la bascule plein/vide des ronces (récolte de mûres) reste visuellement lisible.
- Valider sur la map complète (déplacement caméra libre ZQSD) qu'aucune texture ne semble déformée, répétée de façon incohérente ou mal éclairée.

## Bug connu — clignotement texture herbe
- Clignotement occasionnel observé sur la texture d'herbe du sol (aliasing spéculaire probable, TAA + normal map).
- Tenté : clamp `min_roughness` et réduction `normal_strength` dans `triplanar.gdshader` — n'a pas résolu le problème.
- À investiguer plus tard (pistes restantes : désactiver SSR sur cette surface, réduire l'échelle de la normal map, vérifier filtrage/mipmaps du sampler, ou tester sans TAA).

## Rendu graphique — Phase 3 (animation procédurale des personnages)
- Vérifier que chaque personnage s'oriente vers sa direction de déplacement (plus de glissement sans rotation).
- Vérifier le bobbing de marche (léger mouvement vertical + tilt du corps) en mouvement, et le retour au repos (idle) à l'arrêt.
- Vérifier l'animation de mort : bascule progressive (0,6s) au lieu du basculement instantané précédent.
- Valider sur les 4 personnages simultanément, pas de comportement erratique (rotation qui vibre, bobbing qui persiste à l'arrêt).

## Caméra — cycle clic sur nom (3e personne / 1re personne / retour)
- Clic sur un nom en vue libre : passe en caméra 3e personne (suivi du personnage).
- Reclic sur le même nom : passe en vue 1re personne (yeux du personnage), pas de clipping dans la tête.
- En vue 1re personne : la souris oriente le regard, avec une limite réaliste (~90° de rotation de chaque côté par rapport à l'orientation du corps, pitch limité) — impossible de regarder à 360° ou directement derrière soi.
- En vue 1re personne : si le personnage se déplace et tourne, le champ de vision suit son orientation de corps (le décalage souris reste relatif).
- Reclic à nouveau sur le même nom : retour exact à la caméra précédente (position/rotation libre si c'était le cas).
- Clic sur "Large" pendant un suivi/1re personne : retour à la vue d'ensemble par défaut.
- Clic sur un autre nom pendant un suivi/1re personne en cours : bascule correctement sans état incohérent.
