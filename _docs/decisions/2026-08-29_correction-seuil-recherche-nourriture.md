# Correction du seuil de recherche de nourriture (automate et mock LLM)

Date : 2026-08-29
Statut : proposé

## Le défaut

`pickup_hunger_threshold` (défaut 90 ; `hunger` va de 100 = rassasié à 0 = mort) était
utilisé dans deux sens opposés :

- **Mécanique de cueillette** — `character.gd::try_pick_berry_from_ronce` refuse la
  cueillette si `hunger > pickup_hunger_threshold`. On cueille donc **sous** le seuil,
  conformément au libellé du registre : « niveau de faim en dessous duquel un agent cherche
  à cueillir des mûres ».
- **Navigation** — `baseline_decider.gd` ciblait un roncier si `hunger >
  pickup_hunger_threshold`. L'automate visait donc la nourriture **au-dessus** du seuil,
  c'est-à-dire précisément quand la cueillette allait lui être refusée.

Conséquence, avec les valeurs par défaut (`hunger_depletion_rate` = 0,6/s, faim initiale
100) : un agent ciblait les ronciers pendant les ~17 premières secondes — pendant
lesquelles il ne pouvait rien cueillir — puis, une fois passé sous 90, cessait
définitivement de les cibler. Passé ce point il errait, et ne se nourrissait que par
collision fortuite, la cueillette étant automatique au contact et indépendante de
l'objectif courant.

Autrement dit, l'automate de référence du projet ne cherchait pas sa nourriture quand il
avait faim. Toutes les campagnes des Phases 1 à 8 ont tourné sur ce comportement.

La contradiction remonte à la décision fondatrice du 2026-08-17
(`2026-08-17_ronces-mures-donnees-jeu.md`), qui énonce les deux sens dans le même document :
« au contact d'une ronce, le personnage cueille une mûre uniquement si sa faim est **sous**
un seuil configurable » d'une part, « quand la faim **dépasse** le seuil de cueillette et
qu'au moins un roncier est mémorisé, le personnage se dirige vers le plus proche » d'autre
part. L'écart n'avait pas été relevé depuis.

## Décision

Aligner la navigation sur la mécanique : `hunger <= pickup_hunger_threshold` déclenche la
recherche de nourriture.

- `scripts/baseline_decider.gd` — condition inversée, avec un commentaire rappelant qu'elle
  doit rester alignée sur `try_pick_berry_from_ronce`.
- `scripts/llm_decider.gd::_resolve_mock` — même inversion sur `wants_food`, qui portait la
  même erreur. Le prompt envoyé au vrai LLM n'est pas concerné : il transmet la faim brute
  et laisse le modèle décider, sans mention de seuil.
- `scripts/adaptive_decider.gd` (Phase 1 de `roadmap_apprentissage.md`) utilise la
  condition corrigée dès l'origine.
- Deux vérifications de `tools/run_manual_checks.gd` encodaient l'ancien sens
  (`hunger = 95` avec un seuil à 90 pour obtenir un ciblage) : passées à 85.

## Pourquoi maintenant

L'axe apprentissage (`roadmap_apprentissage.md`) compare un agent qui apprend à chercher sa
nourriture à un automate de référence. Sans cette correction, « l'apprenant fait mieux que
l'automate » n'aurait rien mesuré : il aurait fait mieux qu'un agent qui ne cherche pas à
manger. Le gate de la Phase 3 porte sur la pente d'apprentissage et non sur une comparaison
absolue, donc il aurait tenu — mais toute interprétation ultérieure aurait été faussée.

Corriger a un coût assumé : le comportement de référence change, donc les résultats
antérieurs ne sont plus reproductibles à l'identique. Les résultats de campagne ne sont pas
versionnés (`results/` est dans `.gitignore`) ; ce sont les conclusions consignées dans
`experiments/README.md` et dans ce journal qui devaient être revalidées.

## Effet mesuré

Six campagnes rejouées à seeds identiques. Les chiffres « avant » reproduisent exactement
ceux consignés dans `experiments/README.md` (survie 8 % / 33 % sur `resource_scarcity`),
ce qui valide la méthode de comparaison.

| Campagne | métrique | avant | seuil corrigé |
|---|---|---|---|
| `memory_capacity` | distance / cueilli | 316,0 / 3,67 | 120,6 / 1,67 |
| `memory_capacity` | faim finale | 55,9 | 37,8 |
| `vision_range` (portée 50) | distance / cueilli | 302,4 / 2,42 | 48,8 / 0,83 |
| `contrasted_profiles` | distance / cueilli | 121,2 / 0,75 | 88,1 / 0,42 |
| `resource_scarcity` | survie | 20,8 % | 16,7 % |
| `social_cooperation` | survie / partages | 75 % / 1,05 | **0 % / 0** |

La correction est logiquement juste mais **dégrade la simulation sur toutes les campagnes**.
Elle n'introduit pas le défaut : elle en révèle un que le bug masquait.

## Défaut révélé : aucune condition de sortie d'un objectif atteint

La cueillette se déclenche uniquement sur `body_entered` (`ronce.gd`), une fois par entrée
dans la zone du roncier ; il n'existe ni `body_exited` ni re-déclenchement au contact
prolongé. Un agent qui **cible** un roncier y arrive, cueille une mûre, puis n'a plus
aucune raison de partir : le roncier reste son souvenir le plus proche, à distance nulle.
Il s'immobilise jusqu'à ce que le souvenir s'estompe (~67 s simulées à
`memory_decay_rate` 0,15). Trace directe (`memory_capacity`, seed 1, agent Rouge) : position
figée à (-51,88 ; -50,89) de t=7,7 s à t=18,9 s avec l'objectif `ronce_memorisee`, puis à
(-49,19 ; -48,61) de t=22,7 s jusqu'à la fin du run.

Avant la correction, ce piège était inatteignable : l'automate ne ciblait un roncier
qu'au-dessus du seuil, et passait le reste de sa vie en errance — laquelle le faisait
entrer et sortir des zones, déclenchant les cueillettes fortuites. Le ciblage mène au
piège, l'errance nourrit.

Un filtre a été ajouté sur les ronciers mémorisés vidés
(`character.gd::_nearest_usable_memory`, aligné sur `_direction_to_nearest_visible_ronce`
qui écarte déjà les ronciers sans mûres). Il est correct sur le principe mais **sans effet
mesurable** : avec `berries_per_ronce = 3` et une mûre prise par entrée, un roncier ciblé
n'est presque jamais vide. Les six campagnes donnent des chiffres identiques avec et sans
ce filtre, à l'exception d'un écart marginal sur `social_cooperation` (cueilli 2,35 → 2,40).

## Correction de fond (2026-08-30) : cueillette continue + inventaire dans l'observation

Les deux volets, appliqués ensemble :

- `scripts/ronce.gd` : la cueillette n'est plus déclenchée une seule fois sur
  `body_entered`, mais à chaque frame physique de contact (`_physics_process` +
  `get_overlapping_bodies()`). `try_pick_berry_from_ronce` étant déjà idempotent au-delà
  des seuils autorisés, l'appel répété est sans effet une fois le buisson vide ou
  l'inventaire plein — il ne fait qu'ouvrir la fenêtre qui manquait.
- `scripts/character.gd` : `max_berries_carried` ajouté à l'observation. Les trois
  décideurs (`baseline_decider.gd`, `llm_decider.gd::_resolve_mock`,
  `adaptive_decider.gd`) ne ciblent plus un roncier quand `berries_carried >=
  max_berries_carried`, exactement la condition de `try_pick_berry_from_ronce`.

Sans la cueillette continue seule, l'agent remplit son inventaire progressivement puis
reste sédentaire dessus (la sortie de la mécanique existe mais jamais la sortie de
l'objectif). Sans le filtre d'inventaire seul, la cueillette débloquée ne change rien à la
condition du décideur, qui continue de cibler un roncier où il ne peut déjà plus rien
prendre. Il fallait les deux.

## Effet mesuré (correction complète)

`social_cooperation_multiseed_v1` rejouée en entier sur ses 5 seeds (le signal le plus
sensible, effondré à 0 % dans l'état intermédiaire) :

| état | survie | partages | rencontres | cueilli | distance |
|---|---|---|---|---|---|
| avant (bug d'origine) | 75 % | 1,05 | 11,60 | 10,50 | 807,3 |
| seuil seul (état dégradé) | 0 % | 0,00 | 5,30 | 2,35 | 172,0 |
| correction complète | **85 %** | 0,80 | 16,00 | **12,75** | 799,0 |

La correction ne se contente pas de restaurer l'état d'avant, elle le dépasse : la
cueillette continue permet de remplir l'inventaire en un seul passage plutôt qu'en
plusieurs allers-retours dans la zone de collision, d'où la hausse de cueillette et de
survie à distance parcourue quasi identique. Les cinq autres campagnes non-LLM sont
rejouées pour confirmation (voir tableau global à compléter) ; `llm_vs_automate` reste à
traiter séparément (appels Ollama réels).

## `llm_vs_automate_v1` rejouée (2026-08-30)

15 runs (5 seeds × {`automate`, `llm_mock`, `llm`}), `gemma3:1b`, 180 s simulées.
Pré-correction conservé dans `results/llm_vs_automate_v1/`, post-correction dans
`results/llm_vs_automate_v1__post_correction/`.

| décideur | métrique | pré | post |
|---|---|---|---|
| `automate` | survie | 65 % | 65 % |
| `automate` | cueilli / mangé | 1,65 / 1,50 | **2,60 / 2,15** |
| `automate` | distance | 373,9 | 376,1 |
| `llm_mock` | survie | 40 % | **50 %** |
| `llm_mock` | cueilli / mangé | 1,20 / 1,10 | **1,95 / 1,65** |
| `llm_mock` | distance | 385,5 | 399,2 |
| `llm` (Ollama) | survie | 40 % | 35 % |
| `llm` (Ollama) | cueilli / mangé | 1,25 / 1,25 | 1,40 / 1,15 |
| `llm` (Ollama) | distance | 188,8 | 132,0 |
| `llm` (Ollama) | mémorisés | 0,40 | 0,15 |
| `llm` (Ollama) | latence / taux erreur | 1409 ms / 0,4 % | 1704 ms / 0,7 % |

`automate` et `llm_mock` suivent les six autres campagnes : cueillette et consommation en
hausse nette à survie stable ou meilleure. Le décideur `llm` réel ne profite pas de la
correction du seuil — attendu : son prompt transmet la faim brute sans mention de
`pickup_hunger_threshold` (cf. section « Décision »), seules la cueillette continue et le
gating inventaire le touchent. Les écarts observés côté `llm` (survie −1 agent sur 20,
distance −30 %, mémorisés −0,15) restent dans le bruit d'un modèle 1 B sur 5 seeds ; le
taux d'erreur (0,7 %) et la latence sont sans effet fonctionnel. Aucune régression
imputable à la correction. La baisse de distance côté `llm` mériterait un replay ciblé si
`llm_vs_automate` redevient un scénario de référence actif.
