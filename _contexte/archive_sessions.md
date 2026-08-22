# Session du 2026-08-17

## Décisions prises
- Cueillette de mûres (ronces), consommation auto, modale "Données du jeu" (proposé)
- Mode headless + skills `analyse-partie`/`experimentation-headless` (proposé)
- Mémoire spatiale des ronciers par personnage, capacité 0-10 (proposé)
- Collision physique ajoutée aux ronces, en plus de l'Area3D de détection (proposé)
- Plafond de vitesse headless x80 documenté ; correction collision de nommage des logs

## Livrables produits ou modifiés
- scripts/game_config.gd, ronce.gd, game_logger.gd : créés
- scripts/character.gd, main.gd, ui_manager.gd, free_camera.gd : modifiés
- run_headless.py : créé
- .claude/skills/analyse-partie/, experimentation-headless/ : créés
- _docs/decisions/*.md : mis à jour (2 décisions enrichies d'amendements)

## Hypothèses validées / invalidées
- VALIDE (empirique headless) : la vitesse de jeu n'altère pas l'issue une fois les
  mécaniques indexées sur `time_scale`
- VALIDE (empirique headless, 8 runs x50) : mémoire + collision physique des ronces
  n'introduisent pas de régression sur cueillette/survie
- EN ATTENTE : aucune validation manuelle en jeu (`python run.py`) reçue cette session ->
  les décisions restent au statut "proposé"

## Prochaine étape exacte
Retester manuellement en jeu (`python run.py`) l'ensemble des mécaniques ronces/mémoire,
puis valider/invalider les décisions dans `_docs/decisions/`.

## Question bloquante pour la session suivante
Aucune

---

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

---

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
