# Tests manuels en attente

## Rendu graphique — Phase 2 (matériaux PBR et ressources visuelles)
1. Lancer le jeu, vérifier que le sol affiche la texture d'herbe (leafy_grass) sans étirement visible sur les bords de la map.
2. Vérifier que les murs affichent la texture de brique (brick_wall_001), sans étirement, correctement mappée sur les 4 faces du pourtour.
3. Vérifier que les ronces affichent un buisson (cluster de sphères) et non plus une sphère unique.
4. Vérifier que la bascule plein/vide des ronces (récolte de mûres) reste visuellement lisible.
5. Valider sur la map complète (déplacement caméra libre ZQSD) qu'aucune texture ne semble déformée, répétée de façon incohérente ou mal éclairée.

## Bug connu — clignotement texture herbe
- Clignotement occasionnel observé sur la texture d'herbe du sol (aliasing spéculaire probable, TAA + normal map).
- Tenté : clamp `min_roughness` et réduction `normal_strength` dans `triplanar.gdshader` — n'a pas résolu le problème.
- À investiguer plus tard (pistes restantes : désactiver SSR sur cette surface, réduire l'échelle de la normal map, vérifier filtrage/mipmaps du sampler, ou tester sans TAA).

## Rendu graphique — Phase 3 (animation procédurale des personnages)
6. Vérifier que chaque personnage s'oriente vers sa direction de déplacement (plus de glissement sans rotation).
7. Vérifier le bobbing de marche (léger mouvement vertical + tilt du corps) en mouvement, et le retour au repos (idle) à l'arrêt.
8. Vérifier l'animation de mort : bascule progressive (0,6s) au lieu du basculement instantané précédent.
9. Valider sur les 4 personnages simultanément, pas de comportement erratique (rotation qui vibre, bobbing qui persiste à l'arrêt).

## Caméra — cycle clic sur nom (3e personne / 1re personne / retour)
10. Clic sur un nom en vue libre : passe en caméra 3e personne (suivi du personnage).
11. Reclic sur le même nom : passe en vue 1re personne (yeux du personnage), pas de clipping dans la tête.
12. En vue 1re personne : la souris oriente le regard, avec une limite réaliste (~90° de rotation de chaque côté par rapport à l'orientation du corps, pitch limité) — impossible de regarder à 360° ou directement derrière soi.
13. En vue 1re personne : si le personnage se déplace et tourne, le champ de vision suit son orientation de corps (le décalage souris reste relatif).
14. Reclic à nouveau sur le même nom : retour exact à la caméra précédente (position/rotation libre si c'était le cas).
15. Clic sur "Large" pendant un suivi/1re personne : retour à la vue d'ensemble par défaut.
16. Clic sur un autre nom pendant un suivi/1re personne en cours : bascule correctement sans état incohérent.

## Rendu graphique — Phase 4 (terrain et décor)
17. Vérifier que le sol affiche un relief léger (vallonnement doux), avec la texture d'herbe toujours correctement mappée dessus.
18. Vérifier que le relief s'aplatit près des murs (les murs restent bien plantés sur un sol plat, pas de décalage/flottement).
19. Vérifier que les personnages suivent la hauteur du terrain lors de leurs déplacements (pas de flottement au-dessus du sol, pas d'enfoncement).
20. Vérifier que les ronces sont posées correctement sur le relief (pas flottantes, pas enfoncées).
21. Vérifier la présence de rochers et d'arbres décoratifs répartis sur la map, sans bloquer la circulation des personnages de façon anormale (pas de personnage bloqué en boucle contre un décor).
22. Valider sur la map complète (caméra libre ZQSD) qu'aucun personnage ne traverse le relief ni ne reste bloqué sur une pente.
