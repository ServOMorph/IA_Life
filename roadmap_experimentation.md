# Roadmap — Laboratoire d'expérimentation IA_Life

Créée le : 2026-08-23
Objectif : faire évoluer le prototype Godot actuel vers un laboratoire reproductible
pour observer et comparer des comportements individuels et collectifs, puis y brancher
des systèmes décisionnels interchangeables, dont un LLM.

## Principes de conduite

- Une expérience décrit explicitement son environnement, ses agents, ses règles, ses
  événements, sa seed et ses limites d'exécution.
- Les comportements observés ne sont jamais codés comme des objectifs directs. Ils
  résultent de traits, règles locales, perceptions et interactions.
- Toute évolution expérimentale doit être exécutable en headless, mesurable et
  reproductible avant de devenir un réglage d'interface avancé.
- Le LLM n'est introduit qu'après établissement d'un baseline déterministe et mesurable.
- Le travail graphique reste découplé : il ne doit pas bloquer les phases expérimentales.

## État de départ vérifié

- Les quatre agents suivent aujourd'hui un automate de déplacement, mémoire et
  cueillette ; aucun LLM ni interaction sociale n'est branché.
- Les overrides headless, le logging de session et les vérifications automatisées
  existent déjà.
- Les réglages sont dispersés entre `GameConfig`, `Character` et l'UI, qui crée les
  sliders explicitement : cette architecture ne supportera pas les 20 à 30 traits visés.
- Le personnage riggé est validé pour le personnage de test uniquement. Décision du
  2026-08-23 : il reste limité au personnage de développement ; les quatre agents normaux
  conservent leur représentation légère pendant la priorité expérimentale.

## Phase 0 — Assainissement et contrats de référence [FAIT]

### But

Éliminer les divergences entre l'état réel, les roadmaps et la documentation, afin que
les expériences reposent sur un périmètre validé.

### Actions

- [x] Décider explicitement si le rig `assets/models/character.glb` est étendu aux quatre
  agents normaux ou reste limité au personnage de test : il reste limité au personnage de
  développement.
- [x] Mettre à jour la décision associée et clore la Phase 5 graphique dans le périmètre
  effectivement retenu pour le laboratoire expérimental.
- [x] Cadrer l'identité du projet avant d'ajouter du contenu : comparer l'intégration d'un
  contexte historique (dont le Paléolithique ancien) avec au moins un autre concept de
  monde/narration, puis documenter le choix, ses anachronismes à éviter et ses conséquences
  sur les mécaniques expérimentales. Décision du 2026-08-24 : cadre non historique (île
  isolée) — voir `DOCUMENTATION/orientation_contexte.md`.
- [x] Réconcilier `DESIGN/roadmap_graphisme.md` et `DESIGN/_contexte/signals.md` avec les
  validations déjà réalisées (phases 2 à 5 et rendu des ronces). Fait le 2026-08-24 : Phases
  2-5 marquées [FAIT], actions obsolètes retirées de `DESIGN/_contexte/signals.md`.
- [x] Actualiser la synthèse projet, devenue historique, sans effacer les archives. Fait le
  2026-08-24 : `_docs/2026-08-24_16h11_synthese-projet.md`, ancienne version archivée.
- [x] Établir une commande de smoke test reproductible : lancement headless, contrôles
  automatisés existants et vérification de création de log avec
  `python tools/run_smoke_tests.py`.

### Délégation design

Le chantier est déléguable à l'agent `design` : il met à jour exclusivement les fichiers
de `DESIGN/`, propose le choix de rig et ses critères de validation. Les fichiers déjà
modifiés dans `DESIGN/` doivent être relus et préservés avant toute modification.

### Critères d'acceptation

- Une seule source décrit l'état graphique réel et le choix de rig est documenté.
- Si le rig est étendu : les quatre agents conservent couleur, collision, hauteur terrain
  et comportements ; Idle, Walk et Death sont validés sans glissement prolongé.
- Le smoke test est vert et une session produit un log exploitable.

## Phase 1 — Contrat d'expérience et registre de variables [FAIT]

### But

Créer une source de vérité unique pour toute variable expérimentale, indépendamment de
l'UI et du mode d'exécution.

### Actions

- [x] Définir un format versionné `ExperimentConfig` (JSON) : `experiment_id`,
  `seed`, `environment`, `agents`, `simulation`, `events` et métadonnées de version.
- [x] Ajouter `VariableDef` et `VariableRegistry` : identifiant, libellé, description,
  portée (globale/individuelle), catégorie, type, bornes, défaut, caractère dynamique et
  modification live autorisée. Fait le 2026-08-24 : `scripts/variable_registry.gd` enrichi
  (`label`, `description`, `scope`, `category`, `default`, `dynamic`, `live_editable`) pour
  les 7 variables de `GameConfig` et les 11 variables de `Character` déjà validées.
- [x] Migrer sans changement fonctionnel les variables existantes de `GameConfig` et
  `Character` dans le registre : vitesse, exploration, faim, vieillissement, capacité de
  nourriture, mémoire et paramètres des ronces. Fait le 2026-08-24 : `game_config.gd` et
  `character.gd` lisent désormais leur valeur par défaut depuis `VariableRegistry` (valeurs
  numériques inchangées) ; smoke test vert après migration.
- [x] Valider les overrides entrants à partir du registre et rejeter les clés, types ou
  valeurs hors bornes avec une erreur exploitable.
- [x] Charger une configuration complète avant la construction de la scène ; appliquer
  d'abord les valeurs globales, puis les valeurs individuelles par nom d'agent.
- [x] Journaliser, au démarrage, la configuration normalisée complète, la seed, l'ID,
  le hash/commit du projet si disponible et les options d'exécution.
- [x] Vérifier la reproductibilité seed-à-seed sur deux runs headless identiques. Fait le
  2026-08-24 : `tools/check_reproducibility.py` compare deux summaries (hors `session_id`).
  La limite d'arrêt est désormais `max_simulation_seconds`, comptée sur les ticks physiques ;
  l'ancien `max_wall_seconds` reste un alias de migration.

### Critères d'acceptation

- Une même configuration + seed crée le même monde et les mêmes paramètres d'agents.
- Les anciens usages `run.py`, `run_dev.py` et `run_headless.py` restent compatibles.
- Une variable migrée n'est définie qu'une fois pour ses bornes et sa valeur par défaut.
- Des tests couvrent chargement, validation, valeurs par défaut et overrides par agent.

## Phase 2 — Baseline comportemental et perception [FAIT]

### But

Rendre les décisions déterministes actuelles explicites et comparables avant de créer de
nouveaux traits.

### Actions

- [x] Isoler le système décisionnel actuel derrière une interface minimale : perception,
  état interne, décision, action.
- [x] Exposer l'objectif courant de chaque agent (errance, ressource mémorisée,
  cueillette, consommation) et le journaliser lors de chaque changement.
- [x] Ajouter les premières variables à fort pouvoir discriminant : `exploration_tendency`,
  `goal_persistence`, `known_zone_preference` et `curiosity` sont disponibles.
  `risk_tolerance` est reportée jusqu'à l'introduction d'un danger environnemental mesurable.
  Fait le 2026-08-24 : `goal_persistence` prolonge
  localement la direction d'errance (0,5 neutre), tandis que `known_zone_preference`
  attire l'errance vers la zone déjà visitée la plus proche et `curiosity` favorise une
  direction candidate vers une cellule inconnue ; scénarios associés dans `experiments/`.
- [x] Ne relier chaque trait qu'à des règles locales documentées et testées ;
  `exploration_tendency` réduit linéairement l'intervalle entre réorientations d'errance
  (0,5 est neutre), tandis que `goal_persistence` l'allonge linéairement (0,5 est neutre).
  La métrique associée est `wander_reorientations_total`, également journalisée dans les
  événements `decision`, tandis que `curiosity` favorise une cellule inconnue et
  `known_zone_preference` favorise une cellule connue. Aucun profil nommé (« explorateur »,
  « prudent ») n'est codé en dur.
- [x] Distinguer configuration fixe et état dynamique (fatigue, confiance ou peur futurs)
  afin que seules les premières soient modifiables pendant un run comparable. Fait le
  2026-08-24 : `agents.initial_state` porte les états dynamiques au démarrage (faim) ;
  les validateurs refusent leur présence dans `agents.defaults` ou `agents.individual`.

### Critères d'acceptation

- Les agents peuvent recevoir des profils différents depuis `ExperimentConfig`.
- Chaque nouveau trait produit au moins une différence mesurable dans une expérience
  contrôlée, sans rendre l'exécution non déterministe à seed fixe.
- Les mécaniques actuelles de faim, mémoire, cueillette et mort restent validées.

## Phase 3 — Télémétrie et résultats normalisés [FAIT]

### But

Passer de logs narratifs à des données analysables automatiquement.

### Actions

- [x] Conserver les logs lisibles existants et ajouter un journal structuré par session
  (JSON Lines documenté).
- [x] Enregistrer les événements, positions échantillonnées, objectifs, faim, distance
  parcourue, durée de vie, découvertes, revisites et ressources consommées.
- [x] Produire à la fin de chaque run headless normal un `summary.json` : statut, durée,
  survie, statistiques par agent et métadonnées d'expérience.
- [x] Définir précisément les métriques « zone visitée », « découverte », « revisite » et
  « regroupement » pour éviter des résultats ambigus : une zone est une cellule de 10 m ;
  découverte = première entrée, revisite = retour après sortie, regroupement = durée avec
  au moins un voisin dans le rayon social.
- [x] Créer un outil de validation de schéma et un outil d'agrégation des résumés.
  Fait le 2026-08-24 : `tools/check_telemetry.py` vérifie aussi la cohérence entre les
  compteurs de zones du summary et les événements JSONL.

### Critères d'acceptation

- Chaque run headless laisse un dossier de résultats autonome et parseable.
- Les métriques de base correspondent aux compteurs et logs du jeu sur un scénario court.
- Une agrégation de plusieurs runs calcule taux de survie, durée moyenne, distance,
  découvertes, revisites et variance entre agents.

## Phase 4 — Campagnes expérimentales [FAIT]

### But

Faire de `run_headless.py` le moteur de comparaisons automatisées.

### Actions

- [x] Ajouter une définition de campagne : configuration de base, grille de paramètres,
  liste de seeds, répétitions, timeout et dossier de sortie.
- [x] Générer une configuration par exécution et conserver son fichier exact avec les
  résultats.
- [x] Ajouter l'exécution séquentielle robuste, la reprise après interruption et un
  rapport d'échecs explicite ; le parallélisme n'est ajouté qu'après validation de
  l'isolation des fichiers et de Godot.
- [x] Produire un tableau de synthèse et des graphiques simples pour comparer les groupes.
  Fait le 2026-08-25 : `tools/plot_campaign.py` génère des graphiques SVG en barres à
  partir du CSV agrégé (aucune dépendance externe) ; `tools/aggregate_results.py` expose
  désormais aussi `mean_memorized_ronces`, `mean_berries_picked`, `mean_berries_eaten`.
- [x] Formaliser trois expériences de référence : capacité mémoire, rareté des ressources
  et profils individuels contrastés, chacune sur plusieurs seeds. Fait le 2026-08-25 :
  `experiments/campaigns/memory_capacity_campaign_v1.json`,
  `resource_scarcity_campaign_v1.json`, `contrasted_profiles_campaign_v1.json` (seeds 1/2/3
  chacune) ; résultats et interprétation dans `experiments/README.md` (section « Campagnes
  de référence »).

### Critères d'acceptation

- Une campagne est relançable sans écraser ses résultats précédents.
- Le rapport indique exactement les paramètres et seeds associés à chaque ligne.
- Les trois expériences de référence donnent des résultats comparables et reproductibles.

## Phase 5 — Interface d'inspection scalable [FAIT]

### But

Permettre l'observation interactive sans encombrer les panneaux des quatre agents.

### Actions

- [x] Créer un composant générique de variable, généré depuis le registre (libellé,
  valeur, bornes, description/tooltip, lecture seule si état dynamique). Fait le
  2026-08-25 : `_build_variable_field()` dans `ui_manager.gd`, piloté par
  `VariableRegistry.CHARACTER`.
- [x] Ajouter un panneau Inspecteur avec sélecteur d'agent et filtres par catégorie. Fait le
  2026-08-25 : bouton "Inspecteur" dans la barre de menu, `OptionButton` agent + catégorie.
- [x] Retirer des panneaux de coin les sliders dupliqués ; ils gardent faim, état de vie,
  compteurs et indicateurs critiques. Fait le 2026-08-25 : Vitesse, Vieillissement, Capacité
  à se nourrir et Mémoire retirés (disponibles dans l'Inspecteur) ; Exploration reste (hors
  registre) ; faim, historique et état de vie inchangés.
- [x] Identifier visuellement si un changement est expérimental, temporaire ou exige le
  redémarrage de l'expérience. Fait le 2026-08-25 : tag coloré par champ ("live" vert,
  "dynamique" gris, "nécessite Relancer" orange).
- [x] Ajouter une confirmation avant Relancer et une indication claire que le comportement
  courant est déterministe tant qu'aucun module LLM n'est activé. Fait le 2026-08-25 :
  `ConfirmationDialog` avant `_on_reset_pressed()`, note fixe dans le panneau Inspecteur.

Vérifié visuellement par l'utilisateur le 2026-08-25 (tests manuels 15 et 16, validés puis
retirés de `tests_manuels.md`).

### Critères d'acceptation

- Ajouter une variable au registre la rend disponible sans ajouter de code UI spécifique.
- Les quatre agents restent lisibles en vue d'ensemble.
- L'UI ne permet pas de modifier silencieusement un état dynamique pendant une campagne.

## Phase 6 — Environnement dynamique et interactions sociales [FAIT]

### But

Augmenter progressivement la complexité du monde, puis les interactions entre agents.

### Actions environnement

- [x] Implémenter des événements temporels déclarés dans `ExperimentConfig` : apparition
  et disparition de ressources.
- [x] Journaliser chaque événement et son effet mesuré sur les agents.
- [x] Ajouter un scénario de rupture : suppression d'une proportion de ressources à un
  instant donné.

### Actions sociales

- [x] Ajouter détection/perception d'autres agents et une mémoire sociale minimale.
- [x] Introduire, l'une après l'autre, les règles locales de suivi et d'évitement avec
  paramètres `social_radius`, `follow_probability` et `avoid_probability`.
- [x] Mesurer rencontres, durées de regroupement, suivis et évitements : les compteurs sont
  présents dans le résumé de run et leurs moyennes sont calculées par groupe de campagne.
- [x] Communication, coopération et agressivité implémentées le 2026-08-25 (mécanismes de
  suivi/évitement stables et mesurés au préalable). Communication : partage inconditionnel
  d'une position de roncier mémorisée (`communication_probability`). Coopération : partage
  d'une mûre portée avec un agent rencontré dont la faim est sous le seuil de consommation
  (`cooperation_probability`). Agressivité : répulsion imposée à un agent rencontré,
  indépendamment de son propre choix (`aggression_probability`). Détail et justification des
  choix : `_docs/decisions/2026-08-25_phase6-mecaniques-sociales-avancees.md`.

### Critères d'acceptation

- Les événements et interactions sont activables/désactivables par configuration.
- Un scénario contrôle démontre une différence statistique mesurable entre suivi et
  évitement sur plusieurs seeds.

Communication et agressivité validées de façon fiable par un scénario de simulation dédié
(`experiments/social_communication_smoke_v1.json`, `social_aggression_smoke_v1.json`).
Coopération validée fonctionnellement (`social_cooperation_smoke_v1.json`) mais seulement en
configuration généreuse (beaucoup de ronciers, rayon large, longue durée) — pas de preuve
statistique multi-seeds à ce stade, à traiter en campagne dédiée si nécessaire.

## Phase 7 — Décideurs interchangeables et LLM [FAIT]

### But

Comparer équitablement automate, comportement paramétrable et LLM dans le même monde.

### Actions

- [x] Stabiliser l'interface de décision : observation structurée en entrée, action
  validée en sortie, budget de temps et gestion des erreurs. Fait le 2026-08-26 :
  validation défensive de l'action retournée dans `character.gd::_apply_decision`
  (garde-fou indépendant du décideur), timeout configurable par agent.
- [x] Implémenter l'adaptateur de l'automate existant comme référence de comparaison.
  `BaselineDecider` inchangé, utilisé tel quel comme référence.
- [x] Définir un adaptateur LLM sans accès direct à l'état interne du jeu, avec une action
  limitée au même espace d'actions que la référence. Fait le 2026-08-26 :
  `scripts/llm_decider.gd` (`decider_type` : `automate`/`llm`/`llm_mock`) ; l'intention
  "manger" route via `memory_direction` (même précision de visée que l'automate) — limitation
  documentée pour "suivre"/"eviter" (direction cardinale grossière, non testée en pratique
  car `social_radius` désactivé dans la campagne de référence).
- [x] Logger prompt/réponse de manière traçable et sûre, avec identifiant de modèle,
  paramètres et latence ; exclure secrets et données sensibles des logs. Fait le 2026-08-26 :
  `llm_decision`/`llm_decider_erreur` incluent prompt exact et réponse brute (Ollama local,
  aucun secret transmis).
- [x] Prévoir timeout, réponse invalide, indisponibilité réseau et mode simulation locale.
  Fait le 2026-08-26 : repli automatique sur `BaselineDecider` dans tous les cas, mode
  `llm_mock` déterministe sans appel réseau pour les tests.
- [x] Exécuter des campagnes comparatives LLM / règles / profils paramétrables. Fait le
  2026-08-26 : `experiments/campaigns/llm_vs_automate_v1.json` (3 déciders × 5 seeds),
  résultats dans `results/llm_vs_automate_v1/` (non tracké git).

### Critères d'acceptation

- Les trois décideurs sont comparés avec une même configuration et les mêmes seeds.
- Chaque action LLM est validée, rejouable dans les limites documentées et mesurée.
- Aucun appel externe ne peut bloquer ou corrompre une campagne.

Backend retenu : Ollama local. `gemma3:4b` (modèle initialement choisi) s'est révélé
inutilisable pour ce prompt (réponse quasi fixe "manger"/"E" indépendante du contexte,
0 roncier jamais découvert sur 5 seeds) — pivot vers `gemma3:1b`, qui produit des décisions
variées et cohérentes (survie 40%, proche du mock, contre 65% pour l'automate). Détail complet
(bug HTTPRequest threadé bloqué dans la scène complète, effondrement du modèle, correctifs) :
`_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`. Point ouvert : décider si un
prompt few-shot est nécessaire pour la robustesse multi-modèles avant d'élargir la campagne.

## Phase 8 — Vision et perception générique de l'environnement [FAIT]

### But

Donner aux agents une perception à distance réelle, générique et paramétrable, qui remplace
la découverte par contact comme unique source d'information sur le monde. La vision porte sur
n'importe quelle entité perceptible (ronciers d'abord, agents ensuite, objets futurs sans
modification du système), avec portée, champ de vision et occlusion.

### Constat de départ vérifié (2026-08-26)

- Un roncier n'est mémorisé que par collision physique : `_on_ronce_contact` appelle
  `_remember_ronce` (`scripts/character.gd`). Aucun agent ne peut voir une ressource à distance.
- L'unique perception à distance existante est `social_radius` : un disque omnidirectionnel,
  sans occlusion ni champ de vision, réservé aux autres agents
  (`_update_social_perception`, `scripts/character.gd`). C'est une demi-vision spécialisée.
- Les ronciers ne sont pas exposés en groupe : ils vivent dans `_ronces` (`scripts/main.gd`),
  contrairement aux agents (`add_to_group("agents")`). Aucun contrat de perceptibilité commun
  n'existe aujourd'hui.
- L'observation transmise aux déciders ne contient rien de perçu à distance hors social :
  `has_memories`, `memory_direction`, `social_goal`, `social_direction`
  (`_apply_decision`, `scripts/character.gd`).
- Le prompt LLM ne décrit le monde que par un booléen « a un roncier mémorisé »
  (`_build_prompt`, `scripts/llm_decider.gd`).

### Compatibilité des résultats acquis (contrainte forte)

La vision est une primitive de perception qui aurait relevé de la Phase 2 ; elle est introduite
rétroactivement. Toutes les références produites jusqu'ici (campagnes Phase 4 et
`llm_vs_automate_v1`) l'ont été en découverte-par-contact. En conséquence :

- La valeur par défaut de `vision_range` est `0.0` (vision désactivée), afin que toute
  configuration existante reste reproductible bit-à-bit après l'ajout du système.
- Toute campagne activant la vision constitue une **nouvelle** base de référence et ne se
  compare pas aux résultats antérieurs. Ce point doit être écrit dans la campagne elle-même.

### Actions — primitive de perception

- [x] Définir un contrat de perceptibilité générique, indépendant du type : identité, position,
  type d'entité et état public exposé (ex. un roncier expose s'il porte encore des mûres).
  Aucun accès à l'état interne d'autrui via la vision. Fait le 2026-08-27 :
  `get_perception_type()`/`get_perception_state()` sur `ronce.gd`, groupe `perceptible`.
- [x] Exposer les entités perceptibles par un mécanisme unique et déterministe (groupe Godot ou
  registre central), en remplaçant l'accès direct au tableau `_ronces` pour la perception.
  L'ordre d'itération doit rester stable à seed fixe. Fait le 2026-08-27 : groupe `perceptible`
  peuplé dans `main.gd::_spawn_ronce`.
- [x] Implémenter la fonction de vision : portée, champ de vision angulaire relatif à
  l'orientation de l'agent, et test d'occlusion par le terrain et les obstacles. Fait le
  2026-08-27 : `Character._perceive` (portée, angle, raycast d'occlusion optionnel).
- [x] Ajouter les variables individuelles au registre : `vision_range` (défaut `0.0` = désactivée),
  `vision_angle_degrees` (défaut `360.0` = omnidirectionnel), `vision_blocked_by_terrain`
  (défaut `false`). Chaque variable ajoutée est justifiée par une règle locale documentée. Fait
  le 2026-08-27 : `scripts/variable_registry.gd` (catégorie `perception`), support du type
  `bool` ajouté à `VariableRegistry`.
- [x] Décider explicitement quelle direction définit le champ de vision (orientation affichée
  via `_update_facing`, ou direction de déplacement) et documenter le choix : les deux divergent
  lors des rebonds et des changements d'objectif. Décision du 2026-08-27 : orientation visuelle
  (progressive), plus réaliste — voir `_docs/decisions/2026-08-27_phase8-vision-perception.md`.
- [x] Journaliser chaque première détection d'une entité (`vision`), sans inonder le log :
  un événement par entité nouvellement vue, pas par frame. Fait le 2026-08-27, vérifié dans les
  logs JSONL (catégorie `vision`).

### Actions — exploitation par les déciders

- [x] Étendre l'observation d'une liste structurée des entités visibles (type, direction,
  distance, état public), plus les raccourcis dérivés nécessaires à l'automate. Fait le
  2026-08-27 : `_visible_entities`, `has_visible_ronce`/`visible_ronce_direction` dans
  l'observation.
- [x] Ajouter à `BaselineDecider` la règle d'approche d'un roncier visible, et **trancher
  explicitement la priorité** entre roncier visible et roncier mémorisé (information fraîche
  contre information certaine). La règle retenue est documentée et couverte par un test. Décision
  du 2026-08-27 : priorité au roncier visible, testée (`_test_vision_priority_over_memory`).
- [x] Étendre le prompt LLM à une description structurée de ce qui est visible, en conservant
  le vocabulaire fermé et l'espace d'actions de la référence. L'intention « manger » doit
  pouvoir viser un roncier visible non mémorisé, sans quoi le LLM reste handicapé par rapport
  à l'automate (même nature de biais que le correctif `memory_direction` de la Phase 7). Fait
  le 2026-08-27, validé contre `gemma3:1b` réel (Ollama) — aucune dégradation constatée.
- [x] Faire mémoriser un roncier vu à distance, ou décider explicitement que seule la cueillette
  mémorise. Ce choix modifie la signification de `memory_capacity` et doit être tranché avant
  toute campagne. Décision du 2026-08-27 : mémorisation par vision activée (une fois par
  apparition, pas par frame — voir bug corrigé ci-dessous).

### Action — absorption de `social_radius` (dette technique)

- [x] Faire de la perception des autres agents un cas particulier de la vision, plutôt qu'un
  second système parallèle. Condition de bascule : les scénarios de la Phase 6
  (`social_communication_smoke_v1`, `social_aggression_smoke_v1`,
  `social_cooperation_smoke_v1`) produisent des résultats inchangés à seed fixe avec une vision
  omnidirectionnelle sans occlusion de portée égale à l'ancien `social_radius`.
  Si l'équivalence n'est pas démontrée, conserver les deux systèmes et documenter pourquoi.
  Fait le 2026-08-27 : `_update_social_perception` réutilise `Character._perceive` (code
  partagé, `social_radius` reste un paramètre indépendant) ; équivalence stricte démontrée sur
  les 3 scénarios Phase 6 à seed fixe.

### Actions — mesure et validation

- [x] Ajouter les métriques de perception au résumé de run et à `tools/aggregate_results.py` :
  détections totales, ronciers découverts par vision contre par contact, délai entre première
  vision et premier contact. Fait le 2026-08-27 : `vision_detections_total`,
  `ronces_discovered_by_vision_total`, `vision_to_contact_delay_seconds_total` /
  `vision_to_contact_events_total`.
- [x] Tests de non-régression : `vision_range = 0.0` reproduit exactement les résultats
  antérieurs (contrôle via `tools/check_reproducibility.py`). Vérifié le 2026-08-27.
- [x] Scénarios dédiés : entité dans la portée mais hors du champ de vision (non vue), entité
  dans le champ mais hors de portée (non vue), entité masquée par le relief (non vue si
  `vision_blocked_by_terrain`). Fait le 2026-08-27 : `experiments/vision_baseline_smoke_v1.json`,
  `vision_narrow_angle_smoke_v1.json`, `vision_short_range_smoke_v1.json`,
  `vision_occlusion_smoke_v1.json` (comparatifs, différence mesurable sur chaque filtre).
- [x] Campagne multi-seeds comparant plusieurs valeurs de `vision_range` sur la survie et sur
  le délai de première découverte. Fait le 2026-08-27 :
  `experiments/campaigns/vision_range_campaign_v1.json` (3 valeurs × 3 seeds) — pas de
  différence de survie dans ce scénario (ressources abondantes), différence nette sur la
  vitesse de découverte.

### Critères d'acceptation

- Ajouter un nouveau type d'entité perceptible ne demande aucune modification du système de
  vision lui-même.
- Vision désactivée, les résultats des campagnes antérieures sont reproduits à l'identique.
- La portée, le champ de vision et l'occlusion produisent chacun une différence mesurable dans
  un scénario contrôlé, sans rendre l'exécution non déterministe à seed fixe.
- Les trois déciders (`automate`, `llm_mock`, `llm`) accèdent à la même information visuelle et
  au même espace d'actions.
- Aucun décideur n'accède, via la vision, à une information que l'agent ne pourrait pas percevoir.

### Point d'attention

`curiosity` et `known_zone_preference` (Phase 2) approximent aujourd'hui une recherche
d'inconnu en l'absence de vision. Une fois la vision active, leur interprétation change et leur
utilité doit être réévaluée — sans les retirer avant mesure.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Qualité transverse et jalons de décision

- Après chaque phase : tests automatisés, smoke test headless, mise à jour des décisions
  et de la documentation de contexte.
- À la fin des phases 1, 3 et 4 : revue utilisateur des formats de configuration et de
  résultats avant d'élargir le périmètre.
- Toute nouvelle variable exige : définition dans le registre, règle locale documentée,
  métrique associée, test automatisé et au moins un scénario de démonstration.
- Toute nouvelle mécanique graphique reste dans une roadmap `DESIGN/` et ne modifie pas
  le contrat expérimental sans décision explicite.

## Prochain sprint recommandé

Phases 1 à 8 closes. Aucune Phase 9 définie pour l'instant.

Les deux points ouverts hérités de la Phase 7 sont clos (2026-08-27) : prompt few-shot jugé non
nécessaire (`gemma3:1b` stable avec le prompt étendu par la Phase 8), coopération validée
statistiquement (5 seeds, jamais nulle) — voir `_docs/decisions/`.

Point d'attention hérité de la Phase 8, non retraité : `curiosity` et `known_zone_preference`
(Phase 2) approximent une recherche d'inconnu en l'absence de vision ; leur interprétation
change maintenant que la vision est disponible et reste à réévaluer sans les retirer avant
mesure (voir "Point d'attention" ci-dessus).

Recommandation pour toute future campagne LLM élargie : la vision modifie l'information
disponible en entrée du décideur (Phase 8), donc toute campagne LLM antérieure à la Phase 8
n'est pas comparable à une campagne lancée après.
