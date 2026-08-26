## v0.17 — 2026-08-26

### Ajouté
- Phase 7 close : décideur de personnage interchangeable (`automate`/`llm`/`llm_mock`) via
  `scripts/llm_decider.gd`, backend Ollama local, repli automatique sur l'automate en cas de
  timeout/erreur/indisponibilité réseau. L'intention "manger" route via `memory_direction`
  (même précision de visée que l'automate). Logging complet prompt/réponse.
- `VariableRegistry` : support des types `enum`/`string` (nouvelles variables `decider_type`,
  `llm_model`, `llm_decision_interval_seconds`, `llm_timeout_seconds`).
- Scénarios et campagne comparative : `experiments/llm_mock_smoke_v1.json`,
  `experiments/llm_vs_automate_v1.json`, `experiments/campaigns/llm_vs_automate_v1.json`.

### Modifié
- `tools/aggregate_results.py` : métriques LLM agrégées (appels, taux d'erreur, latence).
- `scripts/ui_manager.gd` : correctif d'affichage de l'Inspecteur pour les types texte.

### Corrigé
- `HTTPRequest` threadé restait bloqué jusqu'au timeout dans la scène complète (contention du
  `WorkerThreadPool` de Godot) — corrigé par `use_threads = false`.
- Modèle `gemma3:4b` écarté après effondrement sur une réponse fixe indépendante du contexte ;
  `gemma3:1b` retenu comme référence (voir `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`).

## v0.16 — 2026-08-25

### Ajouté
- Phase 6 close : trois mécaniques sociales avancées — communication (partage inconditionnel
  d'une position de roncier mémorisée), coopération (partage de nourriture si faim critique de
  l'autre) et agressivité (répulsion imposée), chacune avec sa variable dans `VariableRegistry`.
- Scénarios de validation dédiés : `experiments/social_communication_smoke_v1.json`,
  `social_cooperation_smoke_v1.json`, `social_aggression_smoke_v1.json`.

### Modifié
- `scripts/main.gd`, `tools/aggregate_results.py` : nouvelles métriques sociales exportées et
  agrégées (partages, réceptions, incidents d'agressivité).
- Roadmap : Phase 6 marquée [FAIT], Phase 7 (LLM) débloquée.

### Corrigé
- ROBERTO (`voice-code-bridge`) : la demande de permission de notification push n'était
  déclenchée que par le bouton micro, jamais par l'envoi de texte — corrigé. Ajout d'un
  système de choix rapide par boutons dans l'appli mobile.

## v0.15 — 2026-08-25

### Ajouté
- Trois campagnes de référence (`memory_capacity`, `resource_scarcity`, `contrasted_profiles`)
  et `tools/plot_campaign.py` (graphiques SVG sans dépendance externe) — clôture de la Phase 4.
- Inspecteur générique dans l'UI, piloté par `VariableRegistry` (sélecteur agent/catégorie,
  tags live/dynamique/nécessite-relancer) — clôture de la Phase 5.

### Modifié
- `tools/aggregate_results.py` : métriques `mean_memorized_ronces`, `mean_berries_picked`,
  `mean_berries_eaten` ajoutées.
- Panneaux de coin allégés (Vitesse, Vieillissement, Capacité à se nourrir, Mémoire déplacés
  vers l'Inspecteur) ; confirmation ajoutée avant "Relancer".

### Corrigé
- ROBERTO (`voice-code-bridge`) : script de salutation automatique retiré, le message "salut"
  remonte désormais normalement vers l'agent ; bouton copier ajouté sur les réponses de
  l'appli mobile.

## v0.14 — 2026-08-25

### Corrigé
- `ROBERTO/com_telephone/_commands/com_manager.md` : libération du port 5000 avant tout
  démarrage/redémarrage de `node`, pour éviter l'échec EADDRINUSE causé par un process
  orphelin non tracké.

## v0.13 — 2026-08-24

### Ajouté
- Contrôles automatisés de reproductibilité et de cohérence entre télémétrie JSONL et summary.
- Scénarios de comparaison pour `goal_persistence`, `known_zone_preference` et `curiosity`.

### Modifié
- Les expériences sont bornées par `max_simulation_seconds` ; `max_wall_seconds` reste un alias de migration.
- Configuration fixe et état initial dynamique sont distingués dans `ExperimentConfig`.

## v0.12 — 2026-08-24

### Ajouté
- Launcher `run_rl.py` pour le mode RL (`IA_LIFE_RL_MODE`) ; premier épisode complet validé
  via `rl/client_random.py`.
- Tests automatisés `ExperimentConfig` (défauts, overrides, validation) dans
  `tools/run_manual_checks.gd`.

### Modifié
- `VariableRegistry` enrichi (libellé, description, portée, catégorie, défaut, dynamique,
  live_editable) ; `GameConfig` et `Character` lisent leurs valeurs par défaut depuis le
  registre.
- `DESIGN/roadmap_graphisme.md` et son contexte réconciliés avec l'état réel (Phases 2-5
  closes).

### Décidé
- Cadre non historique (île isolée) retenu pour l'identité du jeu — voir
  `DOCUMENTATION/orientation_contexte.md`.

## v0.11 — 2026-08-23

### Ajouté
- Contrat d'expérience versionné, validation des variables, événements environnementaux,
  campagnes reproductibles, logs JSONL, résumés et agrégation de résultats.
- Perception sociale, suivi et évitement paramétrables avec métriques dédiées.
- Dossier DOCUMENTATION et commande `python tools/run_smoke_tests.py`.

### Modifié
- Le rig Blender est officiellement réservé au personnage de développement.

## v0.9 — 2026-08-22

### Modifié
- Ronces refondues visuellement : buisson vert réaliste (7 lobes, couleur fixe qui ne
  change plus quand le roncier est vide) + mûres noires visibles sur le buisson (une
  sphère par mûre restante), retrait visuel d'une mûre à chaque cueillette ; suppression
  de la bascule plein/vide par matériaux.
- Sliders "Capacité à se nourrir" / "Mémoire" dans le panneau "Personnage de test" (mode
  dev) et détail de test scrollable dans la checklist.

### Validé
- Test manuel 5 ("Capacité à se nourrir" : gain de PV proportionnel au slider) confirmé
  en jeu et retiré de `tests_manuels.md` — restent les items 6, 8-12.

## v0.8 — 2026-08-18

### Ajouté
- Personnage riggé (Phase 5 graphisme) : armature + animations Idle/Walk/Death générées via
  Blender headless (`tools/blender/build_character.py` -> `assets/models/character.glb`),
  intégré uniquement sur le personnage de test (mode dev).
- Blender installé localement (`D:\blender`) pour régénérer le modèle sans dépendance
  externe.
- Touche K (mode dev) : tue le personnage de test à la demande (vérifie l'animation Death).
- Touche G (mode dev) : force la faim haute (déclenche la cueillette). Shift+F1-F4 :
  téléporte un personnage au contact de la ronce la plus proche (F1-F4 seul téléporte
  désormais au centre de la map).
- Persistance des réglages du jeu sur disque (`GameConfig`, `logs/game_config.json`) et
  nouveau réglage "Intensité lumineuse".

### Modifié
- Checklist en jeu (Phase 3 mode dev) : sélection individuelle par test (panneau détail
  Valide/Invalide/Fermer) au lieu d'un formulaire global, état persisté par test
  (`logs/dev_checklist_state.json`), masquage automatique des tests déjà validés.
- Caméra orbite (personnage de test) : correctif du pitch inversé, clamp au-dessus du
  terrain.

### Corrigé
- Items 1-4 de `tests_manuels.md` (bascule ronce, animation procédurale des 4 personnages,
  cueillette/consommation de base) validés et retirés après confirmation en jeu.

## v0.7 — 2026-08-18

### Ajouté
- Phase 3 du mode dev : checklist de tests manuels en jeu (touche T), sauvegarde des
  résultats dans `logs/dev_session_<horodatage>.json`.
- Personnage de test contrôlable manuellement (mode dev) : touche F5, déplacement ZQSD
  relatif à une caméra en orbite 3e personne pilotée à la souris, immortel. Remplace la
  dépendance à la téléportation F1-F4 seule pour observer cueillette/collision en direct.
  Panneau "Personnage de test" (mûres portées/ramassées, faim) en bas d'écran.
- Suivi caméra automatique lors d'une téléportation F1-F4.
- Aplanissement léger du terrain autour du spawn central (personnage de test).

### Modifié
- Touches dev réaffectées : H = forcer faim basse (repas), E = réservée à une future
  action du personnage de test (aucun effet pour l'instant).
- Luminosité ambiante réduite de 10%.

### Corrigé
- Propriété invalide `directional_shadow_normal_bias` (Godot 4.5) -> `shadow_normal_bias`.

## v0.6 — 2026-08-17

### Ajouté
- Mode dev (`run_dev.py`, `IA_LIFE_DEV_MODE`) : raccourcis clavier de déclenchement
  contrôlé (geler/reprendre la simulation, avancer d'une frame, forcer la faim,
  téléporter un personnage au contact d'une ronce), bandeau UX "MODE DEV" et indicateur
  "Temps gelé" — pour tester les mécaniques bloquées en observation directe.

### Corrigé
- Scène qui apparaissait comme une scène de nuit malgré la luminosité augmentée en
  session précédente : ciel, lumière directionnelle et exposition retravaillés (vérifié
  par capture d'écran automatisée avant/après).

### Validé
- Terrain, relief, cuvettes de spawn, faim/vieillissement/mort, vitesse de simulation et
  absence de clignotement de texture d'herbe — confirmés manuellement en jeu.

## v0.5 — 2026-08-17

### Ajouté
- Capture d'écran automatisée (`run_screenshot.py`) : lance le jeu en fenêtre réelle,
  sauvegarde le viewport en PNG après un délai, permet une vérification visuelle sans
  intervention manuelle.
- Relief procédural rendu plus escarpé (amplitude 1.2 -> 5.0) et cuvettes de spawn
  (dépression douce) autour des 4 points d'apparition des personnages.
- Skill `synthese-projet` : génère un état des lieux complet du projet (personnages,
  variables du monde, carte, UX, outillage) dans `_docs/`, avec archivage automatique
  des synthèses précédentes.

### Corrigé
- Bug de rendu majeur : le terrain était invisible depuis le dessus (winding de mesh
  inversé, culling par défaut de Godot), diagnostiqué à tort au premier abord comme un
  problème de texture puis d'auto-ombrage. Corrigé par `render_mode cull_disabled` sur
  le shader triplanar.

### Modifié
- Luminosité de la scène augmentée (énergie de la lumière directionnelle, exposition du
  tonemap) — non validée visuellement de façon décisive.

## v0.4 — 2026-08-17

### Ajouté
- Matériaux PBR CC0 (Poly Haven) via shader triplanar pour le sol et les murs ; ronces
  remodelées en buisson (cluster de sphères).
- Animation procédurale des personnages : orientation vers la direction de déplacement,
  bobbing de marche, animation de mort progressive (tween).
- Cycle caméra 3 clics sur le nom d'un personnage : 3e personne, 1re personne ("yeux",
  regard souris contraint à ~±90° de lacet / ~±63° de tangage relatif au corps), retour
  exact à la caméra précédente.
- Terrain à relief procédural (bruit simplex + `HeightMapShape3D`, aplani en bordure de
  map) et décor procédural (rochers, arbres), en remplacement du sol plat — choisi plutôt
  que le plugin Terrain3D pour rester cohérent avec l'approche "tout par code" du projet.

### Connu
- Clignotement occasionnel de la texture d'herbe non résolu (aliasing spéculaire probable).

## v0.3 — 2026-08-17

### Ajouté
- Cueillette de mûres (ronces) : cueillette/consommation automatiques selon seuils de
  faim, capacité à se nourrir par personnage, modale "Données du jeu" configurable en
  direct (`GameConfig`).
- Mode headless (`run_headless.py`) + skills `analyse-partie`/`experimentation-headless`
  pour tester des réglages sans interface.
- Logging complet de session (`GameLogger`), archivé dans `logs/`.
- Mémoire spatiale des ronciers par personnage (capacité 0-10, renforcement/oubli
  progressif), avec retour ciblé vers le roncier mémorisé le plus proche en cas de faim.
- Collision physique des ronces (`StaticBody3D`), en complément de la détection.

### Modifié
- Vitesse de simulation étendue jusqu'à x50 (plafond headless recommandé x80).
- Caméra : suivi continu d'un personnage + zoom molette, bouton "Large" pour revenir au
  plan d'ensemble.
- Panneaux perso toujours visibles avec sections repliables ; distribution équitable des
  ronces par quadrant de map.

## v0.2 — 2026-08-17

### Ajouté
- Analyse du rendu graphique actuel et pistes d'amélioration gratuites (DESIGN/pistes_graphisme.md).
- Roadmap graphisme en 6 phases (DESIGN/roadmap_graphisme.md).

### Modifié
- Contrainte "personnages sans animation" levée — animation (marche/idle) intégrée au plan.

## v0.1 — 2026-08-17

### Ajouté
- Scaffold Godot programmatique : map 160x160, 4 personnages lowpoly, murs, caméra libre
  ZQSD, `run.py`.
- Déplacement aléatoire avec rebond aux collisions, zone de déplacement par personnage.
- Menu bas d'écran : panneaux de stats/édition par personnage (coins), focus caméra au
  clic, slider de vitesse de simulation globale, bouton de reset complet.
- Système de faim/vieillissement/mort par personnage.
- Archive des décisions d'évolution (`_docs/decisions/`).
## v0.10 — 2026-08-23

### Ajouté
- Suite automatisée `tools/run_manual_checks.py` pour les tests de paramètres et de mémoire
  (6, 8, 9, 10 et 11).
- Touche E du personnage de test : ramasse une mûre proche en mode dev.

### Corrigé
- Retrait du log de diagnostic temporaire du déplacement ; enfoncement visuel des personnages
  et rendu des ronces/mûres validés.

### Modifié
- Roadmap du mode dev clôturée et archivée dans `_docs/archives/2026-08-23_roadmap_mode-dev.md`.
## v0.12 — 2026-08-24

### Ajouté
- Documentation de la voie RL rapide et premier bridge TCP/JSONL avec client random.

### Modifié
- Le personnage Rouge peut recevoir une action RL `Discrete(7)` en mode `IA_LIFE_RL_MODE`.

### Corrigé
- Contrat RL : pas de décision de 0,25 s simulée et récompense de survie à +0,005/s.
