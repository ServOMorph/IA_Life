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
