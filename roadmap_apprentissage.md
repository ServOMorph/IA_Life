# Roadmap — Apprentissage intra-vie (heuristiques apprises sur la faim)

## Objectif

Ajouter un troisième décideur `adaptive_decider.gd` qui **apprend pendant une seule vie** quelle
action de recherche de nourriture marche selon la situation de faim, via une table
`(situation, action) → score` mise à jour en ligne. Un seul personnage apprenant (le n°0), les
autres en automate. **Pas de persistance entre vies** (hors scope de cette roadmap).

C'est le premier pas concret de l'axe « Apprentissage » (option 1B). 1A (sélection/évolution) et
1C (RL formel) restent des axes distincts, non traités ici.

## État de départ (2026-08-29)

- Décideurs interchangeables (Phase 7 du projet) : `decider_type` par personnage, enum
  `["automate", "llm", "llm_mock"]`, dispatché dans `character.gd::_build_decider()` (L114).
- Interface décideur : `decide(observation: Dictionary) -> Dictionary` renvoyant
  `{"goal", "direction", "renew_wander"}`. Goals existants : `controle_manuel`, `ronce_visible`,
  `ronce_memorisee`, `errance`, + goals sociaux.
- Un seul besoin : `hunger` (0–100, se vide, mort à 0). Nourriture : ronces → mûres. Seuils
  `pickup_hunger_threshold` (en dessous : cherche à cueillir), `eat_hunger_threshold`.
  Cueillette/repas automatiques au contact dans `character.gd`, pas des goals.
- Observation (construite `character.gd` ~L210) contient déjà : `hunger`,
  `pickup_hunger_threshold`, `has_visible_ronce`, `visible_ronce_direction`, `has_memories`,
  `memory_direction`, `social_goal`, `social_direction`, `current_direction`, `wander_timer`,
  `delta`, `manual_control`, `manual_direction`.
- Outillage réutilisable : runner headless, logs JSONL, `experiments/*.json`, `campaigns/*.json`,
  `tools/aggregate_results.py`, `tools/plot_campaign.py` (SVG sans dépendance),
  `tools/run_manual_checks.gd`. Déterminisme par seed.

## Modèle d'apprentissage retenu

- **Situations** (uniquement quand `hunger <= pickup_hunger_threshold` ; sinon le décideur se
  comporte comme l'automate : social puis errance) :
  - S1 : roncier visible (`has_visible_ronce`)
  - S2 : pas visible mais quelque chose en mémoire (`has_memories`)
  - S3 : ni visible ni mémorisé
- **Actions** (goals) : `ronce_visible` (S1 seulement), `ronce_memorisee` (S1, S2), `errance`
  (partout). Table = 3 situations × ≤ 3 actions, ~5–7 cellules valides → apprend vite même en
  une vie.
- **Sélection** : ε-greedy (meilleur score, sinon action valide au hasard), RNG seedé par
  personnage.
- **Récompense** : au début de chaque décision de faim, `reward = clamp((hunger_now −
  hunger_derniere_decision) / échelle, −1, 1)` ; mise à jour `score += learning_rate ×
  (reward − score)` (moyenne mobile). Pénalité négative sur la dernière `(situation, action)` à
  la mort de faim.
- **Portée** : la table repart de zéro à chaque naissance.

## Phase 1 — Squelette du décideur adaptatif  [EN COURS]

- `scripts/adaptive_decider.gd` : nouvelle classe (`extends RefCounted`, aligné sur
  `BaselineDecider`). `decide()` reproduit exactement `BaselineDecider` pour manuel / social /
  errance ; seule la branche « faim » change : discrétisation en S1/S2/S3, table initialisée
  neutre, sélection ε-greedy, mémorisation de `(situation, action, hunger, temps)` pour la MAJ
  ultérieure (pas encore de MAJ en Phase 1).
- `scripts/variable_registry.gd` : ajouter `"adaptatif"` à l'enum `decider_type` (L39) ;
  nouvelles variables `learning_rate` et `exploration_epsilon` (scope `individuelle`, catégorie
  `décision`, `live_editable` false).
- `scripts/character.gd::_build_decider()` : ajouter l'arm `"adaptatif"` → `AdaptiveDecider.new()`.
- Vérifier que l'observation porte tout le nécessaire ; ajouter `berries_carried`,
  `eat_hunger_threshold` et un compteur de temps/step si absents.
- RNG : instance `RandomNumberGenerator` seedée par personnage (aligné sur la façon dont le
  projet sème l'aléatoire ailleurs).
- Tests (`tools/run_manual_checks.gd`) : discrétisation correcte des 3 situations ; `epsilon = 0`
  → renvoie toujours l'action au meilleur score ; manuel / social / errance strictement
  identiques à `BaselineDecider` ; deux exécutions à seed fixe → mêmes tirages ε-greedy.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Récompense et mise à jour en ligne  [TODO]

- Au début de chaque `decide()` en situation de faim : calculer `reward` depuis la variation de
  `hunger` depuis la dernière décision de faim (normalisée, bornée `[-1, 1]`) ; appliquer
  `score += learning_rate × (reward − score)`.
- MAJ terminale à la mort de faim (`character.gd`, log `"mort"` ~L296) : `reward` négatif sur la
  dernière `(situation, action)` mémorisée, une seule fois.
- Logs (`GameLogger.log_event_data`) : `apprentissage_decision` (situation, action, exploré,
  score de l'action choisie) ; `apprentissage_maj` (reward, ancien score, nouveau score) ;
  `apprentissage_table` (dump de la table en fin de vie).
- Tests : séquence scriptée situation → action → Δhunger connu → score attendu ; borne de reward
  respectée ; MAJ terminale appelée exactement une fois.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Campagne de validation (gate)  [TODO]

- `experiments/apprentissage_faim_v1.json` : seed fixe, personnage 0 en `adaptatif`, les autres
  en `automate`, durée simulée permettant plusieurs dizaines de décisions de faim pour l'apprenant.
- `tools/aggregate_results.py` : taux de décisions de faim « réussies » (`reward > 0`) par fenêtre
  glissante sur la vie de l'apprenant.
- Graphe SVG (style `tools/plot_campaign.py`) : taux de réussite vs temps.
- **Gate** : la courbe monte de façon reproductible (2 exécutions identiques → mêmes chiffres) et
  l'apprenant finit au-dessus de son taux de réussite initial. La comparaison absolue avec un
  automate dans la même vie n'est PAS le critère (l'apprenant explore, il peut être moins bon en
  une vie) — le signal, c'est la pente.
- Consigner : `experiments/README.md` + décision
  `_docs/decisions/2026-08-JJ_apprentissage-intra-vie-faim.md` (+ ligne dans
  `_docs/decisions/INDEX.md`).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Robustesse et réglages  [TODO]

- Balayage `learning_rate` × `exploration_epsilon` (petite campagne multi-valeurs) : trouver une
  plage qui apprend sans osciller.
- Plusieurs seeds : la progression tient-elle en moyenne, ou seulement sur un seed chanceux ?
- Sous-cas « porte des mûres » : l'ajouter aux situations seulement si Phase 3/4 montre que ça
  change le comportement.
- Décider explicitement de la suite (ligne dans `signals.md`) : persistance entre vies (1B
  étendu), plusieurs apprenants simultanés, ou bascule vers 1C (RL).

## Points ouverts / hors scope

- Persistance de la table entre vies : hors scope de cette roadmap.
- Plusieurs apprenants en même temps : hors scope (l'environnement bouge sous chaque apprenant,
  analyse plus dure — un seul apprenant d'abord).
- Apprentissage sur autre chose que la faim : sans objet (un seul besoin implémenté).
- L'apprenant explore → mortalité plus élevée que l'automate en une vie : comportement attendu,
  pas un échec.

## Risques

- **Discrétisation trop grossière** → plateau bas. Si Phase 3 plafonne, revoir les situations
  avant de conclure à un échec de la méthode.
- **Fenêtre de récompense mal calée** (trop courte : bruit ; trop longue : mauvaise attribution
  du mérite). Paramétrable, à régler en Phase 2/4.
- **Déterminisme de l'ε-greedy** : doit être 100 % reproductible à seed fixe, sinon la courbe de
  Phase 3 n'est pas exploitable.
