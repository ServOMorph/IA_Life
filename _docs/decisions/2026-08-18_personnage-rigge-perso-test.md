# Personnage riggé (Phase 5) branché uniquement sur le personnage de test

**Date :** 2026-08-18
**Statut :** validé

## Décision
- Choix du modèle pour la Phase 5 (`DESIGN/roadmap_graphisme.md`) : modélisation custom via
  Blender, piloté en ligne de commande (`blender --background --python`) plutôt qu'un pack CC0
  (Quaternius) ou une modélisation manuelle dans l'éditeur Blender.
- Le rig (armature 10 os + skinning rigide + animations Idle/Walk/Death) est généré par script
  reproductible (`tools/blender/build_character.py`) et exporté en glTF binaire
  (`assets/models/character.glb`).
- Intégration limitée au personnage de test (mode dev) uniquement — demande explicite de
  l'utilisateur pour isoler la validation avant extension éventuelle aux 4 personnages IA
  normaux (qui restent sur les box meshes + animation procédurale de la Phase 3).
- Blender installé localement (`D:\blender`, via winget) pour permettre la régénération future
  du modèle sans dépendance à un poste tiers.

## Implémentation
- `tools/blender/build_character.py` : génère l'armature, le skinning et les 3 actions, exporte
  en `.glb`.
- `scripts/main.gd` : `_spawn_character(..., rigged: bool)`, `_setup_rigged_visual()` (charge le
  `.glb`, teinte les mesh parts, force le bouclage `Animation.LOOP_LINEAR` sur Idle/Walk).
  `_spawn_test_character()` est le seul appelant avec `rigged = true`.
- `scripts/character.gd` : `setup_rigged_visual()`, `_play_anim()`, branchement Idle/Walk dans
  `_update_walk_animation()` et Death dans `_die()` quand un `AnimationPlayer` est présent ;
  nouvelle méthode `kill()` pour déclencher la mort du personnage de test (immortel par défaut)
  et vérifier l'animation Death.

## Commentaire
Validé par l'utilisateur ("tests validés") après correctif du bouclage d'animation (glissement
constaté après une marche prolongée, animation figée faute de boucle explicite) et ajout de la
touche **K** pour tuer le personnage de test à la demande. Prochaine décision à prendre :
étendre ou non ce rig aux 4 personnages normaux (actuellement hors périmètre de cette session).
