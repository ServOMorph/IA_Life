# Personnage de test contrôlable manuellement (mode dev)

**Date :** 2026-08-18
**Statut :** proposé

## Décision
- Remplacement de l'approche F1-F4 seule (téléportation automatique vers une ronce) par un
  5ème personnage dédié aux tests, présent uniquement en mode dev (`IA_LIFE_DEV_MODE=1`).
- Spawn au centre de la map, immortel (faim pilotable sans jamais mourir), immobile par
  défaut. Touche **F5** : active/désactive le contrôle manuel — caméra en orbite 3ème
  personne (souris = orbite + zoom), **ZQSD** déplace le personnage relatif à l'orientation
  caméra.
- Motif : les tests de la checklist (`tests_manuels.md`) sur la cueillette/l'observation des
  personnages restaient invalidés malgré F1-F4, faute de pouvoir réellement observer l'action
  (pas de suivi caméra). Décision arbitrée par l'utilisateur suite au premier cycle de
  validation checklist (3 tests invalidés pour cause d'observabilité insuffisante).
- Terrain aplani (rayon 18 autour du centre) pour faciliter le déplacement du personnage de
  test sur un relief peu accidenté.

## Implémentation
- `scripts/character.gd` : `manual_control`, `immortal`, `set_manual_direction()`.
- `scripts/free_camera.gd` : nouveau mode `ORBIT` (vue 3ème personne pilotable à la souris).
- `scripts/main.gd` : spawn du personnage de test, touche F5, calcul du déplacement relatif à
  la caméra (`_update_test_character_movement`), touche **E** réservée à une future action
  contextuelle (aucun effet pour l'instant), touche **H** = forcer faim basse (repas).
- `scripts/ui_manager.gd` : panneau "Personnage de test" (mûres portées/ramassées, faim) en
  bas au centre de l'écran.
- F1-F4 (téléportation + suivi caméra automatique) conservés pour les 4 personnages IA.

## Commentaire
Non encore validé : le contrôle clavier (ZQSD) du personnage de test n'a pas été confirmé
fonctionnel par l'utilisateur (terrain jugé trop accidenté lors du premier essai, aplani en
conséquence ; un log de diagnostic temporaire a été ajouté dans
`scripts/main.gd::_update_test_character_movement` mais aucun retour n'a encore été reçu après
le nouvel essai).
