# Roadmap — Environnement apprenable v3 : zones dangereuses

Créée le : 2026-09-01
Statut : **[PLANIFIÉE — préalable à la reprise de `roadmap_apprentissage_v2.md`]**

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

### Phase 0 — Spécification et tests de contrat [À FAIRE]

- Écrire les paramètres dans `VariableRegistry.GAME_CONFIG` : nombre, rayon, coût de faim,
  visibilité et rayon de sécurité du placement.
- Définir le schéma des événements `danger_enter`, `danger_exit` et `danger_exposure`.
- Ajouter aux checks manuels des scénarios sans danger, exposition simple, chevauchement et sortie.
- Verrouiller les 24 seeds et les bras dans une campagne versionnée avant tout résultat.

**Gate** : la configuration est validée, les anciens JSON sans paramètres de danger restent
acceptés avec un comportement strictement inchangé (`danger_zone_count = 0`).

### Phase 1 — Mécanique déterministe et télémétrie [À FAIRE]

- Ajouter un composant `danger_zone.gd` minimal (`Area3D`) et sa génération dans `main.gd`.
- Appliquer le coût dans `character.gd` en temps simulé, indépendamment du framerate.
- Journaliser placement, entrée, sortie, durée et coût ; exposer les totaux dans le résumé de run.
- Étendre `aggregate_results.py` et les validateurs de télémétrie.
- Vérifier visuellement une zone dans un run fenêtré, sans imposer cette vérification aux runs
  headless.

**Gate** : deux runs au même seed sont bit à bit identiques ; coût mesuré = taux × durée à la
tolérance numérique près ; configuration avec zéro zone reproduit une trace de référence v2.

### Phase 2 — Perception et oracle de politiques fixes [À FAIRE]

- Raccorder les zones au système `_perceive` et produire une direction d'éloignement stable.
- Étendre le décideur de politique fixe avec `fixed_policy_danger = ignorer|eviter|viser`.
- La politique de danger est une surcouche : hors danger visible, tous les bras exécutent la même
  politique alimentaire. Cette isolation est nécessaire pour attribuer l'écart au danger.
- Tester les cas danger devant, derrière, hors portée, occlus et zone déjà occupée.

**Gate** : sur un scénario scripté, `eviter` réduit l'exposition, `viser` l'augmente et `ignorer`
laisse la trajectoire inchangée ; aucun bras ne consomme un aléa supplémentaire au moment de la
décision.

### Phase 3 — Calibration sur seeds d'entraînement [À FAIRE]

- Balayer une petite grille : nombre de zones × rayon × coût de faim. Commencer grossier, puis
  raffiner une seule fois autour du meilleur candidat.
- Exécuter les cinq bras sur les 12 seeds de calibration avec `--jobs` et `--retries`.
- Classer les candidats par séparation des politiques, pas par difficulté maximale.

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
