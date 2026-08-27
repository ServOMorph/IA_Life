# Phase 8 — Vision et perception générique de l'environnement

Date : 2026-08-27
Statut : validé (hors campagne de survie approfondie)

## Décision

Primitive de perception générique (`get_perception_type()`, `get_perception_state()`, groupe
Godot `perceptible`) et fonction de vision (`Character._perceive`) : portée (`vision_range`,
défaut `0.0` = désactivée), champ angulaire relatif à l'orientation visuelle (`vision_angle_degrees`,
défaut `360.0`), occlusion optionnelle par raycast (`vision_blocked_by_terrain`, défaut `false`).

Trois choix de conception tranchés par l'utilisateur via l'appli ROBERTO :

- **Direction de référence** : l'orientation visuelle affichée (`basis`, mise à jour progressive
  par `_update_facing`), pas la direction de déplacement brute — plus réaliste, évite un cône de
  vision qui saute instantanément à chaque changement de décision.
- **Priorité visible/mémorisé** : un roncier visible prime sur un roncier mémorisé pour l'intention
  « manger » (automate et LLM), l'information fraîche l'emportant sur l'information potentiellement
  périmée.
- **Mémorisation par vision** : un roncier vu à distance est mémorisé comme s'il était cueilli,
  pour éviter qu'un roncier vu mais non atteint à temps soit oublié et redécouvert sans cesse.

`social_radius` (perception d'autres agents) absorbé comme cas particulier de la vision au niveau
du code : `_update_social_perception` appelle désormais `_perceive()` au lieu de dupliquer la
boucle de filtrage géométrique. `social_radius` reste un paramètre indépendant de `vision_range`
(pas de fusion des valeurs) — seule la primitive géométrique est partagée. Équivalence stricte
démontrée à seed fixe sur les trois scénarios de référence Phase 6 (`social_communication_smoke_v1`,
`social_aggression_smoke_v1`, `social_cooperation_smoke_v1`) : résultats identiques avant/après
refactorisation.

## Bug trouvé et corrigé pendant la validation

Mémorisation par vision initialement déclenchée à chaque frame pour chaque entité visible : quand
plus d'entités sont visibles simultanément que `memory_capacity`, l'éviction de la plus faible
mémoire reformait indéfiniment le même « nouveau » souvenir à chaque frame, faisant exploser
`ronces_discovered_by_vision_total` (des dizaines de milliers d'incréments sur une campagne de
quelques dizaines de secondes). Corrigé en ne déclenchant la mémorisation qu'à la première
apparition dans le champ de vision (comme le contact physique), pas à chaque frame. Test de
non-régression dédié ajouté (`tools/run_manual_checks.gd::_test_vision_memory_capacity_no_churn`).

Une seconde régression a été introduite puis corrigée pendant l'absorption de `social_radius` :
`_perceive()` aplatit la composante verticale par défaut (cohérent avec la vision, jeu 2D en plan),
ce qui cassait de façon marginale l'équivalence de `social_cooperation_smoke_v1` (distance 3D
originale vs distance horizontale, écart d'une rencontre sur 14 near la limite du rayon). Corrigé
par un paramètre `flatten_vertical` (`true` pour la vision, `false` pour le social, qui préserve la
distance 3D d'origine).

## Commentaire

Non-régression vérifiée : `vision_range = 0.0` (défaut) reproduit les résultats à l'identique
(`tools/check_reproducibility.py`). Scénarios dédiés portée/angle/occlusion validés par comparaison
(`experiments/vision_baseline_smoke_v1.json`, `vision_narrow_angle_smoke_v1.json`,
`vision_short_range_smoke_v1.json`, `vision_occlusion_smoke_v1.json`). Campagne multi-seeds
(`experiments/campaigns/vision_range_campaign_v1.json`, 3 valeurs de `vision_range` × 3 seeds) :
pas de différence de survie observée (ressources abondantes dans ce scénario, 100 % de survie
partout), mais différence nette et cohérente sur la vitesse de découverte (détections, ronciers
découverts par vision, délai vision→contact). Six nouveaux tests unitaires dans
`tools/run_manual_checks.gd` couvrent portée, angle, mémorisation, non-régression du bug de
capacité, et priorité automate visible/mémorisé.
