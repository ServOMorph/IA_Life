# Signals — design   (MAJ 2026-08-17)

## Actions ouvertes
- [P1|ouvert] Valider manuellement en jeu (`python run.py`) les Phases 2, 3, 4 de la roadmap
  graphisme + le cycle caméra 3 clics — fait quand: chaque section de `tests_manuels.md` est
  confirmée et supprimée par l'utilisateur — réf: `tests_manuels.md`, `DESIGN/roadmap_graphisme.md`
  (Phases 2-4)
- [P2|ouvert] Clignotement occasionnel de la texture d'herbe (aliasing spéculaire probable) —
  fait quand: cause identifiée et correction validée visuellement (pistes : désactiver SSR sur
  cette surface, réduire l'échelle de la normal map, vérifier filtrage/mipmaps, tester sans TAA)
  — réf: `scripts/triplanar.gdshader`, `tests_manuels.md` (section "Bug connu")
- [P2|ouvert] Démarrer la Phase 5 (personnages riggés et animation squelettique) — fait quand:
  utilisateur confirme les validations Phases 2-4 et donne le feu vert (post-checkpoint/compact)
  — réf: `DESIGN/roadmap_graphisme.md` (Phase 5)

## Contexte chaud
- Les Phases 2, 3 et 4 ont été codées dans la même session sans validation intermédiaire (les
  checkpoints `/compact` entre phases n'ont pas été respectés à la lettre — l'utilisateur a
  enchaîné via "continue"/"continue roadmap"). Toutes marquées `[EN COURS]` dans la roadmap en
  attendant validation groupée, plutôt qu'une seule à la fois comme prévu par le protocole.

## Dernière session (2026-08-17)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-17

## Décisions prises
- Phase 2 : textures PBR CC0 (Poly Haven) via shader triplanar (sol/murs), ronces en buisson
- Phase 3 : orientation personnages, bobbing de marche, animation de mort (tween)
- Caméra : cycle 3 clics (3e personne / 1re personne contrainte / retour), ad hoc hors roadmap
- Phase 4 : relief procédural par code (bruit simplex) choisi plutôt que Terrain3D + décor procédural

## Livrables produits ou modifiés
- scripts/triplanar.gdshader, assets/textures/{leafy_grass,brick_wall_001}/ : créés
- scripts/main.gd, character.gd, free_camera.gd, ui_manager.gd : modifiés
- tests_manuels.md : 5 sections ajoutées (Phases 2/3/4, bug herbe, caméra), en attente
- _docs/decisions/2026-08-17_{terrain-relief-procedural,camera-cycle-3clics}.md : créés

## Hypothèses validées / invalidées
- VALIDE (choix utilisateur) : relief procédural par code préférable à Terrain3D
- INVALIDE (partiel) : clamp roughness/normal map n'a pas résolu le clignotement herbe -> ouvert
- EN ATTENTE : aucune validation manuelle en jeu reçue cette session (Phases 2-4 + caméra)

## Prochaine étape exacte
Valider manuellement en jeu les Phases 2/3/4 + caméra, vider les sections correspondantes de
`tests_manuels.md`, puis démarrer la Phase 5 (personnages riggés).

## Question bloquante pour la session suivante
Aucune
