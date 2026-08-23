# Configurations d'expérience

`smoke_config_v1.json` est un exemple minimal du format `ExperimentConfig` v1.
Il est compatible avec l'ancien format d'overrides : les clés historiques
`game_config`, `game_speed`, `character_defaults`, `quit_on_all_dead` et
`max_wall_seconds` restent acceptées.

Le nouveau format sépare explicitement :

- `experiment_id`, `seed`, `metadata` et `events` ;
- `environment.game_config` pour les règles globales ;
- `agents.defaults` et `agents.individual.<Nom>` pour les paramètres des agents ;
- `simulation` pour vitesse et limites d'exécution.

Lancer l'exemple sous Windows :

```powershell
python run_headless.py experiments/smoke_config_v1.json 20
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
