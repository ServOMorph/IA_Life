# Roadmap — Décors avec collisions

Créée le : 2026-10-03
Statut : **[TODO]**

## Objectif

Permettre d'ajouter des éléments de décor bloquants (arbres d'abord, autres décors ensuite) pour le
réalisme, sans que la survie mesurée ne chute à cause de la navigation plutôt que des décisions des
agents. Les arbres actuels (108, collisions désactivées) servent de premier cas.

## Constats de départ (code au 2026-10-03)

- `scripts/main.gd` : `_build_decor()` (8 rochers, 108 arbres, RNG dédié seedé sur
  `_experiment_seed`) est appelé avant `_spawn_ronces()` (RNG global) ; aucune exclusion autour des
  ronciers ni des points de départ.
- Les rochers ont déjà une collision active : les références actuelles incluent donc 8 obstacles.
- Tronc d'arbre : `CylinderShape3D` rayon `0.2 × échelle`, hauteur `2 × échelle`, `disabled = true`.
- `scripts/character.gd` : contact vertical → `_bounce_back()`. Le demi-tour (1,5 à 4 s) n'agit
  qu'en errance ; en ciblage de roncier (visible ou mémorisé), `baseline_decider.gd` recalcule la
  direction vers la cible à chaque image et annule le demi-tour : contre un tronc, glissement ou
  blocage frontal. Aucun contournement.
- `scripts/llm_survie_engine.gd` : trajectoire en ligne droite ; blocage après 3 s sous 0,5 m
  → cible ou direction retirée dans un rayon de 6 m.
- `scripts/danger_detour.gd` : contournement existant pour les zones dangereuses, piste de
  réutilisation à évaluer.
- Vision : `vision_blocked_by_terrain` (défaut `false`) ; activée, les troncs masqueraient les
  ronciers.

## Périmètre verrouillé

| Sujet | Décision |
|---|---|
| Activation | Variable `decor_collisions`, défaut `false`, pilote arbres et futurs décors ; rochers toujours bloquants |
| Premier décor | Troncs d'arbres ; tout nouveau décor bloquant passe par le même mécanisme |
| Mesure | `game_speed = 1.0` ; `llm_survie` à `--jobs 1` |
| Hors périmètre | Pathfinding global (NavigationServer), repousse, danger, apprentissage |

## Risques et parades

- **Rupture des références** : le placement des rochers change, donc les runs `automate` et
  `llm_survie` aussi. Accepté ; parade : nouvelle référence sans collisions d'arbres en Phase 5.
- **Ronciers inaccessibles** : tronc collé à un roncier. Parade : rayon d'exclusion en Phase 1.
- **Blocage `llm_survie`** : un tronc sur la ligne droite marque à tort une cible comme bloquée.
  Parade : contournement local en Phase 4 avant toute campagne LLM.
- **Contournement trop coûteux en temps** : parade par mesure du nombre de contacts et de la durée
  des contournements dans les logs.

## Phases

### Phase 0 — Contrat et référence [TODO]

- Définir la variable `decor_collisions` (registre, portée globale, non modifiable en direct).
- Décidé (2026-10-03) : l'exclusion de placement s'applique aux rochers comme aux arbres. Rupture
  des références `automate` et `llm_survie` assumée : nouvelle référence mesurée en Phase 5.
- Décidé (2026-10-03) : les rochers gardent leur collision en permanence ; `decor_collisions`
  ne pilote que les arbres et les futurs décors.
- Fixer les rayons d'exclusion (ronciers, points de départ, autres décors).
- Fixer les seuils du gate de Phase 3 : durée maximale de blocage frontal (N s) et nombre de
  cartes testées (M).
- Définir les indicateurs journalisés : contacts obstacle, contournements, blocages, durée de vie.
- Critère de succès de la Phase 5, défini avec l'utilisateur.

**Gate** : contrat écrit dans `experiments/decor_collisions_contrat_v1.md`, validé par l'utilisateur.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 1 — Placement sûr [TODO]

- Construire le décor après les ronciers, avec rejet des positions trop proches des ronciers,
  des points de départ et des autres décors (RNG dédié conservé).
- Mécanisme générique réutilisable par tout futur décor.

**Gate** : tests verts — distances minimales respectées sur N graines ; positions des ronciers
inchangées.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 2 — Interrupteur de collisions [TODO]

- `decor_collisions` active les troncs ; journalisation des contacts obstacle.
- Vérifier l'occlusion de la vision quand `vision_blocked_by_terrain` est actif.

**Gate** : tests verts — `false` : simulation identique à la Phase 1 ; `true` : un agent est
physiquement bloqué par un tronc ; occlusion effective si la vision bloquée est active.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 3 — Contournement automate [TODO]

- Ciblage de roncier (risque principal) : contournement local du décor (décalage latéral puis
  reprise du cap vers la cible) ; évaluer la réutilisation de `danger_detour.gd`.
- Errance : demi-tour actuel conservé ou remplacé selon la mesure des contacts.
- Le comportement contre les murs reste inchangé.

**Gate** : tests verts — un agent rejoint un roncier situé derrière un tronc ; aucun agent en
blocage frontal contre un tronc plus de N s en ciblage de roncier sur M cartes (N et M fixés en Phase 0)
avec collisions ; `decor_collisions = false` inchangé.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 4 — Contournement `llm_survie` [TODO]

- Appliquer le contournement aux actions `aller_vers` et `explorer` du moteur.
- Un blocage n'est déclaré qu'après échec du contournement.

**Gate** : tests verts avec le décideur mock — cible derrière un tronc atteinte, pas de
`blocked_targets` à tort ; `decor_collisions = false` inchangé.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 5 — Campagne de contrôle [TODO]

- Bras `automate` avec et sans collisions sur 6 cartes (parallélisable).
- Si l'automate est viable : bras `llm_survie` avec et sans collisions (`--jobs 1`, Ollama actif).
- Rapport : survie, contacts, contournements, blocages ; décision d'activation par défaut ou non.

**Gate** : critère de la Phase 0 évalué ; décision consignée dans `_docs/decisions/`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
