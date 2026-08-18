# Signals — ia_life   (MAJ 2026-08-18)

## Actions ouvertes
- [P1|ouvert] Reprendre la validation checklist (`tests_manuels.md`) avec le personnage de
  test : items 5, 6, 8-12 (capacité à se nourrir, données du jeu, mémoire spatiale,
  collision des ronces), étapes déjà rédigées dans le fichier.
  fait quand: chaque test restant de `tests_manuels.md` est confirmé ou invalidé par
  l'utilisateur
  réf: `tests_manuels.md`, `roadmap_mode-dev.md` (Phase 4)
- [P1|ouvert] Décider si le personnage riggé (Phase 5, `assets/models/character.glb`) doit
  être étendu aux 4 personnages normaux ou rester un outil de test.
  fait quand: décision prise avec l'utilisateur
  réf: `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`,
  `DESIGN/roadmap_graphisme.md` (Phase 5)
- [P2|ouvert] Corriger le bug des personnages visuellement enfoncés dans le sol (ils
  suivent bien la hauteur du terrain en déplacement mais restent enfoncés).
  fait quand: les personnages apparaissent au niveau du sol en déplacement et à l'arrêt
  réf: `tests_manuels.md` (section "Bug connu"), `scripts/main.gd` (`_terrain_height`,
  `_spawn_character`), `scripts/character.gd`
- [P3|ouvert] Décider du sort du log de diagnostic temporaire (`_test_debug_log_timer`)
  maintenant que le contrôle clavier du personnage de test est confirmé fonctionnel.
  fait quand: décision prise avec l'utilisateur
  réf: `scripts/main.gd` (`_update_test_character_movement`)
- [P3|ouvert] Définir l'action future assignée à la touche E du personnage de test
  (actuellement placeholder sans effet).
  fait quand: une action concrète est spécifiée et implémentée
  réf: `scripts/main.gd` (`_dev_test_character_action`)

## Contexte chaud
- Zone `design` (`DESIGN/roadmap_graphisme.md`) : Phase 5 avancée et validée (rig +
  animations sur le personnage de test) dans cette même session mais sans passer par
  `/close design` — penser à clore cette zone séparément (`_contexte/signals.md` de design
  encore sur l'état "bloqué" antérieur à cette session).
- Blender installé localement (`D:\blender`, via winget) pour permettre la régénération du
  modèle riggé sans dépendance à un poste tiers.
- Dossier `_docs/Analyse du projet/` : non suivi par git, origine hors de cette session,
  laissé de côté.

## Dernière session (2026-08-18)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-18

## Décisions prises
- Rig personnage (Phase 5, `roadmap_graphisme.md`) généré via Blender headless (script
  reproductible), branché uniquement sur le personnage de test — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- Personnage de test contrôlable (F5/ZQSD) confirmé fonctionnel après usage intensif cette
  session — statut de la décision passé à validé.
- Checklist en jeu retravaillée (sélection individuelle par test, état persisté, masquage
  des tests validés) ; réglages du jeu persistés sur disque (`GameConfig`).

## Livrables produits ou modifiés
- `tools/blender/build_character.py`, `assets/models/character.glb` : créés (rig 10 os,
  animations Idle/Walk/Death)
- `scripts/main.gd`, `character.gd` : rig branché sur le perso test, touche K (tuer le
  perso test), touche G (faim haute), Shift+F1-F4 (téléport au contact d'une ronce)
- `scripts/ui_manager.gd`, `game_config.gd` : refonte checklist, persistance des réglages
- `scripts/free_camera.gd` : correctif pitch orbite + clamp au sol
- `tests_manuels.md` : items 1-4 et rig Phase 5 validés et retirés ; items 5, 6, 8-12
  enrichis d'étapes précises
- `_docs/decisions/` : 2 fichiers mis à jour/créés (statuts validé)

## Hypothèses validées / invalidées
- VALIDE : contrôle clavier du personnage de test fonctionnel
- VALIDE : rig Phase 5 (Idle/Walk/Death) sur le personnage de test
- VALIDE : cueillette/consommation de base, bascule ronce, animation procédurale 4 persos
- EN ATTENTE : items 5, 6, 8-12 de `tests_manuels.md`

## Prochaine étape exacte
Reprendre la checklist en jeu (touche T) pour les items 5, 6, 8-12 ; trancher l'extension
du rig aux 4 personnages normaux.

## Question bloquante pour la session suivante
Aucune
