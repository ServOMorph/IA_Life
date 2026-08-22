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

## Phase 3 — UX de checklist en jeu [FAIT]
- Panneau listant les tests issus de `tests_manuels.md` (par catégorie, sections repliables),
  parsing direct du fichier, validé/invalidé (boutons exclusifs) + champ commentaire libre.
  Touche **T** en mode dev (initialement C, renommée pour éviter un conflit avec le
  déplacement caméra libre).
- Sauvegarde des résultats dans `logs/dev_session_<horodatage>.json` : id, catégorie, statut,
  commentaire. Premier cycle de validation effectué le 2026-08-17 (3 tests renseignés).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Restitution et bouclage [EN COURS]
- Lecture du fichier de résultats en session Claude Code.
- Traitement test par test : tests validés retirés de `tests_manuels.md`, tests invalidés
  ou commentés transformés en actions concrètes (bug à corriger, ajustement à faire).
- Premier cycle traité (2026-08-17/18) : items 1-3 invalidés, tous pour la même cause racine
  (mode dev F1-F4 sans suivi caméra = observation impossible). Actions concrètes tirées :
  - Suivi caméra automatique ajouté sur téléportation F1-F4 (débloque l'item 1, bascule
    plein/vide des ronces désormais testable).
  - Pivot majeur décidé avec l'utilisateur : ajout d'un 5ème personnage de test contrôlable
    manuellement (F5, ZQSD + souris, vue 3ème personne orbitale, immortel) — voir
    `_docs/decisions/2026-08-18_personnage-test-controlable.md`. Remplace la dépendance à
    F1-F4 seul pour observer cueillette/collision en direct.
- Deuxième cycle (2026-08-18) : contrôle clavier (ZQSD) du personnage de test confirmé
  fonctionnel (voir `_docs/decisions/2026-08-18_personnage-test-controlable.md`, statut
  validé). Items 1, 2 (Phase 2/3 graphisme), 3 et 4 (cueillette/consommation de base)
  validés et retirés de `tests_manuels.md`. Rig Phase 5 (`roadmap_graphisme.md`, zone
  design) intégré et validé sur le personnage de test uniquement — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.
- Checklist en jeu (Phase 3) retravaillée par l'utilisateur en session : sélection
  individuelle par test (au lieu d'un formulaire global), état persistant
  (`logs/dev_checklist_state.json`), masquage automatique des tests déjà validés.
- Troisième cycle (2026-08-22) : item 5 validé (slider "Capacité à se nourrir", gain de PV
  proportionnel) et retiré de `tests_manuels.md`. Refonte visuelle des ronces demandée
  pour poursuivre la validation (buisson vert + mûres noires visibles, retrait à la
  cueillette) — voir `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`.
- Reste à traiter : items 6, 8-12 de `tests_manuels.md` (étapes précises déjà rédigées),
  confirmation visuelle du rendu ronces/mûres, bug d'enfoncement des personnages dans le
  sol (Phase 4 terrain, toujours ouvert), décision sur le retrait du log de diagnostic
  temporaire (`_test_debug_log_timer`).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
