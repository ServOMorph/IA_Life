# Roadmap — Apprentissage intra-vie (heuristiques apprises sur la faim)

> **Roadmap close (2026-08-30).** Les 4 phases sont [FAIT] côté code. L'apprentissage intra-vie
> 1B ne rend pas de façon fiable en une vie (effet non généralisé sur 2 seeds, `learning_rate`
> sans levier). Diagnostic racine et suite de l'axe : `roadmap_apprentissage_v2.md`.

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

## Phase 1 — Squelette du décideur adaptatif  [FAIT]

- `scripts/adaptive_decider.gd` : nouvelle classe (`extends RefCounted`, aligné sur
  `BaselineDecider`). `decide()` reproduit exactement `BaselineDecider` pour manuel / social /
  errance ; seule la branche « faim » change : discrétisation en S1/S2/S3, table initialisée
  neutre, sélection ε-greedy, mémorisation de `(situation, action, hunger, temps)` pour la MAJ
  ultérieure (pas encore de MAJ en Phase 1).
- `scripts/variable_registry.gd` : `"adaptatif"` ajouté à l'enum `decider_type` (L39) ;
  variables `learning_rate`, `exploration_epsilon` et `adaptive_decision_interval_seconds`
  ajoutées (scope `individuelle`, catégorie `décision`, `live_editable` false).
- `scripts/character.gd::_build_decider()` : arm `"adaptatif"` → `AdaptiveDecider.new()`.
  Observation complétée : `berries_carried`, `max_berries_carried`, `eat_hunger_threshold`,
  `elapsed_seconds`.
- RNG : instance `RandomNumberGenerator` seedée par personnage (`decider_seed` du run + hash du
  nom), aligné sur la façon dont le projet sème l'aléatoire ailleurs. Déterminisme vérifié par
  `tools/check_reproducibility.py` sur un run réel.
- **Ajout non prévu au périmètre initial : engagement sur l'action.** Interroger le décideur à
  chaque frame physique avec un ε-greedy produisait un changement d'avis plusieurs dizaines de
  fois par seconde (409 transitions de goal sur un run de 120 s), rendant toute mesure de
  récompense en Phase 2 inexploitable. `adaptive_decision_interval_seconds` (défaut 2,0 s) fait
  tenir l'action choisie ; la direction reste recalculée à chaque frame. Décision :
  `_docs/decisions/2026-08-29_engagement-decision-adaptatif.md`.
- Tests (`tools/run_manual_checks.gd`) : discrétisation des 3 situations, sélection gloutonne à
  ε=0, équivalence stricte à `BaselineDecider` hors situation de faim, déterminisme à seed fixe,
  registre + dispatch, engagement sur l'intervalle (6 vérifications), gating sur l'inventaire
  plein (voir correctif ci-dessous).

### Correctif de mécanique découvert pendant la Phase 1 (2026-08-29/30)

En alignant `AdaptiveDecider` sur la condition réelle de cueillette
(`try_pick_berry_from_ronce`), deux bugs préexistants dans **tout** le projet (automate et LLM
mock, pas seulement l'adaptatif) sont apparus :

1. `baseline_decider.gd` ciblait un roncier au-dessus du seuil de faim (`>`) alors que la
   cueillette n'est autorisée qu'en dessous (`<=`) — l'automate de référence ne cherchait
   jamais sa nourriture quand il avait faim.
2. Corriger (1) a révélé qu'aucun mécanisme ne fait sortir un agent d'un objectif de cueillette
   atteint : la récolte ne se déclenchait qu'une fois sur `body_entered`, et le décideur pouvait
   cibler un roncier même l'inventaire plein. Un agent qui ciblait enfin un roncier s'y figeait.

Corrigé : condition `<=` dans `baseline_decider.gd` et `llm_decider.gd::_resolve_mock` ; cueillette
continue tant que l'agent est au contact (`ronce.gd::_physics_process`) ; `max_berries_carried`
ajouté à l'observation et aux trois décideurs pour ne plus cibler un roncier quand l'inventaire
est plein. Six campagnes de référence rejouées à seeds identiques pour validation — la plus
sensible (`social_cooperation_multiseed_v1`, effondrée à 0 % de survie dans l'état intermédiaire)
remonte à 85 % de survie, au-dessus des 75 % d'origine. Détail et tableau complet :
`_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md`.

**Non traité, hors périmètre de cette roadmap** : `experiments/campaigns/llm_vs_automate_v1.json`
(15 runs, dont 5 appels Ollama réels) pas rejoué — Ollama injoignable en fin de session
(`127.0.0.1:11434` refuse la connexion, contrairement à la note précédente de `signals.md`).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Récompense et mise à jour en ligne  [FAIT]

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

Réalisé le 2026-08-30 : `adaptive_decider.gd` (`_apply_online_reward`, `_commit_reward`,
`on_terminal_starvation`, `log_table`), hooks fin de vie dans `character.gd` et `main.gd`,
2 tests dans `run_manual_checks.gd`. `REWARD_HUNGER_SCALE` reste une constante interne (5,0).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Campagne de validation (gate)  [FAIT]

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

Réalisé le 2026-08-30. Le gate de pente absolue n'a pas fonctionné (transitoire de faim
initiale commun à tous les comportements ; `vision_range` 40 → 100 % S1). **Recalibré** : gate
= `reward` moyen de l'apprenant (`exploration_epsilon` 0,2) au-dessus d'un bras de contrôle
(`exploration_epsilon` 1,0, sélection aléatoire) au même seed, `vision_range` 15. Ainsi
recalibré, gate franchi sur le seed testé (learner −0,203 > contrôle −0,250, reproductible ;
table S1 `ronce_visible` → +0,106 ; learner survit, contrôle meurt). Outils :
`aggregate_results.py --learning-curve`, `tools/plot_learning_curve.py`. Décision :
`_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Robustesse et réglages  [FAIT]

- Balayage `learning_rate` × `exploration_epsilon` (petite campagne multi-valeurs) : trouver une
  plage qui apprend sans osciller.
- Plusieurs seeds : la progression tient-elle en moyenne, ou seulement sur un seed chanceux ?
- Sous-cas « porte des mûres » : l'ajouter aux situations seulement si Phase 3/4 montre que ça
  change le comportement.
- Décider explicitement de la suite (ligne dans `signals.md`) : persistance entre vies (1B
  étendu), plusieurs apprenants simultanés, ou bascule vers 1C (RL).

Réalisé le 2026-08-30 (`experiments/apprentissage_faim_v2.json`,
`experiments/campaigns/apprentissage_faim_v2_sweep.json`, `lr` ∈ {0,1 ; 0,2 ; 0,4} ×
`ε` ∈ {0,1 ; 0,2 ; 0,4 ; 1,0}, 2 seeds, 24 runs). Résultat : l'avantage de l'apprenant sur le
contrôle **ne généralise pas** (+0,07 de `reward` sur un seed, nul/négatif sur l'autre) ;
`learning_rate` sans effet mesurable (suites de récompense identiques au bit près sur le seed
« propre ») ; seul signal robuste : `exploration_epsilon` ≤ 0,2. Aucune configuration
n'oscille. Sous-cas « porte des mûres » non ajouté (Phase 3/4 ne l'a pas motivé). Décision de
suite reportée à `signals.md` : bifurcation à trancher (affiner la discrétisation 1B, ou acter
que 1B ne rend pas en une vie et arbitrer 1A / 1C). Détail :
`_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md` (sections Phase 4).

---

**Roadmap terminée côté code (4 phases).** Suite de l'axe : voir action P1 de `signals.md`.

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
  du mérite). Le risque structurel (aucune fenêtre du tout) est levé en Phase 1
  (`adaptive_decision_interval_seconds`) ; reste à régler sa valeur en Phase 2/4.
- ~~Déterminisme de l'ε-greedy~~ : levé en Phase 1, vérifié par
  `tools/check_reproducibility.py` sur un run réel (deux exécutions à seed fixe strictement
  identiques).
