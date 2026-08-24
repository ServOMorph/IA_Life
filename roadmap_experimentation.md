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

## Phase 1 — Contrat d'expérience et registre de variables [EN COURS — actions closes, reproductibilité seed-à-seed à vérifier]

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

### Critères d'acceptation

- Une même configuration + seed crée le même monde et les mêmes paramètres d'agents.
- Les anciens usages `run.py`, `run_dev.py` et `run_headless.py` restent compatibles.
- Une variable migrée n'est définie qu'une fois pour ses bornes et sa valeur par défaut.
- Des tests couvrent chargement, validation, valeurs par défaut et overrides par agent.

## Phase 2 — Baseline comportemental et perception [À FAIRE]

### But

Rendre les décisions déterministes actuelles explicites et comparables avant de créer de
nouveaux traits.

### Actions

- [x] Isoler le système décisionnel actuel derrière une interface minimale : perception,
  état interne, décision, action.
- [x] Exposer l'objectif courant de chaque agent (errance, ressource mémorisée,
  cueillette, consommation) et le journaliser lors de chaque changement.
- [~] Ajouter les premières variables à fort pouvoir discriminant : `exploration_tendency`
  est disponible ; `curiosity`, `goal_persistence`, `risk_tolerance` et préférence pour
  zones connues restent à concevoir.
- [~] Ne relier chaque trait qu'à des règles locales documentées et testées ;
  `exploration_tendency` réduit linéairement l'intervalle entre réorientations d'errance
  (0,5 est neutre). La métrique associée est `wander_reorientations_total`, également
  journalisée dans les événements `decision`. Aucun profil nommé (« explorateur »,
  « prudent ») n'est codé en dur.
- [ ] Distinguer configuration fixe et état dynamique (fatigue, confiance ou peur futurs)
  afin que seules les premières soient modifiables pendant un run comparable.

### Critères d'acceptation

- Les agents peuvent recevoir des profils différents depuis `ExperimentConfig`.
- Chaque nouveau trait produit au moins une différence mesurable dans une expérience
  contrôlée, sans rendre l'exécution non déterministe à seed fixe.
- Les mécaniques actuelles de faim, mémoire, cueillette et mort restent validées.

## Phase 3 — Télémétrie et résultats normalisés [À FAIRE]

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

### Critères d'acceptation

- Chaque run headless laisse un dossier de résultats autonome et parseable.
- Les métriques de base correspondent aux compteurs et logs du jeu sur un scénario court.
- Une agrégation de plusieurs runs calcule taux de survie, durée moyenne, distance,
  découvertes, revisites et variance entre agents.

## Phase 4 — Campagnes expérimentales [À FAIRE]

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
- [ ] Produire un tableau de synthèse et des graphiques simples pour comparer les groupes.
- [ ] Formaliser trois expériences de référence : capacité mémoire, rareté des ressources
  et profils individuels contrastés, chacune sur plusieurs seeds.

### Critères d'acceptation

- Une campagne est relançable sans écraser ses résultats précédents.
- Le rapport indique exactement les paramètres et seeds associés à chaque ligne.
- Les trois expériences de référence donnent des résultats comparables et reproductibles.

## Phase 5 — Interface d'inspection scalable [À FAIRE]

### But

Permettre l'observation interactive sans encombrer les panneaux des quatre agents.

### Actions

- [ ] Créer un composant générique de variable, généré depuis le registre (libellé,
  valeur, bornes, description/tooltip, lecture seule si état dynamique).
- [ ] Ajouter un panneau Inspecteur avec sélecteur d'agent et filtres par catégorie.
- [ ] Retirer des panneaux de coin les sliders dupliqués ; ils gardent faim, état de vie,
  compteurs et indicateurs critiques.
- [ ] Identifier visuellement si un changement est expérimental, temporaire ou exige le
  redémarrage de l'expérience.
- [ ] Ajouter une confirmation avant Relancer et une indication claire que le comportement
  courant est déterministe tant qu'aucun module LLM n'est activé.

### Critères d'acceptation

- Ajouter une variable au registre la rend disponible sans ajouter de code UI spécifique.
- Les quatre agents restent lisibles en vue d'ensemble.
- L'UI ne permet pas de modifier silencieusement un état dynamique pendant une campagne.

## Phase 6 — Environnement dynamique et interactions sociales [À FAIRE]

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
- [ ] Reporter coopération, communication et agressivité tant que les deux mécanismes de
  base ne sont ni stables ni mesurés.

### Critères d'acceptation

- Les événements et interactions sont activables/désactivables par configuration.
- Un scénario contrôle démontre une différence statistique mesurable entre suivi et
  évitement sur plusieurs seeds.

## Phase 7 — Décideurs interchangeables et LLM [BLOQUÉ PAR LES PHASES 1 À 6]

### But

Comparer équitablement automate, comportement paramétrable et LLM dans le même monde.

### Actions

- [ ] Stabiliser l'interface de décision : observation structurée en entrée, action
  validée en sortie, budget de temps et gestion des erreurs.
- [ ] Implémenter l'adaptateur de l'automate existant comme référence de comparaison.
- [ ] Définir un adaptateur LLM sans accès direct à l'état interne du jeu, avec une action
  limitée au même espace d'actions que la référence.
- [ ] Logger prompt/réponse de manière traçable et sûre, avec identifiant de modèle,
  paramètres et latence ; exclure secrets et données sensibles des logs.
- [ ] Prévoir timeout, réponse invalide, indisponibilité réseau et mode simulation locale.
- [ ] Exécuter des campagnes comparatives LLM / règles / profils paramétrables.

### Critères d'acceptation

- Les trois décideurs sont comparés avec une même configuration et les mêmes seeds.
- Chaque action LLM est validée, rejouable dans les limites documentées et mesurée.
- Aucun appel externe ne peut bloquer ou corrompre une campagne.

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

1. Prendre et documenter la décision sur le rig (Phase 0, en parallèle du code).
2. Écrire le schéma `ExperimentConfig` v1 et les tests de validation.
3. Créer `VariableRegistry`, migrer les variables existantes sans changer l'UI.
4. Journaliser configuration normalisée, seed et version de projet dans chaque session.
5. Lancer deux fois la même expérience puis comparer automatiquement les résultats pour
   démontrer la reproductibilité avant d'ajouter la moindre nouvelle variable.
