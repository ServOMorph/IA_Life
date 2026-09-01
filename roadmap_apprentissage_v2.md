# Roadmap — Apprentissage durable et mesurable

Créée le : 2026-08-30
Succède à `roadmap_apprentissage.md` (4 phases closes, effet 1B non généralisé).
Tranche l'action P1 de `signals.md` : **ni « affiner la discrétisation » seul, ni bascule 1C
immédiate** — les deux étaient prématurés faute d'avoir établi que la tâche est apprenable et
que le signal d'apprentissage est exploitable.

> **AXE SUSPENDU (2026-09-01).** Branche « Échec » du critère de succès. Phases 0-3 closes.
> Après Phase 2 (signal événementiel + amorçage TD) et Phase 3 (espace d'action S3 ×5), et
> après enrichissement + re-gel de l'environnement (`apprentissage_env_ref_v2.json`),
> `adaptatif_courant` reste **à égalité statistique avec la sélection aléatoire** au seed
> apparié (M1 v2 : survie 4-3/12, mûres 4-6/12 vs `aleatoire`). Le code Phases 2-3 est
> conservé (gates (a) et (b) passés, tests verts). Phases 4-5 et Phase 6 non engagées.
> Détail : `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`.
> Rouvrir la Phase 6 (approximation de fonction) ou une v3 seulement sur décision explicite.

## Diagnostic — pourquoi l'apprentissage actuel ne peut pas tenir

Constats établis en lisant `scripts/adaptive_decider.gd`, `scripts/character.gd`,
`experiments/apprentissage_faim_v2.json` et les résultats consignés dans
`_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`.

### 1. 63 % des décisions ne sont pas des décisions

`ACTIONS_BY_SITUATION[S3_inconnu] = [errance]` : une seule action. `_select_action` court-circuite
sur `actions.size() <= 1`. Or le mix mesuré en Phase 3 était S1 31 / S2 13 / S3 74 sur ~118
décisions de faim : **74 décisions sur 118 n'offrent aucun choix**. Au mieux ~44 décisions
réellement apprenantes par vie, réparties sur 5 cellules.

Conséquence : affiner les *situations* (recommandation de la roadmap précédente) fractionne une
table déjà sous-échantillonnée sans créer une seule décision de plus. Le levier est du côté des
*actions*, en S3, là où l'agent passe la majorité de son temps.

### 2. La récompense est une constante plus un pic rare

`reward = clamp((hunger_now - hunger_precedent) / REWARD_HUNGER_SCALE, -1, 1)` avec
`REWARD_HUNGER_SCALE` 5,0, `hunger_depletion_rate` 0,8 et une fenêtre d'engagement de 2,0 s :
toute fenêtre sans repas vaut **exactement −0,32, quelle que soit l'action**. Seule une fenêtre
avec repas sort du lot. Le signal utile est donc un indicateur binaire « ai-je mangé dans ces
2 secondes », noyé dans un décalage constant.

Contrôle du modèle : à un taux de réussite mesuré de 0,094, ce modèle prédit un `reward` moyen de
≈ −0,19 ; les campagnes mesurent −0,157 à −0,203. Le mécanisme mesure la fréquence des repas,
pas la qualité des décisions.

### 3. Aucune propagation du crédit

`_commit_reward` est une moyenne mobile de la récompense immédiate : pas d'amorçage, pas de
facteur d'actualisation, pas de trace d'éligibilité. Rejoindre un roncier visible prend plus
qu'une fenêtre d'engagement : les fenêtres intermédiaires du *bon* comportement reçoivent −0,32,
seule la dernière encaisse le repas. **La meilleure action est systématiquement pénalisée pendant
son exécution.** À trois fenêtres d'approche, le signal est dilué 3 contre 1.

### 4. Une vie ne fournit pas assez d'échantillons

`reset_table()` est appelée dans `_init` et `_die()` est terminal — pas de renaissance dans
`character.gd`. Chaque vie repart de zéro avec ~44 décisions utiles. Avec `learning_rate` 0,2, la
moyenne mobile n'a une mémoire effective que de ~5 échantillons : chaque score est la moyenne des
5 dernières visites de sa cellule. À ~10 visites par cellule en S1, l'erreur type sur un score est
de l'ordre de 0,15, pour des écarts à résoudre de 0,05 à 0,4.

Le mécanisme peut donc résoudre **un seul contraste par vie** : le plus gros, en S1 (« viser le
roncier visible »), et c'est exactement ce que la Phase 3 a observé. Tout le reste est sous le
plancher de bruit. Or ce contraste unique est aussi celui que `BaselineDecider` code en dur : il
n'apporte rien au niveau des résultats, ce qui explique que `learning_rate` n'ait aucun effet
mesurable et que l'avantage s'inverse au second seed.

### 5. Le critère d'acceptation mesurait la mauvaise chose

Le `reward` moyen interne a servi de métrique de gate en Phases 3 et 4. C'est la quantité même que
l'agent optimise, dominée par le transitoire de faim initiale, et sans lien démontré avec la
survie. Un gate ne peut porter que sur une métrique de résultat (survie, mûres mangées).

### Synthèse

Le problème n'est pas le réglage du learner. Il y a **environ un bit apprenable par vie**, et la
variance inter-seed des résultats l'écrase. Quatre leviers sont nécessaires *ensemble* :
plus de bits apprenables (actions en S3), plus d'échantillons par bit (amorçage + persistance
entre vies), un effet plus fort par bit (environnement calibré), et une mesure capable de le voir
(métrique de résultat, N seeds, seeds de test réservés).

---

## Principes de conduite

- Aucune amélioration du learner tant qu'il n'est pas établi qu'il existe quelque chose à
  apprendre (Phase 1). Une phase peut invalider les suivantes ; c'est son rôle.
- Tout gate porte sur une métrique de **résultat** (survie, mûres mangées, temps sous seuil),
  jamais sur le `reward` interne.
- Toute comparaison est appariée au même seed, sur ≥ 12 seeds, avec taille d'effet rapportée.
- Toute table apprise est évaluée sur des seeds **réservés**, jamais sur ceux de son entraînement.

---

## Benchmark d'évaluation de la roadmap (avant / après)

Cette roadmap modifie la récompense, l'espace d'action, la portée de l'apprentissage *et*
l'environnement de référence. Sans point de comparaison verrouillé, il sera impossible de dire à
la fin si le travail a produit un gain réel ou seulement déplacé les critères. Le benchmark est
donc défini **maintenant**, avant toute modification, et son critère de succès est écrit avant la
première mesure — pas après.

### Bras verrouillés

| Bras | Rôle |
|---|---|
| `automate` | Référence externe. `BaselineDecider` inchangé. **La barre à battre.** |
| `adaptatif_v1` | Décideur actuel **figé** dans son état du 2026-08-30 (`lr` 0,2, ε 0,2, intervalle 2,0 s). Le « avant ». |
| `aleatoire` | `adaptatif_v1` à ε 1,0 : sélection aléatoire, table jamais lue. Plancher sans apprentissage. |
| `politique_fixe_max_v1` | Meilleure politique fixe de l'espace d'action **original** (Phase 1). Plafond « sans apprendre » **stable** sur toute la durée du benchmark. |
| `politique_fixe_max` | Meilleure politique fixe de l'espace d'action **courant** (réévaluée après la Phase 3). Plafond « sans apprendre » du moment. |
| `adaptatif_courant` | État du learner à la date de la mesure. Le « après ». |

`adaptatif_v1` est conservé comme classe distincte et gelée (`scripts/adaptive_decider_v1.gd`),
pas comme un tag git : les Phases 2 à 4 modifient l'observation et les hooks de fin de vie, un
ancien commit ne serait plus exécutable dans le moteur courant. La duplication est assumée et
temporaire — le fichier est supprimé **à la clôture de la roadmap** (après une éventuelle Phase 6),
pas dès Mf.

### Cas verrouillés

- 12 seeds d'entraînement + 12 seeds de **test réservés**, énumérés explicitement dans
  `experiments/campaigns/benchmark_apprentissage.json`. Une fois le fichier écrit, ces listes ne
  sont plus modifiées : ajouter ou remplacer un seed après avoir vu les résultats invalide la
  comparaison.
- Environnement : `experiments/apprentissage_env_ref.json` gelé en **Phase 1**. Toutes les
  mesures, « avant » comprise, tournent dessus.
- **Config des 3 agents non-apprenants** (Bleu / Vert / Jaune, `decider_type` `automate`) figée
  pour toutes les mesures : ils se disputent les mûres avec l'apprenant, tout changement de leur
  comportement décale la baseline sans que ce soit imputable au learner.
- Durée simulée et conditions d'arrêt identiques pour tous les bras.

### Métriques

- **Primaire** : taux de survie à la fin de la durée simulée, sur les seeds de test.
- Secondaires : durée de vie médiane, mûres mangées, temps passé sous `pickup_hunger_threshold`,
  part des décisions de faim offrant ≥ 2 actions valides.
- **Interdite comme critère** : le `reward` moyen interne. Il change de définition en Phase 2 et
  n'est donc comparable ni avant/après, ni entre bras.

### Calendrier des mesures

| Mesure | Quand | Bras |
|---|---|---|
| **M0 (« avant »)** | Fin de Phase 1, environnement gelé | `automate`, `adaptatif_v1`, `aleatoire`, `politique_fixe_max_v1` |
| M1 | Fin de Phase 2 (refonte du signal) | + `adaptatif_courant` |
| M2 | Fin de Phase 3 (espace d'action) | tous (`politique_fixe_max` réévalué) |
| M3 | Fin de Phase 4 (persistance), sur seeds réservés | tous |
| **Mf (« après »)** | Fin de Phase 5 | tous |

Les mesures intermédiaires servent à attribuer le gain à une phase précise. Si M1, M2 et M3 sont
plates, inutile d'attendre Mf pour le savoir.

### Critère de succès de la roadmap — écrit à l'avance

- **Succès** : à Mf, `adaptatif_courant` bat `adaptatif_v1` **et** `automate` sur les seeds
  réservés, dans le même sens sur ≥ 9 seeds sur 12, métrique primaire.
- **Succès partiel** : bat `adaptatif_v1` mais pas `automate`. L'apprentissage fonctionne mais
  n'atteint pas une heuristique écrite à la main : le consigner tel quel, sans reformuler le
  critère.
- **Échec** : ne bat pas `adaptatif_v1`. La roadmap n'a rien produit de mesurable ; suspendre
  l'axe apprentissage plutôt que lancer une v3.
- Repère supplémentaire, non gate : la position de `adaptatif_courant` par rapport à
  `politique_fixe_max` indique s'il reste de la marge dans l'espace d'action courant (en dessous)
  ou s'il faut l'élargir (au niveau ou au-dessus).

### Budget de calcul (ordre de grandeur)

- Benchmark seul : 6 bras × 24 seeds × 5 mesures ≈ **720 runs**.
- Phase 1 (balayage environnement × politiques fixes × seeds) : c'est le poste dominant. Grille
  grossière 8 environnements × ~7 politiques × 12 seeds ≈ **670 runs**. Raffiner la grille
  ensuite seulement autour du meilleur point.
- Phases 2 à 4 (balayages `γ`, `c`, oracle sur espace élargi, lignées) : ≈ **600 runs** cumulés.
- Total : **~2 000 runs**, soit **~25–30 h** de simulation cumulée à l'objectif de la Phase 0
  (72 runs de 300 s / h). Sans la Phase 0, ce total est hors budget : la Phase 0 n'est pas
  optionnelle.

---

## Phase 0 — Débit expérimental  [FAIT]

Close le 2026-08-31. Parallélisme reproductible de `tools/run_campaign.py` (`--jobs`,
`--retries`, `--warmup`, bras nommés `arms`), égalité bit à bit séquentiel/parallèle vérifiée
(`tools/check_campaign_parallelism.py`), reprise après interruption. Bras gelé `adaptatif_v1`
(`scripts/adaptive_decider_v1.gd`), équivalence à seed fixe vérifiée
(`tools/check_adaptive_v1_equivalence.py`). Gate : 72 runs de 300 s en ~45 min à `--jobs 8`.
`game_speed` x1/x4 : divergence sur le décideur adaptatif documentée comme limite connue
(`.claude/memory.md`).

Prérequis bloquant : les statistiques exigées par toutes les phases suivantes (≥ 12 seeds ×
plusieurs bras) sont hors budget au débit actuel. `tools/run_campaign.py` est séquentiel (aucune
trace de parallélisme dans `tools/`) et `game_speed` est cloué à 1,0 par l'action P2.

- Ajouter le parallélisme à `tools/run_campaign.py` (N processus Godot), avec isolation des
  fichiers de sortie et reproduction **bit à bit** du séquentiel à seeds fixes. La condition
  posée par la Phase 4 de l'ancienne `roadmap_experimentation.md` (« parallélisme seulement après
  validation de l'isolation des fichiers et de Godot ») est à honorer. C'est le vrai chantier de
  cette phase.
- **Geler le bras `adaptatif_v1`** : copier `scripts/adaptive_decider.gd` dans
  `scripts/adaptive_decider_v1.gd`, l'exposer comme `decider_type` distinct. À faire **avant**
  toute autre modification de code : passé la Phase 2, l'état « avant » n'est plus reconstituable.
- `game_speed` (action P2 de `signals.md`) : **hors du gate**. Si le parallélisme atteint la
  cible à `game_speed` 1,0, la divergence x1/x4 n'est pas sur le chemin critique. La documenter
  comme limite connue dans `.claude/memory.md` (toutes les campagnes de la roadmap tournent à
  1,0) ; l'instruire à fond seulement si le débit reste insuffisant.
- Tests : une campagne parallélisée reproduit bit à bit la même campagne séquentielle à seeds
  fixes ; interruption en cours de campagne et reprise sans perte ; `adaptatif_v1` et `adaptatif`
  produisent des runs strictement identiques à seed fixe tant que le second n'a pas été modifié.

**Gate** : une campagne de 72 runs de 300 s simulés s'exécute en moins d'une heure, résultats
identiques au séquentiel.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 1 — Calibrer l'environnement et établir l'oracle  [FAIT]

Close le 2026-08-31. Décideur `politique_fixe` (`scripts/fixed_policy_decider.gd`).
Environnement de référence **gelé** : `vision_range` 15, `hunger_depletion_rate` 0,7,
`ronce_count` 30 (`experiments/apprentissage_env_ref.json`). Gate franchi à n=12 : meilleure
politique fixe `pf_er_rm` survie 0,83, pire `pf_er_er` 0,17, écart 0,67, accord 9/12. Bit
apprenable identifié = décision S2 (viser souvenir vs errer). `pf_rv_rm` ≡ `automate` bit à
bit ; `politique_fixe_max_v1` = `pf_er_rm`. Mesure M0 prise (9 bras, 12 seeds d'entraînement).
Décision : `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md`. Angle mort :
`aleatoire` (0,92) plafonne au-dessus d'`adaptatif_v1` (0,83) — bande Mf étroite sur la survie,
métriques secondaires à mobiliser dès M1.

Fusion de « la tâche est-elle apprenable ? » et « l'environnement discrimine-t-il ? » : les deux
questions se répondent avec la **même** campagne. Séparer les phases forcerait à rejouer l'oracle
après tout changement d'environnement, et rendrait un résultat nul ininterprétable (tâche vide,
ou environnement mal réglé ?).

- Ajouter un mode de politique figée : table préchargée et `exploration_epsilon` 0, ou
  `decider_type` dédié. Aucune mise à jour de score, comportement déterministe.
- Énumérer les politiques déterministes de l'espace d'action **actuel** (S1 : 3 actions × S2 :
  2 actions = 6 politiques), plus `automate` comme référence externe.
- Balayer l'environnement : `vision_range` × `ronce_count` × `hunger_depletion_rate` (grille
  grossière d'abord). Pour **chaque** environnement candidat, exécuter les 7 politiques sur
  ≥ 12 seeds.
- Métriques : durée de survie, mûres mangées, temps passé sous `pickup_hunger_threshold`.
- Choisir l'environnement qui **maximise l'écart** entre la meilleure et la pire politique fixe,
  avec un taux de survie ni nul ni saturé. Le raffiner localement si utile.
- Livrable : `experiments/apprentissage_env_ref.json` (environnement retenu, **gelé** — tout
  changement ultérieur invalide les comparaisons et doit être consigné) et
  `experiments/campaigns/benchmark_apprentissage.json` (bras, seeds d'entraînement, seeds
  réservés).
- La campagne du point retenu **est** la mesure **M0 « avant »** (`automate`, `adaptatif_v1`,
  `aleatoire`, `politique_fixe_max_v1`). Consigner le tableau dans la décision de la phase.

> **Note de travail (2026-08-31, à analyser après la campagne de faisabilité) — « manger au
> contact »**
> Le buffer de 3 mûres (cueillette à `hunger ≤ 90` sac non plein, consommation différée à
> `hunger ≤ 50`) atténue massivement le signal de récompense : une maraude qui rapporte ~50
> points de faim est créditée ~+0,4 au lieu de +1,0, parce que la digestion se fait pendant que
> `_is_hunger_situation` est false (sac plein) et que `_apply_online_reward` ne tourne pas alors.
> Retirer la consommation différée fait retomber le gain de faim dans la fenêtre d'engagement de
> la décision d'approche — c'est le « +1 à la cueillette » de la Phase 2 obtenu sans toucher à la
> formule, et un prérequis de cohérence pour cette Phase 2.
> - Créneau : **conditionnel au gate**. Gate passe → garder le buffer, laisser la Phase 2 gérer.
>   Gate échoue → candidat d'enrichissement d'environnement, sous forme **Variante C** :
>   `eat_hunger_threshold = pickup_hunger_threshold` en config d'env (zéro code), re-probe avec
>   `hunger_depletion_rate` plus bas, re-run de l'oracle.
> - Procéduralement permis seulement **pré-M0** (env encore non gelé), décision explicite à
>   consigner dans `apprentissage_env_ref.json`. Après M0 = violation du bras gelé.
> - Variante A (suppression de l'inventaire) écartée : surface code trop large en cours de
>   roadmap (schéma summary, `aggregate_results.py`, HUD, vecteur RL, tous les `experiments/*.json`).

**Gate** : dans l'environnement retenu, il existe une paire de politiques fixes dont l'écart de
résultat va dans le même sens sur ≥ 9 seeds sur 12, la meilleure survit ≥ 70 % et la pire ≤ 30 %.
**Si aucun environnement de la grille ne sépare les politiques** : l'espace situation/action
actuel ne porte rien d'apprenable dans un environnement viable. Ne pas engager les Phases 2 à 4 ;
remonter à l'utilisateur le choix entre enrichir l'environnement (dangers, ressources
hétérogènes, coûts de déplacement) et suspendre l'axe.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Refonte du signal : récompense événementielle et amorçage  [FAIT]

Close le 2026-09-01. Récompense événementielle (`PICK_REWARD` +1, `survival_cost_rate` −c·Δt,
`TERMINAL_REWARD` −1), amorçage TD (`cible = r + γ·maxQ(s',·)`, γ 0,9), `TABLE_SCHEMA_VERSION`.
Tests d'attribution du crédit verts, déterminisme préservé. M1 v1 : `adaptatif_courant` franchit
le plateau (survie 1,00 vs `aleatoire` 0,92) mais le gate « ≥ 9/12 » est inatteignable, survie
et vie médiane saturées au plafond de l'environnement v1. Décision utilisateur (option 1) :
lire le gate comme franchi sur l'intention, poursuivre. Décision :
`_docs/decisions/2026-09-01_phase2-signal-recompense-td.md`.

Corrige les défauts 2 et 3 du diagnostic.

- **Récompense événementielle** plutôt que variation de faim : `+1` à la cueillette (conséquence
  directe de la décision), coût de survie explicite `−c · Δt` (le décalage constant devient un
  paramètre assumé et réglable, plus un artefact), `−1` terminal à la mort. Retirer
  `REWARD_HUNGER_SCALE` ou le réduire au rôle de coût de survie.
- **Amorçage** : remplacer la moyenne mobile de `_commit_reward` par une mise à jour à
  différence temporelle — `Q(s,a) += α · [r + γ · max Q(s',·) − Q(s,a)]`, γ de l'ordre de 0,9 —
  afin que les fenêtres d'approche héritent de la valeur du repas à venir. Traces d'éligibilité
  (TD(λ)) seulement si la chaîne d'états s'avère trop courte pour propager.
- **Versionner le format de table dumpée** (`apprentissage_table`) : un tag de schéma, pour
  qu'une table produite ici ne soit pas chargée silencieusement par un run d'une phase à
  sémantique de scores différente (Phase 4).
- Tests : scénario scripté d'approche sur 3 fenêtres d'engagement terminée par une cueillette →
  la cellule (S1, `ronce_visible`) finit **positive** (le mécanisme actuel la laisse nulle ou
  négative) ; bornes de récompense respectées ; pénalité terminale toujours appliquée une seule
  fois ; déterminisme à seed fixe inchangé (`tools/check_reproducibility.py`).
- Mesure **M1** du benchmark (tous bras, `adaptatif_courant` entre en lice).

**Gate** : les deux tests d'attribution du crédit passent, **et** `adaptatif_courant` bat
`aleatoire` **et** `adaptatif_v1` sur ≥ 9 seeds sur 12 (métrique de résultat), **sans être pire**
que `politique_fixe_max_v1`. « Battre l'automate » n'est **pas** exigé ici : l'espace d'action
utile n'existe qu'à partir de la Phase 3, ce gate serait un faux négatif.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Élargir l'espace d'action là où les décisions se prennent  [FAIT]

Close le 2026-09-01. S3 passe de 1 à 5 actions (`errance`, `cap_maintenu`, `demi_tour`,
`zone_inconnue`, `zone_connue`) ; S2 gagne `souvenir_ancien`. `politique_fixe` route S3
(`fixed_policy_s3`). Gate (a) acquis (`adaptatif_courant` part multi-action = 1,00). Gate (b)
en échec sur l'env v1 (métriques saturées) mais **franchi sur l'env v2** enrichi
(`cap_maintenu` 0,50 vs `demi_tour` 0,17 = 9-1/12) — les nouvelles actions ne sont pas
cosmétiques, mais aucune ne bat `errance` en politique fixe. Tripwire Phase 2 déclenché →
bifurcation : environnement re-gelé en v2, nouveau M0 v2 / M1 v2. M1 v2 : `adaptatif_courant`
ne se sépare pas de `aleatoire` ni de `adaptatif_v1` → **axe suspendu** (voir bandeau en tête).
Décision : `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md`.

Corrige le défaut 1. Ajoute des actions en S3, pas des situations.

- Nouvelles actions pour S3 (et disponibles ailleurs si pertinent) : maintenir la direction
  courante, demi-tour, viser la zone inconnue la plus proche, viser une zone déjà connue, viser un
  souvenir ancien ou lointain.
- Ces actions réutilisent les mécanismes existants `curiosity` et `known_zone_preference` en les
  transformant en **choix explicites** au lieu de modulations diffuses de l'errance. Cela solde le
  point d'attention hérité de la Phase 8 de l'ancienne `roadmap_experimentation.md` (leur
  interprétation devait être réévaluée une fois la vision disponible).
- Rejouer l'oracle de la Phase 1 sur l'espace élargi → nouvelle valeur de `politique_fixe_max`
  (l'espace d'action a changé). `politique_fixe_max_v1` reste inchangé.
- Mesure **M2** du benchmark (tous bras).

**Gate** : (a) la part des décisions de faim offrant ≥ 2 actions valides passe de ~37 % à ≥ 80 % ;
(b) l'oracle montre un écart de résultat significatif entre au moins deux des nouvelles actions
S3. Si (b) échoue, ces actions sont cosmétiques : les retirer plutôt que les conserver.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Persistance entre vies  [NON ENGAGÉE — axe suspendu]

Corrige le défaut 4. C'est le levier décisif : les Phases 2 et 3 densifient et élargissent le
signal, mais une vie restera toujours courte devant le nombre d'échantillons nécessaires.

- `adaptive_table_in` / `adaptive_table_out` dans `ExperimentConfig` : un run peut démarrer sur
  une table produite par un run précédent et la déverser en fin de vie. Le tag de schéma
  (Phase 2) est vérifié au chargement, refus si incompatible. **Aucune mécanique de jeu à
  modifier** — pas de renaissance à implémenter, la persistance est un artefact de niveau run.
- `tools/run_lineage.py` : enchaîne K générations, chacune amorcée par la table de la précédente,
  sur des seeds tournants.
- Séparation entraînement / test sur les seeds : table entraînée sur les seeds A, évaluée sur des
  seeds B **réservés**. Obligatoire, sinon la table sur-apprend la carte.
- Courbe inter-générations (réutiliser `tools/plot_learning_curve.py`) : résultat par génération.
- Mesure **M3** du benchmark, sur les seeds réservés, `adaptatif_courant` amorcé par la table de
  la génération K.

**Gate** : la table de la génération K bat la table neutre de la génération 0 sur ≥ 12 seeds
réservés, dans le même sens sur ≥ 9 d'entre eux, sur la métrique de résultat.

C'est le point où 1B (« heuristiques apprises ») et 1A (« la table devient un génotype »)
convergent : une table persistée est un contenu transmissible. La sélection entre lignées
deviendrait alors une extension naturelle, hors périmètre de cette roadmap.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 5 — Protocole statistique et verrouillage  [NON ENGAGÉE — axe suspendu]

Corrige le défaut 5, et fige la méthode pour tout travail d'apprentissage ultérieur.

- Standardiser le protocole d'acceptation : ≥ 12 seeds, bras appariés au même seed, métrique de
  résultat, test non paramétrique (test des signes ou Wilcoxon apparié), taille d'effet rapportée.
- Interdire explicitement le `reward` moyen interne comme critère de gate, et consigner pourquoi
  (piège des Phases 3-4 de `roadmap_apprentissage.md`).
- `tools/aggregate_results.py` : comparaison appariée entre bras et test des signes.
- **Mesure Mf « après »** : tous les bras, seeds réservés. Publier le tableau M0 → Mf côte à côte
  et prononcer le verdict selon le critère écrit à l'avance (succès / succès partiel / échec),
  sans le reformuler.
- Décision `_docs/decisions/` + ligne dans `INDEX.md` + section dans `experiments/README.md`.

**Gate** : le protocole est appliqué rétroactivement aux résultats des Phases 2 à 4 et confirme
(ou infirme) leurs conclusions ; Mf est prise et le verdict M0 → Mf est prononcé.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 6 — Approximation de fonction (conditionnelle)  [NON ENGAGÉE — conditionnelle, réouverture sur décision explicite]

**À n'engager que si les Phases 2 à 5 plafonnent**, c'est-à-dire si le learner ne dépasse pas la
meilleure politique fixe malgré un signal correct, un espace d'action large et la persistance.

- Remplacer la discrétisation par une approximation linéaire sur variables continues : faim
  normalisée, distance au roncier visible le plus proche, fraîcheur du souvenir, mûres portées.
- Le plafond de la discrétisation disparaît ; l'infrastructure de récompense, de mesure et de
  persistance des Phases 2 à 5 est réutilisée telle quelle.

C'est l'entrée formelle dans 1C (RL), mais comme prolongement du même socle, pas comme réécriture.

Après cette phase (ou après Mf si elle n'est pas engagée) : supprimer
`scripts/adaptive_decider_v1.gd`, clôturer la roadmap.

## Points ouverts / hors scope

- Sélection entre lignées (1A complet, croisement/mutation de tables) : hors scope, débloqué par
  la Phase 4.
- Plusieurs apprenants simultanés : hors scope (l'environnement bouge sous chaque apprenant).
- Apprentissage sur un besoin autre que la faim : sans objet, un seul besoin implémenté.
- Décideur LLM : hors périmètre. Rappel hérité de l'ancienne `roadmap_experimentation.md` — toute
  campagne LLM antérieure à la Phase 8 (vision) n'est pas comparable à une campagne postérieure.

## Risques

- **La Phase 1 ne sépare aucune politique dans aucun environnement viable.** Risque principal,
  assumé : tout le travail d'apprentissage depuis le début porterait sur une tâche vide. La
  Phase 1 fusionnée le détecte en une campagne au lieu de le diluer sur deux phases. Réponse :
  décision utilisateur (enrichir l'environnement ou suspendre l'axe), pas de contournement.
- **La Phase 0 ne débloque pas le débit.** Sans parallélisme reproductible, les ~2 000 runs de la
  roadmap sont hors budget et le protocole de la Phase 5 devient inapplicable. Repli : réduire
  `max_simulation_seconds` et compenser par plus de seeds, après avoir vérifié que la durée
  réduite ne tronque pas les vies. Le parallélisme bit-exact (isolation fichiers, instances
  Godot, RNG) est un vrai chantier — la Phase 0 peut glisser.
- **Sur-apprentissage de la carte en Phase 4.** Mitigé par les seeds réservés ; à surveiller aussi
  sur la topologie (une seule disposition de ronciers apprise par cœur).
- **γ mal réglé en Phase 2** : trop bas, le crédit ne remonte pas ; trop haut, toutes les cellules
  convergent vers la même valeur. À balayer avec le même protocole que les autres paramètres, et
  seulement après que le test d'attribution du crédit passe.
- **Dérive du bras gelé.** `adaptatif_v1` dépend de l'observation construite par `character.gd`,
  que les Phases 2 à 4 modifient. Si un champ dont il dépend change de sens, la comparaison
  avant/après devient trompeuse sans erreur visible. Mitigation : le test de Phase 0
  (`adaptatif_v1` ≡ `adaptatif` à seed fixe) est rejoué à chaque mesure du benchmark contre la
  trace M0 ; toute divergence non intentionnelle est traitée comme une régression, pas comme un
  résultat.
- **Reformulation du critère de succès après coup.** Le risque le plus probable, et le seul que le
  benchmark ne détecte pas lui-même. Le critère est écrit ci-dessus avant la première mesure ;
  s'il doit changer, le changement est daté et justifié dans la décision, et l'ancien critère
  reste visible.
