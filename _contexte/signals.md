# Signals — ia_life   (MAJ 2026-08-17)

## Actions ouvertes
- [P1|ouvert] Poursuivre `roadmap_mode-dev.md` — Phase 3 (UX de checklist en jeu :
  panneau listant les tests par catégorie, validation/invalidation + commentaire,
  sauvegarde des résultats).
  fait quand: le panneau est implémenté et un premier cycle de validation est sauvegardé
  réf: `roadmap_mode-dev.md`, `tests_manuels.md`, `scripts/ui_manager.gd`, `scripts/main.gd`
- [P1|ouvert] Retester manuellement en jeu les mécaniques encore bloquées : bascule
  plein/vide des ronces (cueillette), comportement simultané des 4 personnages, et les
  tests jamais validés de cueillette/consommation/mémoire/collision (items 3-12).
  fait quand: chaque test de `tests_manuels.md` est confirmé ou invalidé par l'utilisateur
  réf: `tests_manuels.md`, `roadmap_mode-dev.md`
- [P2|ouvert] Corriger le bug des personnages visuellement enfoncés dans le sol (ils
  suivent bien la hauteur du terrain en déplacement mais restent enfoncés).
  fait quand: les personnages apparaissent au niveau du sol en déplacement et à l'arrêt
  réf: `tests_manuels.md` (section "Bug connu"), `scripts/main.gd` (`_terrain_height`,
  `_spawn_character`), `scripts/character.gd`
- [P2|ouvert] Faire confirmer par l'utilisateur en jeu le correctif de luminosité (scène
  de jour au lieu de nuit) — vérifié cette session par capture d'écran automatisée
  uniquement, pas encore en jeu réel par l'utilisateur.
  fait quand: l'utilisateur confirme visuellement en jeu
  réf: `scripts/main.gd` (`_build_environment`, `_build_light`),
  `_docs/decisions/2026-08-17_terrain-relief-procedural.md`

## Dernière session (2026-08-17)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-17

## Décisions prises
- Validation manuelle en jeu du terrain/relief/cuvettes de spawn, de la faim/
  vieillissement/mort et de la vitesse de simulation ; clignotement de texture d'herbe
  non reproduit (considéré résolu)
- Construction du mode dev (`roadmap_mode-dev.md`) pour rendre observables à la demande
  les mécaniques bloquées en observation directe (cueillette isolée, 4 personnages
  simultanés) : `run_dev.py`, raccourcis clavier, UX en jeu
- Correction du bug "scène de nuit" (ciel/lumière/exposition), vérifiée par capture
  d'écran automatisée avant/après

## Livrables produits ou modifiés
- `roadmap_mode-dev.md` : créé (Phases 1 et 2 [FAIT], Phases 3-4 [TODO])
- `run_dev.py` : créé
- `scripts/main.gd` : raccourcis dev (Espace/N/H/E/F1-F4), correctif éclairage jour
- `scripts/ui_manager.gd` : bandeau "MODE DEV" + indicateur "Temps gelé"
- `tests_manuels.md` : items validés retirés ; reste 2 tests BLOQUÉS + 1 bug connu
- `_docs/decisions/2026-08-17_ronces-mures-donnees-jeu.md`,
  `_docs/decisions/2026-08-17_terrain-relief-procedural.md` : commentaires mis à jour

## Hypothèses validées / invalidées
- VALIDE : relief, cuvettes de spawn, faim/vieillissement/mort, vitesse de simulation
- INVALIDE : luminosité (scène de nuit) -> corrigée (ciel/lumière/exposition), vérifiée
  par capture d'écran, en attente de confirmation utilisateur en jeu
- EN ATTENTE : bascule plein/vide des ronces, comportement des 4 personnages simultanés,
  cueillette/consommation/mémoire/collision (items 3-12), bug enfoncement dans le sol

## Prochaine étape exacte
Phase 3 de `roadmap_mode-dev.md` : UX de checklist en jeu.

## Question bloquante pour la session suivante
Aucune

## Contexte chaud
- Zone `design` (DESIGN/roadmap_graphisme.md) : plusieurs sessions ont modifié du rendu/
  terrain couvert par la roadmap graphisme (Phase 4) sans passer par `/close design` —
  penser à clore aussi cette zone si un point d'étape graphisme est nécessaire.
