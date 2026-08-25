# Configurations d'expérience

`smoke_config_v1.json` est un exemple minimal du format `ExperimentConfig` v1.
Il est compatible avec l'ancien format d'overrides : les clés historiques
`game_config`, `game_speed`, `character_defaults`, `quit_on_all_dead` et
`max_wall_seconds` restent acceptées comme alias de migration de
`max_simulation_seconds`.

Le nouveau format sépare explicitement :

- `experiment_id`, `seed`, `metadata` et `events` ;
- `environment.game_config` pour les règles globales ;
- `agents.defaults` et `agents.individual.<Nom>` pour les paramètres des agents ;
- `agents.initial_state.defaults` et `agents.initial_state.individual.<Nom>` pour les
  états dynamiques au démarrage (actuellement `hunger`) ;
- `simulation` pour vitesse et limites d'exécution ; `max_simulation_seconds` fixe
  la durée simulée, indépendamment de la charge de la machine.

Lancer l'exemple sous Windows :

```powershell
python run_headless.py experiments/smoke_config_v1.json 20
python tools/check_reproducibility.py experiments/telemetry_smoke_v1.json
```

Le jeu refuse une variable inconnue, un type incompatible ou une valeur hors bornes.
La configuration normalisée est inscrite au début du log de session. Chaque session produit
aussi un fichier voisin au format JSON Lines (`.jsonl`) : une ligne JSON autonome par
événement, avec le schéma, l'identifiant de session, le temps écoulé, la catégorie, le
message lisible et les données structurées disponibles.

Lorsqu'une exécution headless s'arrête normalement (timeout, tous les agents morts ou
capture), un fichier `*.summary.json` voisin synthétise aussi le résultat final par agent.

`telemetry_smoke_v1.json` est un scénario très court (2 s) destiné à vérifier cette
chaîne de résultats de bout en bout.

## Métriques spatiales

Les positions sont échantillonnées toutes les secondes simulées. Une zone est une cellule
de 10 × 10 m, identifiée par ses coordonnées entières `x:z`. Une découverte est la première
entrée d'un agent dans une zone ; une revisite est une entrée ultérieure dans cette même
zone, après avoir rejoint une autre cellule. Les totaux sont disponibles dans le résumé
par agent (`visited_zones_total`, `zone_discoveries_total`, `zone_revisits_total`).

## Analyse de résultats

Valider tous les résumés d'un dossier :

```powershell
python tools/aggregate_results.py logs --validate-only
```

Les summaries antérieurs au contrat normalisé (sans `config_sha256`) sont signalés comme
archives et exclus de l'agrégation ; les erreurs d'un résultat au format actuel restent
bloquantes.

Créer un CSV par agent et un rapport agrégé par expérience :

```powershell
python tools/aggregate_results.py logs --output results/agents.csv --report results/report.json
```

## Campagnes

Une campagne crée un dossier par exécution, y archive la configuration exacte et les trois
résultats (`.summary.json`, `.jsonl`, `.log`). Elle s'exécute séquentiellement et peut être
reprise sans rejouer les runs terminés :

```powershell
python tools/run_campaign.py experiments/campaigns/exploration_smoke_campaign_v1.json
python tools/run_campaign.py experiments/campaigns/exploration_smoke_campaign_v1.json --resume
```

## Événements environnementaux

Les événements sont déclarés dans `events`, à un temps simulé donné. Deux types sont
actuellement disponibles : `remove_ronces_fraction` (`fraction` entre 0 et 1) et
`spawn_ronces` (`count` entre 1 et 500). Ils sont déterministes à seed fixe, journalisés
dans les événements `environment_event` et récapitulés dans `executed_events` du résumé.

`resource_disruption_v1.json` retire 50 % des ronciers après 10 s simulées.

## Perception sociale

`social_radius` active la perception des agents voisins. Une rencontre est une entrée
dans ce rayon ; une fin de rencontre intervient lors de la sortie du rayon. Le
regroupement est le temps cumulé où un agent possède au moins un voisin dans ce rayon.
`social_perception_smoke_v1.json` donne volontairement un rayon couvrant toute la carte
pour vérifier ces mesures.

`follow_probability` et `avoid_probability` s'appliquent lors d'une nouvelle rencontre,
uniquement si l'agent est autrement en errance. Elles ne dépassent jamais les priorités
ressource et contrôle manuel. `social_follow_smoke_v1.json` force le suivi pour vérifier
la règle de base ; `social_avoid_smoke_v1.json` fait de même pour l'évitement. Leur somme
doit être inférieure ou égale à 1. Les résumés distinguent désormais les décisions de suivi
et d'évitement ; l'agrégateur en calcule les moyennes par groupe.

# Profils d'exploration

`exploration_profiles_v1.json` compare deux extrêmes avec la même seed et sans ressources :
`Rouge` (0.0) conserve une direction plus longtemps que `Bleu` (1.0). Les événements
`decision` permettent de comparer le nombre de réorientations sans interpréter les logs
narratifs.

`goal_persistence_profiles_v1.json` compare l'effet inverse à exploration : `Rouge` (0.0)
réoriente plus vite son errance que `Bleu` (1.0). La métrique associée est
`wander_reorientations_total`, déjà journalisée dans les événements `decision`.

`known_zone_preference_profiles_v1.json` compare l'errance sans biais de `Rouge` (0.0)
à celle de `Bleu` (1.0), attirée vers sa zone visitée la plus proche. Les métriques sont
`zone_discoveries_total` et `zone_revisits_total`.

`curiosity_profiles_v1.json` compare `Rouge` (0.0) à `Bleu` (1.0), qui privilégie les
directions candidates projetées vers une zone inconnue. Les métriques sont
`zone_discoveries_total` et `zone_revisits_total`.

## Campagnes de référence (Phase 4)

Trois campagnes comparent des groupes sur plusieurs seeds (1, 2, 3), avec CSV agrégé et
graphiques SVG simples générés par `tools/plot_campaign.py` :

```powershell
python tools/run_campaign.py experiments/campaigns/<campagne>.json
python tools/aggregate_results.py results/<campagne> --output results/<campagne>/agents.csv --report results/<campagne>/report.json
python tools/plot_campaign.py results/<campagne>/agents.csv results/<campagne>/charts
```

**`memory_capacity_campaign_v1`** (`memory_capacity_profiles_v1.json`, 100 ronciers, 150 s
simulées, faim initiale 100) compare `memory_capacity` 1 vs 20. Résultat mesuré :
`memorized_ronces` moyen passe de 1.00 (capacité 1) à 1.42 (capacité 20) — la capacité
limite bien le nombre de ronciers retenus simultanément. En revanche distance parcourue et
cueillette sont identiques entre les deux groupes sur ce scénario : la faim ne descend
jamais sous le seuil de rappel actif (`pickup_hunger_threshold`), donc la mémoire n'influe
pas ici la trajectoire, seulement son propre remplissage. Une campagne future avec faim
initiale basse serait nécessaire pour mesurer un effet sur la survie.

**`resource_scarcity_campaign_v1`** (`resource_scarcity_v1.json`, faim initiale 60, 150 s
simulées, arrêt si tous morts) compare `ronce_count` 5 vs 40. Résultat mesuré : taux de
survie 8 % (rare, 1/12) contre 33 % (abondant, 4/12) — différence nette et attendue.

**`contrasted_profiles_campaign_v1`** (`contrasted_profiles_v1.json`, 24 ronciers, 150 s
simulées) compare deux profils comportementaux complets (pas une seule variable isolée) :
`Rouge` cumule exploration_tendency, curiosity à 1.0 et goal_persistence,
known_zone_preference à 0.0 ; `Bleu` a le profil inverse. `Vert`/`Jaune` restent neutres
(valeurs par défaut) comme repère. Résultat mesuré : distance parcourue moyenne 138.99
(Rouge) contre 89.77 (Bleu), `Vert`/`Jaune` à 123.47/132.39 — cohérent avec les traits
individuels déjà validés en Phase 2, cette fois combinés.
