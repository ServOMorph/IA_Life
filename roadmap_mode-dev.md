# Roadmap — Mode dev (run_dev.py)

Créée le : 2026-08-17
Origine : session de validation manuelle 2026-08-17 — plusieurs mécaniques (cueillette,
mémoire, faim/mort) impossibles à observer/valider en jeu normal (aléatoire, vitesse
compressée, 4 personnages non observables en détail simultanément).

## Objectif
Un mode `run_dev.py` à la racine, avec une UX en jeu qui affiche la liste exhaustive des
tests manuels à effectuer (issue de `tests_manuels.md`), permet de valider/invalider
chaque test avec un commentaire libre, et persiste les résultats dans un fichier relu en
session suivante pour traiter les commentaires un par un.

## Phase 1 — Recensement exhaustif des tests de mécaniques de jeu [FAIT]
- Revue de `tests_manuels.md` (tests de rendu/caméra existants) et des décisions archivées
  (`_docs/decisions/2026-08-17_ronces-mures-donnees-jeu.md`) pour identifier les mécaniques
  jamais couvertes par un test manuel : cueillette, consommation, mémoire spatiale,
  collision des ronces, faim/vieillissement/mort, vitesse de simulation, luminosité.
- 15 tests de mécaniques ajoutés à `tests_manuels.md`, plus 2 tests existants reclassés
  BLOQUÉ (bascule plein/vide des ronces, validation simultanée des 4 personnages) et 1 bug
  connu documenté (enfoncement des personnages dans le sol).
- Ce recensement constitue la liste de départ que l'UX du mode dev devra afficher. Il
  restera à compléter au fil de l'eau (toute nouvelle mécanique ajoutée au jeu doit gagner
  son entrée dans `tests_manuels.md`, donc apparaître dans le mode dev sans étape
  supplémentaire si le mode dev lit directement ce fichier).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Infrastructure d'observation contrôlée [FAIT]
Rendre les mécaniques observables à la demande plutôt que de compter sur le hasard de la
simulation en temps réel :
- `run_dev.py` (nouveau, racine) : lance Godot avec la variable d'environnement
  `IA_LIFE_DEV_MODE=1`. `run.py` inchangé (comportement normal non altéré, variable absente).
- `scripts/main.gd` : `_dev_mode` lu depuis `IA_LIFE_DEV_MODE` en `_ready()`. Raccourcis
  clavier actifs uniquement en mode dev (`_unhandled_key_input`) :
  - Espace : geler/reprendre la simulation (`GameSpeed.time_scale` mis à 0 puis restauré).
  - N : avancer d'une frame physique pendant que la simulation est gelée.
  - H : forcer la faim de tous les personnages vivants à 95 (déclenche une cueillette au
    prochain contact avec une ronce).
  - E : forcer la faim de tous les personnages vivants à 40 (déclenche un repas si le
    personnage porte une mûre).
  - F1-F4 : téléporter le personnage correspondant au contact de la ronce la plus proche
    (liste `_ronces` alimentée dans `_spawn_ronce`).
  - Chaque déclenchement est loggé (catégorie `dev` dans `GameLogger`).
- Aucun outil dédié n'a été ajouté côté `character.gd` : les leviers nécessaires (faim,
  position, mémoire) étaient déjà exposés en tant que propriétés du script et pilotables
  depuis `main.gd`.
- `scripts/ui_manager.gd` : bandeau "MODE DEV" centré en haut de l'écran (visible
  uniquement si `dev_mode` passé à `setup()`), rappelant la liste des raccourcis.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — UX de checklist en jeu [TODO]
- Panneau listant les tests issus de `tests_manuels.md` (par catégorie), avec pour chacun :
  case validé/invalidé + champ commentaire libre.
- Sauvegarde des résultats dans un fichier (ex. `logs/dev_session_<horodatage>.json` ou
  équivalent) : id du test, statut, commentaire.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Restitution et bouclage [TODO]
- Lecture du fichier de résultats en session Claude Code.
- Traitement test par test : tests validés retirés de `tests_manuels.md`, tests invalidés
  ou commentés transformés en actions concrètes (bug à corriger, ajustement à faire).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
