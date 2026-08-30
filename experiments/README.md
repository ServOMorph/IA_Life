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

## Courbe d'apprentissage du décideur adaptatif (roadmap_apprentissage, Phase 3)

`apprentissage_faim_v1.json` fait vivre `Rouge` en `adaptatif` (vision 15,
`hunger_depletion_rate` 0,8) au milieu de trois `automate`, seed fixe, 420 s simulées. Le
décideur adaptatif journalise `apprentissage_decision`, `apprentissage_maj` (récompense +
score avant/après) et `apprentissage_table` (dump de fin de vie).

La campagne compare deux bras au même seed via une grille sur
`agents.individual.Rouge.exploration_epsilon` : `0.2` (learner, exploite la table apprise)
et `1.0` (contrôle, sélection toujours aléatoire parmi les actions valides, table jamais
lue). 2 répétitions par bras → 4 runs.

```powershell
python tools/run_campaign.py experiments/campaigns/apprentissage_faim_v1.json
python tools/aggregate_results.py results/apprentissage_faim_v1 --learning-curve results/apprentissage_faim_v1/curve
python tools/plot_learning_curve.py results/apprentissage_faim_v1/curve/learning_curve.csv results/apprentissage_faim_v1/charts
```

`--learning-curve` produit `learning_curve.csv` (taux de décisions de faim réussies
`reward > 0` et `reward` moyen, en fenêtre glissante, avec la colonne `params` du bras) et
`learning_curve_summary.json` (pentes, débuts/fins, `reward` moyen sur la vie, test
d'égalité stricte des suites de récompense entre répétitions d'un même bras).

Résultat Phase 3 (2026-08-30, seed 20260830) : chaque bras est **reproductible au bit près**
entre ses 2 répétitions. Le learner accumule un `reward` moyen supérieur au contrôle sur la
vie (−0,203 vs −0,250), taux de réussite double (0,094 vs 0,047) ; dans S1 la table rend
`ronce_visible` positive (+0,106) et la sélection s'y concentre ; le learner survit (420 s),
le contrôle meurt (375 s). **Gate franchi sur ce seed.**

Phase 4 — robustesse (`apprentissage_faim_v2.json` + `campaigns/apprentissage_faim_v2_sweep.json`,
balayage `learning_rate` × `exploration_epsilon`, 2 seeds, 24 runs) : l'avantage **ne
généralise pas**. Sur le second seed (20260831) le contrôle aléatoire fait mieux que la
plupart des configurations apprenantes ; l'effet moyen (~0,05 de `reward`) est de l'ordre
de la variance inter-seed. `learning_rate` n'a aucun effet mesurable (suites de récompense
identiques au bit près pour `lr` 0,1/0,2/0,4 sur le seed « propre »). Seul signal robuste :
`exploration_epsilon` doit être ≤ 0,2 (à 0,4 le décideur retombe au niveau du hasard).
Détail et recommandation : `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`.
