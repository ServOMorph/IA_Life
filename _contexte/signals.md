# Signals — ia_life   (MAJ 2026-08-22)

## Actions ouvertes
- [P1|ouvert] Reprendre la validation checklist (`tests_manuels.md`) avec le personnage de
  test : items 6, 8-12 (données du jeu, mémoire spatiale, collision des ronces), étapes
  déjà rédigées dans le fichier. Test 5 validé (2026-08-21).
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
  animations sur le personnage de test) dans une session sans passer par `/close design`
  — penser à clore cette zone séparément (`_contexte/signals.md` de design encore sur
  l'état antérieur ; fichiers DESIGN/ modifiés non commités : signals.md et
  roadmap_graphisme.md, à valider lors de la clôture de la zone design).
- Blender installé localement (`D:\blender`, via winget) pour permettre la régénération du
  modèle riggé sans dépendance à un poste tiers.
- Dossier `_docs/Analyse du projet/` : non suivi par git, origine hors de cette session,
  laissé de côté.
- Refonte visuelle des ronces faite en session (buisson vert + mûres noires) — validation
  visuelle globale du rendu en attente d'une confirmation explicite (voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`).

## Dernière session (2026-08-22)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-22

## Décisions prises
- Refonte visuelle des ronces : buisson vert réaliste (7 lobes, couleur fixe qui ne change
  plus quand le roncier est vide), mûres noires visibles sur le buisson (1 sphère par mûre
  restante), retrait visuel d'une mûre à chaque cueillette ; suppression de la bascule
  plein/vide par matériaux — voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
- Test manuel 5 validé (slider "Capacité à se nourrir" : gain de PV proportionnel).

## Livrables produits ou modifiés
- `scripts/ronce.gd` : mûres visuelles (sphères noires, retrait à la cueillette),
  suppression des matériaux plein/vide
- `scripts/main.gd` : buisson 7 lobes + matériau vert fixe, génération des positions de
  mûres (`_bush_berry_positions`)
- `scripts/ui_manager.gd` : sliders "Capacité à se nourrir"/"Mémoire" au panneau perso de
  test, détail de test scrollable (travail hors de cette session, lié au test 5)
- `tests_manuels.md` : test 5 validé et retiré (restent items 6, 8-12)
- `_docs/decisions/2026-08-22_ronces-mures-visuelles.md` : créé (statut validé)

## Hypothèses validées / invalidées
- VALIDE : test 5 (gain de PV proportionnel au slider "Capacité à se nourrir")
- EN ATTENTE : validation visuelle globale de la refonte ronces/mûres (aspect du buisson,
  lisibilité des mûres)

## Prochaine étape exacte
Reprendre la checklist en jeu (touche T) pour les items 6, 8-12 de `tests_manuels.md` ;
confirmer visuellement la refonte ronces/mûres.

## Question bloquante pour la session suivante
Aucune
