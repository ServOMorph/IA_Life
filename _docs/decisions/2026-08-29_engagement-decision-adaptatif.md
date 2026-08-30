# Décideur adaptatif — l'action choisie est tenue pendant un intervalle

Date : 2026-08-29
Statut : proposé

## Problème

Le décideur est interrogé à chaque frame physique (`Character::_apply_decision`, 60 Hz).
L'automate est déterministe : à situation constante il renvoie la même action, donc son
objectif reste stable. Le décideur adaptatif, lui, tire une action par ε-greedy à chaque
appel : avec `exploration_epsilon = 0.3` et trois actions valides, il change d'avis
plusieurs dizaines de fois par seconde.

Deux conséquences, la seconde bloquante pour la suite de la roadmap apprentissage :

- L'agent oscille entre directions cibles et progresse peu.
- La récompense prévue en Phase 2 est la variation de faim entre deux décisions
  consécutives. Entre deux frames, la faim varie de l'ordre du centième de point : une
  fois normalisée et bornée, c'est du bruit centré sur zéro. Les scores de la table
  convergeraient vers du bruit, et l'action qui a réellement mené l'agent jusqu'à un
  roncier ne recevrait pas le crédit — des centaines d'autres se sont intercalées.

La roadmap listait « fenêtre de récompense mal calée » comme un réglage à ajuster en
Phase 2/4. Le constat est plus structurel : rien ne faisait tenir une action, donc il n'y
avait aucune fenêtre à régler.

## Décision

`AdaptiveDecider` tient l'action choisie pendant `adaptive_decision_interval_seconds` de
temps simulé (nouvelle variable au registre, portée individuelle, catégorie `décision`,
défaut `2.0`, bornes `[0.1, 60.0]`). Le pattern est calqué sur
`llm_decision_interval_seconds`, déjà validé en Phase 7.

Précisions de conception :

- **C'est l'action qui est figée, pas la trajectoire.** La direction est recalculée à
  chaque frame à partir de l'action tenue et de l'observation courante, sinon l'agent
  irait tout droit pendant que sa cible se déplace relativement à lui.
- **Trois évènements reprennent la décision avant l'expiration** : la situation
  discrétisée change (le crédit d'une cellule doit couvrir une période où sa situation
  était réelle), l'action tenue devient inapplicable (viser un souvenir qu'on n'a plus),
  ou l'agent sort de la situation de faim.
- **La fenêtre de récompense de la Phase 2 est exactement la fenêtre d'engagement**, ce
  qui rend le paramètre directement balayable en Phase 4.

## Alternatives écartées

- **Engagement jusqu'au seul changement de situation** (sans intervalle) : plus élégant
  sémantiquement — une récompense = un épisode de situation — mais il couple la fenêtre de
  récompense à la discrétisation, or celle-ci est déjà le risque n°1 de
  `roadmap_apprentissage.md`. En cas de plateau en Phase 3, il faut pouvoir diagnostiquer
  une variable à la fois. Cette option est en outre exposée au papillonnage si la
  situation oscille (roncier à la limite de la portée de vision).
- **Les deux combinés** (engagement borné par un délai maximal) : garde le couplage et
  ajoute un paramètre.

## Commentaire

Un intervalle nul reproduit le comportement sans engagement, ce qui sert de témoin dans
les tests. Six vérifications ajoutées à `tools/run_manual_checks.gd::_test_adaptive_engagement` :
action tenue sur l'intervalle, intervalle nul redécidant à chaque frame, nouvelle décision
à l'expiration, direction recalculée en cours d'engagement, reprise sur changement de
situation, reprise sur action invalidée, libération en sortie de faim.

Aucune mesure de l'effet de ce paramètre sur la survie ou sur la pente d'apprentissage :
la Phase 1 ne met pas la table à jour. Le réglage du défaut `2.0` est un choix de départ
raisonné (à `hunger_depletion_rate = 0.6`/s, la fenêtre couvre 1,2 point de faim, contre
environ 16,7 points gagnés par mûre consommée : le signal d'un repas domine largement la
déplétion de fond), pas un optimum mesuré. À balayer en Phase 4.
