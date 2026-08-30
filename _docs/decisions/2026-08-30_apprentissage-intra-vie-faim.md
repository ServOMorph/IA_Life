# Apprentissage intra-vie sur la faim — campagnes de validation (Phases 3 et 4)

Date : 2026-08-30
Statut : proposé — effet démontré sur un seed (Phase 3), **ne généralise pas proprement
sur deux seeds** (Phase 4). Le mécanisme est correct et reproductible ; son bénéfice
intra-vie est marginal et dépendant du seed.

> Phase 3 : le protocole final (bras de contrôle aléatoire, même seed) franchit le gate sur
> le seed testé. Phase 4 : le balayage `learning_rate` × `exploration_epsilon` sur deux
> seeds montre que l'avantage sur le contrôle est faible (~0,05 de `reward`) et s'inverse
> sur le second seed. Les trois sections sont conservées : diagnostic initial, résultat
> Phase 3, résultat Phase 4.

## Ce qui a été construit

- `experiments/apprentissage_faim_v1.json` : Rouge en `adaptatif` (vision 40,
  `hunger_depletion_rate` 0,8), Bleu/Vert/Jaune en `automate`, seed fixe 20260830, carte
  30 ronciers × 4 mûres, 420 s simulées, arrêt à durée atteinte.
- `experiments/campaigns/apprentissage_faim_v1.json` : 2 répétitions au même seed pour le
  contrôle de reproductibilité.
- `tools/aggregate_results.py --learning-curve` : à partir des `.jsonl`, extrait par agent
  la suite des `apprentissage_maj` non terminaux et calcule, en fenêtre glissante
  (défaut 20 décisions, pas 5) : le taux de décisions « réussies » (`reward > 0`), le
  `reward` moyen, leurs pentes par régression linéaire, et un test d'égalité stricte des
  suites de récompense entre runs.
- `tools/plot_learning_curve.py` : courbe SVG sans dépendance, une ligne par (run, agent),
  taux de réussite vs temps simulé.

## Méthode

Rouge produit 90 décisions de faim sur ses 420 s de vie (il survit). Fenêtre 20, pas 5 →
15 fenêtres. Campagne rejouée 2 fois au même seed.

## Résultats

| Mesure | run 1 | run 2 |
|---|---|---|
| décisions de faim | 90 | 90 |
| suite des récompenses | identique bit à bit entre les 2 runs | — |
| taux de réussite (`reward > 0`) début → fin | 0,25 → 0,15 | idem |
| pente du taux de réussite | −0,0068 / fenêtre | idem |
| pente du `reward` moyen | −0,0037 / fenêtre | idem |
| table finale S1 | `ronce_visible` −0,168 ; `errance` −0,291 ; `ronce_memorisee` −0,296 | idem |
| répartition des actions choisies en S1 | `ronce_visible` 47 / `ronce_memorisee` 37 / `errance` 7 | idem |

## Verdict du gate

Le gate de la Phase 3 (« la courbe monte de façon reproductible **et** l'apprenant finit
au-dessus de son taux de réussite initial ») **n'est pas franchi** : la courbe descend
légèrement, sur les deux proxys (taux de réussite et `reward` moyen).

Ce qui est acquis :

- **Reproductibilité** : les deux exécutions au même seed produisent des suites de
  récompense strictement identiques.
- **Le mécanisme apprend une préférence cohérente** : dans S1, la table converge vers un
  ordre correct (`ronce_visible` nettement moins mauvais que viser un souvenir ou errer),
  et la sélection gloutonne déplace la répartition des actions vers cette cellule
  (47 / 37 / 7). La MAJ en ligne et la sélection ε-greedy font ce qu'on attend d'elles.

## Deux causes diagnostiquées

1. **La discrétisation en 3 situations n'est pas exercée.** Avec `vision_range` 40 sur
   cette carte, un roncier est toujours visible : 91 décisions sur 91 sont en S1. S2
   (souvenir sans visible) et S3 (rien) ne surviennent jamais. Sur une carte de cette
   taille, réduire la vision assez pour faire apparaître S2/S3 prive l'agent de nourriture
   au point de le faire mourir vite — compromis structurel entre « voir les 3 situations »
   et « vivre assez longtemps pour apprendre ».
2. **Le proxy `reward > 0` sur une fenêtre de 2 s mesure surtout le calage d'un repas dans
   la tranche**, pas la qualité de la décision. La faim initiale de 100 fait manger plus
   souvent en début de vie (régime transitoire) qu'ensuite : la « baisse » du taux de
   réussite est un artefact de ce transitoire, pas une désapprentissage. Le signal
   d'apprentissage réel est dans la table de scores, que ce proxy ne reflète pas.

## Protocole recalibré (2026-08-30) — retenu

Décision (option C) : le gate absolu (« la courbe monte ») était mal posé — la faim
initiale de 100 crée un transitoire descendant que les deux comportements subissent. Il est
remplacé par une **comparaison à un bras de contrôle au même seed** :

- **Bras learner** : Rouge `adaptatif`, `exploration_epsilon` 0,2 (exploite la table).
- **Bras contrôle** : Rouge `adaptatif`, `exploration_epsilon` 1,0 — sélection toujours
  aléatoire parmi les actions valides, table mise à jour mais jamais lue. Même engagement,
  même calcul de récompense, même journalisation : la seule différence est
  glouton vs aléatoire.
- `vision_range` de Rouge ramenée de 40 à **15** : les trois situations surviennent enfin
  (S1 / S2 / S3).
- Grille de campagne `agents.individual.Rouge.exploration_epsilon: [0.2, 1.0]`,
  2 répétitions, seed fixe → 4 runs.
- **Gate** : le `reward` moyen du learner (sur la vie, et sur la dernière fenêtre) est
  au-dessus de celui du contrôle, de façon reproductible entre les 2 répétitions de chaque
  bras.

### Résultats (4 runs, seed 20260830, fenêtre 20 / pas 5)

| Mesure | learner ε 0,2 | contrôle ε 1,0 |
|---|---|---|
| décisions de faim | 117 | 149 |
| répétition → répétition | identique bit à bit | identique bit à bit |
| `reward` moyen sur la vie | **−0,203** | −0,250 |
| `reward` moyen dernière fenêtre | **−0,295** | −0,323 |
| taux de réussite (`reward > 0`) sur la vie | **0,094** | 0,047 |
| mix de situations | S1 31 / S2 13 / S3 74 | S1 84 / S2 49 / S3 17 |
| table finale S1 `ronce_visible` | **+0,106** | −0,316 |
| actions choisies en S1 (`ronce_visible`/`memo`/`errance`) | 22 / 5 / 4 | 24 / 26 / 34 |
| issue de Rouge | vivant à 420 s (15 mûres) | mort à 375 s (12 mûres) |

### Verdict : gate franchi

- Le learner accumule un `reward` moyen supérieur au contrôle, sur la vie entière comme en
  fin de vie, et **strictement reproductible** (les deux répétitions de chaque bras donnent
  des suites de récompense identiques au bit près).
- Dans S1, la table du learner rend l'action `ronce_visible` **positive** (+0,106) et la
  sélection s'y concentre (22 sur 31) ; côté contrôle, sélection aléatoire, la même cellule
  reste négative. L'apprentissage se traduit donc en meilleures décisions, pas seulement en
  scores internes.
- Effet aval : le learner survit là où le bras sans apprentissage meurt. Le learner fait
  aussi *moins* de décisions de faim (117 vs 149) : il rejoint la nourriture plus vite,
  donc repasse moins de temps sous le seuil.

La courbe brute (`reward` moyen ou taux de réussite en fonction du temps) reste légèrement
descendante *dans chaque vie* — c'est le transitoire de faim initiale, présent dans les
deux bras. Le signal d'apprentissage est l'écart constant entre les deux courbes, pas leur
pente individuelle.

### Limites

- Un seul seed. La reproductibilité est démontrée (déterminisme), pas la robustesse
  statistique sur plusieurs environnements — c'est l'objet de la Phase 4.
- Sur cette carte, S3 domine encore le mix côté learner (74/118) : il erre souvent sans
  rien voir ni se rappeler. La discrétisation S1/S2/S3 est exercée mais déséquilibrée.
- `REWARD_HUNGER_SCALE` reste une constante (5,0) — à régler en Phase 4.

## Protocole Phase 4 — robustesse et réglages

`experiments/apprentissage_faim_v2.json` (identique à v1, `max_simulation_seconds` 300) et
`experiments/campaigns/apprentissage_faim_v2_sweep.json` : balayage
`learning_rate` ∈ {0,1 ; 0,2 ; 0,4} × `exploration_epsilon` ∈ {0,1 ; 0,2 ; 0,4 ; 1,0}
sur 2 seeds (20260830, 20260831), 1 répétition → 24 runs. `exploration_epsilon` 1,0 sert
de contrôle « pas d'apprentissage » par seed.

`tools/aggregate_results.py --learning-curve` a été complété : volatilité fenêtre-à-fenêtre
(`*_step_volatility`) et `reward` moyen 1re vs 2e moitié de vie, pour objectiver « apprend
sans osciller ».

### Résultats — `reward` moyen sur la vie, écart au contrôle du même seed

| | seed 20260830 (contrôle −0,228) | seed 20260831 (contrôle −0,183) |
|---|---|---|
| ε 0,1 (toute valeur de `lr`) | −0,157 (**+0,071**) | −0,17 à −0,26 (−0,08 à **+0,01**) |
| ε 0,2 (toute valeur de `lr`) | −0,157 (**+0,071**) | −0,22 à −0,25 (−0,04 à −0,07) |
| ε 0,4 (toute valeur de `lr`) | −0,264 (−0,036) | −0,16 à −0,20 (−0,02 à **+0,02**) |

### Ce que le balayage montre

- **`learning_rate` n'est pas un levier ici.** Sur le seed 20260830, les suites de
  récompense sont **identiques au bit près** pour `lr` 0,1 / 0,2 / 0,4 à ε ≤ 0,2 : le
  classement des actions dans chaque situation est figé tôt et ne dépend pas de la vitesse
  de mise à jour. Sur le seed 20260831, `lr` fait varier fortement l'issue (75 vs 115
  décisions à ε 0,1) mais de façon non monotone — du bruit, pas un réglage.
- **`exploration_epsilon` doit être bas.** ε 0,4 ramène le décideur adaptatif au niveau du
  contrôle aléatoire, voire en dessous, sur les deux seeds. ε 0,1–0,2 est la seule plage
  où un avantage apparaît.
- **L'avantage sur le contrôle ne généralise pas.** Nettement positif (+0,07) sur le seed
  20260830, il est nul ou négatif sur le seed 20260831, où le contrôle aléatoire fait
  mieux que la plupart des configurations apprenantes. L'amplitude de l'effet (~0,05 de
  `reward`) est du même ordre que l'écart transitoire intra-vie et que la variance
  inter-seed (une vie sur deux, un seed « malchanceux » tue l'apprenant vers 210 s).
- **Volatilité** comparable partout (~0,05–0,07), le contrôle inclus : aucune configuration
  n'« oscille » pathologiquement. Le critère « apprend sans osciller » n'est pas
  discriminant à ces réglages.

### Verdict Phase 4

L'apprentissage intra-vie tel qu'implémenté produit un **effet réel mais faible et
dépendant du seed**. Le gate Phase 3 restait honnête pour son protocole (un seed, learner
vs contrôle), mais l'ajout d'un second seed suffit à faire disparaître l'avantage. Deux
seeds ne tranchent pas ; il faudrait ≥ 8–10 seeds pour dire si l'effet moyen est positif.

L'absence de couplage entre `learning_rate` et comportement est le signal le plus net : il
suggère que la discrétisation (3 situations × ≤ 3 actions) est trop grossière pour que la
récompense déplace des choix en une seule vie — le risque « plateau bas » listé dans la
roadmap.

### Recommandation pour la suite de l'axe

Ne pas enchaîner sur la persistance entre vies, les apprenants multiples ou la bascule 1C
(RL) : le signal intra-vie est trop ténu pour servir de base. Deux pistes, par ordre de
préférence :

1. **Affiner le modèle avant d'élargir** : sous-situations plus fines (porter des mûres,
   distance au roncier visible, mémoire fraîche vs estompée), et vérifier que `reward`
   déplace alors réellement les choix (couplage `learning_rate` → comportement non nul).
2. Si (1) ne débloque rien : **conclure que 1B « heuristiques apprises » ne rend pas en
   une vie** sur cet environnement, et arbitrer explicitement entre 1A (sélection entre
   vies, où la table devient un génotype) et 1C.

Décision de bifurcation à consigner dans `signals.md` par `/close`.

### Limites Phase 4

- 2 seeds seulement (budget : ~2 h de simulation à `game_speed` 1).
- `game_speed` > 1 écarté : un test x1 vs x4 a montré des simulations divergentes
  (séries de récompense différentes, spans différents). Contredit la note mémoire
  `2026-08-17 — Vitesse de jeu = accélérateur de temps pur` sur le chemin du décideur
  adaptatif ; à investiguer hors de cet axe.
- `REWARD_HUNGER_SCALE` non balayée (reste 5,0) : vu l'absence d'effet de `learning_rate`,
  la régler seule a peu de chances de changer le tableau.

## Fichiers de résultats

- Phase 3 : `results/apprentissage_faim_v1/` (gitignoré) — `run_000{1,2}` (learner),
  `run_000{3,4}` (contrôle), `curve/`, `charts/`.
- Phase 4 : `results/apprentissage_faim_v2_sweep/` (gitignoré) — 24 runs, `curve/`,
  `agents.csv`, `report.json`.
