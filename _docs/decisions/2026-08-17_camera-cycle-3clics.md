# Cycle caméra 3 clics sur le nom (3e personne / 1re personne / retour)

**Date :** 2026-08-17
**Statut :** proposé

## Décision
- Clic sur un nom de personnage : caméra 3e personne (suivi).
- Reclic sur le même nom : bascule en vue 1re personne ("yeux" du personnage).
- Reclic à nouveau : retour exact à l'état de caméra précédent (libre ou suivi d'un autre
  personnage), via un snapshot position/rotation/zoom.
- En vue 1re personne, la souris oriente le regard mais reste contrainte à une amplitude
  réaliste : lacet ±90° et tangage ±~63° relatifs à l'orientation du corps du personnage
  (qui peut lui-même tourner en marchant) — impossible de regarder à 360° ou derrière soi.

## Implémentation
- `scripts/free_camera.gd` : machine à états `Mode { FREE, FOLLOW, FPS }`,
  `toggle_character()`, `_save_snapshot()`/`_restore_previous()`, constantes
  `FPS_YAW_LIMIT`/`FPS_PITCH_LIMIT`.
- `scripts/ui_manager.gd` : `_on_character_button_pressed` délègue à `toggle_character()`.

## Commentaire
Demande utilisateur ad hoc, hors séquence de la roadmap graphisme. Implémentation vérifiée
sans erreur en headless ; validation visuelle manuelle en attente (`tests_manuels.md`).
