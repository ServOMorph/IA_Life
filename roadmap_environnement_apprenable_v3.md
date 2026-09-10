# Roadmap — Environnement apprenable v3 : zones dangereuses

> **Proposition de réorientation — 2026-09-10, non adoptée.**
> La [roadmap d'apprentissage proposée](D:/ServOMorph/IA_Life/roadmap_apprentissage_fonctionnel_proposition.md)
> prévoit une première preuve alimentaire indépendante du danger, sur la base de cette
> [analyse sourcée](D:/ServOMorph/IA_Life/_docs/2026-09-10_recherche_apprentissage.md).
> Le danger deviendrait une extension. Cette proposition ne valide aucun candidat, ne modifie
> aucun statut ci-dessous et n'autorise pas l'ouverture des seeds réservés.

Créée le : 2026-09-01
Statut : **[EN COURS — Phases 0-2 FAIT, Phase 3 EN COURS, préalable à la reprise de `roadmap_apprentissage_v2.md`]**

## Objectif

Créer une tâche où le choix de direction produit un avantage causal, mesurable et
généralisable. Le mécanisme retenu est un ensemble de **zones dangereuses localisées** qui
augmentent la perte de faim tant qu'un agent les traverse. Une politique qui les évite doit
clairement battre une politique qui les ignore ou les vise, avant toute modification du learner.

Cette roadmap ne cherche pas à « faire apprendre coûte que coûte ». Elle établit d'abord que le
nouvel environnement porte un signal stratégique exploitable. Si l'oracle de politiques fixes
échoue, l'axe apprentissage reste suspendu.

## Diagnostic approfondi

### Pourquoi l'environnement v2 ne suffit pas

- Les ronciers sont homogènes et répartis aléatoirement dans les quatre quadrants
  (`main.gd::_spawn_ronces`). Il n'existe ni type de ressource, ni coût spatial, ni danger.
- Hors roncier visible ou mémorisé, les cinq actions S3 changent la trajectoire, mais aucune
  direction n'est structurellement bonne ou mauvaise. Leur valeur dépend surtout de la rencontre
  fortuite avec une ressource.
- Sur l'environnement v2, `aleatoire` atteint 0,58 de survie, comme la meilleure politique fixe,
  et `adaptatif_courant` atteint 0,67 sans séparation appariée (4-3/12 en survie, 4-6/12 en
  mûres). Le hasard est donc déjà proche du plafond utile de la tâche.
- La vie médiane sature dès que la survie dépasse 0,5. Les métriques discriminantes restent la
  survie et les mûres mangées ; une nouvelle mécanique doit ajouter une mesure causale propre.

### Ce que le code permet déjà de réutiliser

- `Character._perceive` fournit une perception générique par groupe, portée, angle et occlusion.
- Les zones visitées, directions candidates et politiques fixes donnent un socle pour ajouter une
  réponse d'évitement sans réécrire le déplacement.
- Les expériences JSON, les campagnes parallèles, les seeds appariés et les bras nommés sont déjà
  reproductibles.
- `oracle_report.py`, `benchmark_report.py` et `aggregate_results.py` fournissent la structure des
  comparaisons, mais devront intégrer les métriques de danger.

### Point critique pour l'apprentissage

Le reward actuel vaut principalement `+1` par cueillette, moins un coût par seconde, avec `-1`
terminal. Une perte de faim accélérée dans une zone dangereuse ne crée donc **aucun signal négatif
immédiat** dans la table adaptative. Le learner ne pourrait l'inférer qu'à travers une mort rare et
retardée. La reprise devra ajouter un événement de pénalité de danger au signal, avec un nouveau
tag de schéma de table. Ce raccord est volontairement interdit avant validation de l'oracle fixe.

## Mécanique minimale retenue

Une zone dangereuse est une aire circulaire immobile, générée de façon déterministe depuis le
seed de l'expérience.

- Effet : coût de faim additionnel par seconde d'exposition ; aucune nouvelle jauge de santé.
- Cumul : si deux zones se chevauchent, appliquer un seul coût maximal, pas une somme.
- Perception : la zone est perceptible dans la vision générique ; l'observation expose au minimum
  `in_danger`, `has_visible_danger`, `visible_danger_direction` et `visible_danger_distance`.
- Réponse oracle : `ignorer`, `eviter` (direction opposée au danger pertinent) ou `viser`.
- Placement : hors rayon de sécurité des spawns, des murs et des ronciers ; nombre de tentatives
  borné ; résultat journalisé. Aucun placement silencieusement différent entre deux runs du même
  seed.
- Télémétrie par agent : entrées, sorties, secondes d'exposition et coût de faim cumulé.

Choisir une pénalité de faim plutôt qu'une mort instantanée conserve une tâche graduelle, réutilise
la métrique de survie existante et permet de calibrer la difficulté sans ajouter un système de vie.

## Contrat expérimental verrouillé

- 12 seeds de calibration et 12 seeds réservés, distincts et écrits avant les mesures.
- `game_speed = 1.0`, même durée simulée et mêmes agents non étudiés pour tous les bras.
- Les environnements v1 et v2 restent gelés et ne sont jamais écrasés ; la référence retenue sera
  `experiments/apprentissage_env_ref_v3.json`.
- Bras minimaux : `danger_eviter`, `danger_ignorer`, `danger_viser`, `aleatoire`, plus la meilleure
  politique fixe alimentaire de v2 comme contrôle sans danger.
- Métrique primaire : survie. Secondaires : mûres mangées puis durée de vie si la survie est à
  égalité. Métriques causales : exposition et coût de faim dû au danger.
- Comparaisons appariées au seed. Aucun réglage n'est choisi sur les seeds réservés.
- Le reward interne est interdit comme gate de cette roadmap.

## Plan d'action

### Phase 0 — Spécification et tests de contrat [FAIT — 2026-09-01]

- Écrire les paramètres dans `VariableRegistry.GAME_CONFIG` : nombre, rayon, coût de faim,
  visibilité et rayon de sécurité du placement.
- Définir le schéma des événements `danger_enter`, `danger_exit` et `danger_exposure`.
- Ajouter aux checks manuels des scénarios sans danger, exposition simple, chevauchement et sortie.
- Verrouiller les 24 seeds et les bras dans une campagne versionnée avant tout résultat.

**Gate** : la configuration est validée, les anciens JSON sans paramètres de danger restent
acceptés avec un comportement strictement inchangé (`danger_zone_count = 0`).

**Livrables** : `DangerZoneContract` verrouille le calcul zéro zone / exposition / chevauchement /
sortie ; `experiments/danger_zone_contract_v1.md` fixe le schéma de télémétrie ;
`danger_zone_oracle_base_v1.json` et `campaigns/danger_zone_oracle_v3.json` fixent les cinq bras,
la grille initiale et les 24 seeds (12 calibration + 12 réservés).

### Phase 1 — Mécanique déterministe et télémétrie [FAIT — 2026-09-06]

- Ajouter un composant `danger_zone.gd` minimal (`Area3D`) et sa génération dans `main.gd`.
- Appliquer le coût dans `character.gd` en temps simulé, indépendamment du framerate.
- Journaliser placement, entrée, sortie, durée et coût ; exposer les totaux dans le résumé de run.
- Étendre `aggregate_results.py` et les validateurs de télémétrie.
- Vérifier visuellement une zone dans un run fenêtré, sans imposer cette vérification aux runs
  headless.

**Gate** : deux runs au même seed sont bit à bit identiques ; coût mesuré = taux × durée à la
tolérance numérique près ; configuration avec zéro zone reproduit une trace de référence v2.

**Livrables** : `danger_zone.gd` instancie les `Area3D` avec un RNG séparé, et `Character`
applique le taux maximal des zones actives au temps simulé. Les événements et totaux sont validés
par `danger_zone_smoke_v1.json` et `check_telemetry.py` ; deux runs headless au même seed sont
identiques. Vérification fenêtrée faite le 2026-09-06 (rendu des disques rouges, placement hors
décor, exposition/sortie, `danger_zone_count: 0` strict) via `run_danger_windowed.py` — gate
complet passé. Outillage : autoload `DevState` + panneau dev (relance avec seed / nombre de zones
choisis), `experiments/danger_zone_windowed_v1.json`.

### Phase 2 — Perception et oracle de politiques fixes [FAIT — 2026-09-07]

- Raccorder les zones au système `_perceive` et produire une direction d'éloignement stable.
- Étendre le décideur de politique fixe avec `fixed_policy_danger = ignorer|eviter|viser`.
- La politique de danger est une surcouche : hors danger visible, tous les bras exécutent la même
  politique alimentaire. Cette isolation est nécessaire pour attribuer l'écart au danger.
- Tester les cas danger devant, derrière, hors portée, occlus et zone déjà occupée.
- Livrer une config smoke avec `events` scriptés amenant un agent dans une zone puis l'en sortant,
  pour que `check_telemetry.py` couvre la séquence `danger_enter` / `danger_exposure` / `danger_exit`
  en headless (la smoke Phase 1 a des agents immobiles ; point 15 de `tests_manuels.md` non
  couvert sans manip fenêtrée).

**Gate** : sur un scénario scripté, `eviter` réduit l'exposition, `viser` l'augmente et `ignorer`
laisse la trajectoire inchangée ; aucun bras ne consomme un aléa supplémentaire au moment de la
décision.

**Livrables** : `danger_zone.gd` expose `get_perception_type()/get_perception_state()` (perceptible
si `danger_zone_visible`) ; `character.gd` calcule `danger_response_direction` (priorité à la zone
physiquement active sur la zone seulement visible, couvre le cas « zone déjà occupée ») et l'expose
à l'observation ; `fixed_policy_decider.gd::decide()` applique la surcouche (`ignorer` = no-op,
`eviter`/`viser` = direction opposée/alignée). Événement scripté `teleport_agent` ajouté à
`experiment_config.gd`/`main.gd`. Séquence `danger_enter`/`danger_exposure`/`danger_exit` couverte
en headless par `experiments/danger_zone_scripted_events_v1.json`
(`check_telemetry.py`/`check_reproducibility.py` verts). Gate causal vérifié sur
`experiments/danger_zone_fixed_policy_scenario_v1.json` (seed 2, 4 agents co-localisés dans la même
zone) : exposition `eviter` 0,75 s < `ignorer` 1,73/1,47 s < `viser` 11,98 s, reproductible ; aucune
régression sur `p1_fixed_policy_selftest.json` (`check_fixed_policy.py`). 12 tests ajoutés à
`run_manual_checks.gd`.

### Phase 3 — Calibration sur seeds d'entraînement [EN COURS — engagée 2026-09-08]

- Balayer une petite grille : nombre de zones × rayon × coût de faim. Commencer grossier, puis
  raffiner une seule fois autour du meilleur candidat.
- Exécuter les cinq bras sur les 12 seeds de calibration avec `--jobs` et `--retries`.
- Classer les candidats par séparation des politiques, pas par difficulté maximale.

**Avancement (2026-09-08)** : gate causal jamais franchi, mais 3 causes d'échec en cascade
identifiées et corrigées/amendées, chacune vérifiée par un diagnostic resserré (12 seeds de
calibration, jamais les seeds réservés) :

1. Grille initiale (4 zones/rayon/coût × 4 bras × 12 seeds, 384 runs) : 0/8 points passent.
   Bug trouvé : `FixedPolicyDecider.decide()` est rappelé à chaque frame physique — le bras
   `aleatoire` retirait eviter/viser à chaque frame, la direction s'annulait en moyenne et
   reproduisait exactement les stats du bras `eviter`. Corrigé : le tirage est tenu pendant
   `decision_interval_seconds` (`fixed_policy_decider.gd`). Bras `pf_rm_er` (contrôle sans
   danger) sorti de cette campagne — un override de bras sur `danger_zone_count` est toujours
   écrasé par la grille (`run_campaign.py` applique bras puis grille).
2. Bug rejoué (384 runs) : gate toujours 0/8, et de façon inattendue `eviter` (0,19 survie,
   coût de danger nul confirmé) restait pire que `ignorer` (0,32) — la surcouche remplaçait la
   politique alimentaire dès qu'une zone est visible n'importe où dans le champ de vision
   (15 m), pas seulement sur le chemin. Corrigé : nouveau paramètre `danger_reaction_range`
   (CHARACTER), sous lequel seul un danger *visible* (pas subi) déclenche la surcouche.
3. Diagnostic `danger_reaction_range` (3/5/8 m, 144 runs) : `eviter` remonte à 0,33 au meilleur
   point mais gate toujours en échec — et le contrôle sans danger (`pf_rm_er`) ne survit lui-même
   qu'à 0,25 sur ces 12 seeds, sous le seuil de 0,50 du critère 4, indépendamment du danger.
   Diagnostic `hunger_depletion_rate` (0,70 à 0,90, 60 runs) : 0,70 remonte la survie de
   `pf_rm_er` à 0,75. Base amendée : `experiments/danger_zone_oracle_base_v2.json`
   (`hunger_depletion_rate` 0,70), `danger_zone_oracle_base_v1.json` conservé intact.
4. Diagnostic `reaction_range` rejoué sur la base v2 (144 runs) : critère 4 satisfait (best 0,67,
   worst 0,33) mais `eviter`/`ignorer`/`aleatoire` produisent des résultats strictement
   identiques sur la majorité des seeds — avec 6 zones et `danger_zone_safety_radius` 12 m
   autour de 30 ronciers (carte 160×160), le danger est trop rare sur la trajectoire naturelle
   pour que la réponse ait l'occasion de s'exercer. Diagnostic densité (10/15/20 zones, 144
   runs, aucun échec de placement même à 20) : tendance **monotone claire** — à 20 zones,
   `eviter` devient la meilleure politique (0,58, devant `ignorer` 0,50) ; les 3 critères
   d'accord progressent 6→7/12, 3→6/12, 2→5/12, mais restent sous les seuils requis (9-10/12).

Depuis, les probes de densité 25/30/40, de coût 0,8/1,0/1,2 et de placement sur approche des
ronciers ont tous échoué le gate. Le placement approche est complet depuis sa correction
(1 728/1 728 zones), mais un probe de portée 10/12/15 m démontre que la fuite rectiligne ne bat
pas `aleatoire`. Prochaine étape : décision utilisateur entre un mécanisme de contournement
stateful et l'abandon de l'axe ; ne pas ouvrir les seeds réservés. Détail complet :
`_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.

**Gate causal obligatoire** :

1. `danger_eviter` subit moins de coût de danger que `danger_viser` sur au moins 10/12 seeds ;
2. `danger_eviter` bat `danger_viser` sur le résultat dans le même sens sur au moins 9/12 seeds ;
3. `danger_eviter` bat `aleatoire` sur le résultat dans le même sens sur au moins 9/12 seeds ;
4. la survie n'est ni triviale ni effondrée : meilleure politique entre 0,50 et 0,90, pire
   politique au plus à 0,40.

Le résultat est comparé lexicographiquement : survie, puis mûres mangées, puis durée de vie. Les
seuils ci-dessus sont écrits avant la campagne et ne sont pas reformulés après coup.

**Branche Échec** : si aucun candidat ne passe, ne pas ajouter le danger au learner. Documenter si
l'échec vient du placement, d'un effet trop faible ou d'une tâche encore dominée par le hasard,
puis demander une décision : seconde itération de mécanique ou abandon.

**Itération de contournement (2026-09-10)** : cible et côté mémorisés. Le candidat v2 échoue :
critères 1/2/3 à 10/12, 10/12, 5/12 et survie maximale 0,42. Les logs montrent 7 timeouts sur
20 détours, compatibles avec des collisions bloquantes. V3 introduit un unique changement de côté
après immobilisation, mais reste non mesuré à la pause. Décision et campagnes :
`_docs/decisions/2026-09-10_contournement-stateful.md`. L'évaluateur compare désormais correctement
`danger_eviter` à `danger_viser`; aucun seed réservé n'a été ouvert.

### Phase 4 — Confirmation réservée et gel v3 [À FAIRE]

- Prendre le meilleur environnement sans consulter les seeds réservés.
- Écrire `apprentissage_env_ref_v3.json` avec commentaire de gel et empreinte de configuration.
- Rejouer exactement les mêmes bras sur les 12 seeds réservés.
- Produire un rapport apparié et une décision détaillée.

**Gate** : les quatre conditions de la Phase 3 passent également sur les seeds réservés. Un échec
réservé invalide le candidat ; il est interdit de retourner régler l'environnement sur ces seeds.

### Phase 5 — Préparer le raccord d'apprentissage [À FAIRE]

Après le gate réservé seulement :

- Ajouter au plan de reprise un état prioritaire de danger visible et une action
  `eloignement_danger` ; ne pas multiplier les états par un produit cartésien inutile.
- Ajouter une pénalité événementielle proportionnelle au coût de faim réellement subi pendant la
  fenêtre d'engagement ; incrémenter `TABLE_SCHEMA_VERSION`.
- Écrire les tests d'attribution du crédit : l'évitement devient positif relativement à
  `viser/ignorer`, sans modifier le reward de cueillette hors danger.
- Définir une nouvelle baseline M0 v3 avec `adaptatif_v1`, `aleatoire`, politiques fixes et
  `adaptatif_courant`, avant tout entraînement.
- Consigner la décision de reprise et amender le bandeau de `roadmap_apprentissage_v2.md`.

**Gate** : le contrat de reprise contient les tests, bras, seeds, métriques et critère de succès ;
aucune campagne adaptative n'a encore utilisé les seeds réservés.

## Hors périmètre

- Dangers mobiles, combat, dégâts instantanés ou nouvelle jauge de santé.
- Plusieurs types de danger dans la même itération.
- Ressources hétérogènes, régénération ou épuisement spatial des ronciers.
- Refonte de l'algorithme d'apprentissage avant validation de l'environnement.
- Apprentissage multi-agent simultané.

## Risques et parades

- **Le danger devient seulement une taxe aléatoire.** Parade : politique `viser` comme contrôle
  négatif et gate apparié sur l'exposition.
- **L'évitement empêche aussi d'atteindre les mûres.** Parade : placement avec marge autour des
  ronciers et mesure conjointe exposition/mûres.
- **Le placement varie avec l'ordre des appels RNG.** Parade : RNG dédié au danger, dérivé du seed,
  sans consommer la séquence du terrain, des ronciers ou des agents.
- **Le learner ne voit pas le coût.** Parade : pénalité événementielle explicite seulement après
  l'oracle, avec test d'attribution et schéma de table incrémenté.
- **Sur-ajustement de la carte.** Parade : seeds réservés et interdiction de recalibrer après leur
  ouverture.
- **Explosion de l'espace d'état.** Parade : état prioritaire de danger, pas de combinaison de
  toutes les situations alimentaires avec tous les niveaux de danger.

## Condition de déblocage de `roadmap_apprentissage_v2.md`

Cette roadmap débloque l'autre roadmap **uniquement quand les Phases 0 à 5 sont [FAIT] et que le
gate de la Phase 4 passe sur les 12 seeds réservés**. À ce moment-là, modifier
`roadmap_apprentissage_v2.md` pour :

1. remplacer le bandeau « AXE SUSPENDU » par « REPRISE AUTORISÉE SUR ENVIRONNEMENT v3 » ;
2. insérer une Phase 3b de raccord danger (observation, action, reward, schéma et tests) ;
3. rebaseliner M0/M1 sur `apprentissage_env_ref_v3.json` ;
4. reprendre ensuite à la Phase 4 (persistance entre vies), puis appliquer le protocole de la
   Phase 5. La Phase 6 reste conditionnelle aux résultats obtenus sur la tâche v3.

Tant que cette condition n'est pas satisfaite, les interdictions actuelles restent vraies : ne pas
relancer M2 v2, M3, les Phases 4-5 ou la Phase 6 de la roadmap apprentissage v2.
