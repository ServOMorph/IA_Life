# Signals — ia_life   (MAJ 2026-08-18)

## Actions ouvertes
- [P1|ouvert] Confirmer que le contrôle clavier (ZQSD) du personnage de test fonctionne
  après F5 — terrain aplani suite à un premier essai jugé trop accidenté, log de
  diagnostic ajouté, aucun retour reçu depuis.
  fait quand: l'utilisateur confirme le déplacement en jeu, ou le log `logs/session_*.log`
  (entrées "Debug test-perso") montre une position qui varie avec les touches
  réf: `scripts/main.gd` (`_update_test_character_movement`, `_dev_toggle_test_control`)
- [P1|ouvert] Reprendre la validation checklist (`tests_manuels.md`) avec le personnage de
  test : bascule plein/vide des ronces (item 1, désormais testable), 4 personnages
  simultanés (item 2, toujours bloqué), items 4-12 (consommation, mémoire, collision)
  jamais testés.
  fait quand: chaque test de `tests_manuels.md` est confirmé ou invalidé par l'utilisateur
  réf: `tests_manuels.md`, `roadmap_mode-dev.md` (Phase 4)
- [P2|ouvert] Décider du sort du log de diagnostic temporaire (`_test_debug_log_timer`)
  une fois le contrôle clavier confirmé — le retirer ou le garder.
  fait quand: décision prise avec l'utilisateur
  réf: `scripts/main.gd` (`_update_test_character_movement`)
- [P2|ouvert] Corriger le bug des personnages visuellement enfoncés dans le sol (ils
  suivent bien la hauteur du terrain en déplacement mais restent enfoncés).
  fait quand: les personnages apparaissent au niveau du sol en déplacement et à l'arrêt
  réf: `tests_manuels.md` (section "Bug connu"), `scripts/main.gd` (`_terrain_height`,
  `_spawn_character`), `scripts/character.gd`
- [P3|ouvert] Définir l'action future assignée à la touche E du personnage de test
  (actuellement placeholder sans effet).
  fait quand: une action concrète est spécifiée et implémentée
  réf: `scripts/main.gd` (`_dev_test_character_action`)

## Dernière session (2026-08-18)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-18

## Décisions prises
- Phase 3 de `roadmap_mode-dev.md` implémentée (checklist en jeu) ; premier cycle de
  validation traité (Phase 4 démarrée)
- Correctif bug pré-existant : `directional_shadow_normal_bias` (propriété invalide) ->
  `shadow_normal_bias`
- Pivot majeur : ajout d'un 5ème personnage de test contrôlable manuellement (F5, ZQSD +
  souris, vue orbitale 3e personne, immortel), remplace la dépendance à F1-F4 seul —
  décision arbitrée avec l'utilisateur, voir `_docs/decisions/2026-08-18_*.md`
- Terrain aplani autour du spawn du personnage de test (rayon 18), luminosité ambiante
  -10%, personnage de test recoloré en gris foncé
- Touches H/E réaffectées : H = forcer faim basse (repas) ; E = réservée à une future
  action du personnage de test (aucun effet pour l'instant)

## Livrables produits ou modifiés
- `scripts/ui_manager.gd` : panneau checklist, panneau "Personnage de test", indicateurs
  d'état dans le bandeau MODE DEV
- `scripts/main.gd` : personnage de test, touche F5, aplanissement terrain, luminosité,
  réaffectation H/E, correctif shadow, log de diagnostic temporaire
- `scripts/character.gd` : `manual_control`, `immortal`, `set_manual_direction`
- `scripts/free_camera.gd` : mode `ORBIT` (vue 3e personne pilotable)
- `tests_manuels.md` : items 1 et 2 mis à jour (item 1 débloqué, item 2 affiné)
- `roadmap_mode-dev.md` : Phase 3 [FAIT], Phase 4 [EN COURS]
- `_docs/decisions/2026-08-18_personnage-test-controlable.md` : créé (statut proposé)

## Hypothèses validées / invalidées
- VALIDE : correctif `shadow_normal_bias` (vérifié headless, plus d'erreur)
- VALIDE : item 1 (bascule ronce) débloqué mécaniquement via suivi caméra auto sur F1-F4
- INVALIDE : F1-F4 seul insuffisant pour observer cueillette/comportement -> pivot vers
  personnage de test contrôlable
- EN ATTENTE : contrôle clavier du personnage de test (jamais confirmé fonctionnel),
  items 2 et 4-12 de `tests_manuels.md`

## Prochaine étape exacte
Confirmer en jeu que ZQSD déplace bien le personnage de test après F5 (terrain aplani
entre-temps), puis reprendre la checklist pour les items restants.

## Question bloquante pour la session suivante
Aucune

## Contexte chaud
- Zone `design` (DESIGN/roadmap_graphisme.md) : modifiée hors session ia_life (Phase 5
  passée en EN COURS — bloqué), toujours non commitée, sans passer par `/close design` —
  penser à clore cette zone séparément.
- Dossier `_docs/Analyse du projet/` : non suivi par git, origine hors de cette session,
  laissé de côté.
