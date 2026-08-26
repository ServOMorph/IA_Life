# Décideurs interchangeables (automate / LLM Ollama local)

**Date :** 2026-08-26
**Statut :** proposé

## Décision
Le décideur de chaque personnage (`Character._decider`) devient interchangeable par
configuration (`decider_type` : `automate` / `llm` / `llm_mock`), sans modifier
`BaselineDecider` (adaptateur de référence inchangé). Le backend LLM retenu est **Ollama
local** (`http://127.0.0.1:11434/api/generate`) — pas d'API cloud, pas de clé/secret à gérer.

Le décideur LLM (`LLMDecider`) ne bloque jamais la boucle physique : `decide()` retourne
toujours immédiatement la dernière action connue, une requête HTTP asynchrone
(`HTTPRequest` natif Godot) étant déclenchée en arrière-plan à intervalle configurable
(`llm_decision_interval_seconds`). Le LLM produit un vocabulaire fermé (intention +
direction 8-way), traduit en interne vers le même contrat `{goal, direction, renew_wander}`
que l'automate — aucune action hors de l'espace de référence n'est possible.

Toute erreur (timeout, JSON invalide, Ollama indisponible, réponse hors énumération)
déclenche un repli immédiat sur `BaselineDecider`, journalisé (`llm_decider_erreur`), sans
jamais bloquer un run headless ou une campagne.

**Compromis assumé — reproductibilité :** un run avec `decider_type=llm` n'est pas
reproductible seed-à-seed (latence et contenu réseau non déterministes). Ce n'est pas
contourné artificiellement ; toute campagne comparative doit le documenter explicitement
(voir `experiments/campaigns/llm_vs_automate_v1.json`).

## Implémentation
- `scripts/variable_registry.gd` : support des types `enum`/`string` dans `validate_values`
  et `default_value` ; nouvelles variables individuelles `decider_type`, `llm_model`,
  `llm_decision_interval_seconds`, `llm_timeout_seconds` (catégorie `décision`).
- `scripts/character.gd` : `_decider` construit dans `_ready()` via `_build_decider()`
  (auparavant instancié en dur) ; validation défensive de l'action retournée dans
  `_apply_decision` (garde-fou indépendant du décideur) ; compteurs `llm_calls_total`,
  `llm_errors_total`, `llm_total_latency_ms` délégués au décideur.
- `scripts/llm_decider.gd` (nouveau, `class_name LLMDecider extends Node`) : throttle par
  cooldown, un seul appel en vol, mode `llm_mock` déterministe (aucun appel réseau) pour
  tester sans dépendance Ollama, mode `llm` réel via `HTTPRequest` (`use_threads = false` —
  voir Point résolu ci-dessous). Le champ `format` de la requête Ollama porte un schéma JSON
  strict (`type/properties/enum/required`) plutôt qu'un simple `"json"`, pour forcer un
  décodage contraint côté serveur et garantir la conformité du vocabulaire fermé.
- `scripts/main.gd` : compteurs LLM ajoutés au résumé de run (`_finish_headless_run`).
- `scripts/ui_manager.gd` : correctif d'affichage de l'Inspecteur pour les types
  `enum`/`string` (l'ancien formatage numérique aurait affiché `"0.00"`) ; note statique
  mise à jour.
- `tools/aggregate_results.py` : `DECIDER_AGENT_FIELDS` (optionnels, rétrocompatibles),
  métriques dérivées `mean_llm_calls`, `llm_error_rate`, `mean_llm_latency_ms`.
- `experiments/llm_mock_smoke_v1.json` : scénario de fumée sans Ollama.
- `experiments/llm_vs_automate_v1.json` + `experiments/campaigns/llm_vs_automate_v1.json` :
  configuration et campagne comparative (`automate` / `llm_mock` / `llm`, 5 seeds).

## Validation
- Smoke test global (`tools/run_smoke_tests.py`) : vert, aucune régression sur le
  comportement `automate` par défaut.
- Scénario `llm_mock` : 15 appels sur 30 s simulées à l'intervalle configuré (2 s), 0 erreur,
  directions cycliques déterministes, événements `llm_decision` conformes dans le `.jsonl`.
- Agrégation (`tools/aggregate_results.py`) : validation de schéma et rapport (métriques
  `mean_llm_calls`, `llm_error_rate`, `mean_llm_latency_ms`) corrects sur le résumé mock.
- Campagne (`tools/run_campaign.py --dry-run`) : plan de 15 runs (3 déciders × 5 seeds)
  généré correctement.
- Mode `llm` réel, Ollama arrêté : repli automate immédiat, run non bloqué, erreur
  `llm_decider_erreur` (raison `reseau`) journalisée à chaque tentative.
- Mode `llm` réel, Ollama actif (modèle `gemma3:4b`, timeout 3 s) : timeout Godot déclenché
  (chargement à froid du modèle > budget), repli automate confirmé fonctionnel — comportement
  attendu, pas une anomalie.
- Chemin de succès complet (réponse LLM reçue et appliquée) : confirmé après correction du
  bug ci-dessous — deux appels réussis, latence ~1 s chacun, schéma respecté.

## Point résolu — HTTPRequest threadé bloqué dans la scène complète
Un premier test avec `gemma3:1b` et un timeout de 60 s a systématiquement échoué par timeout
Godot (`result = 13`), alors qu'une requête identique (même payload, mêmes headers) réussissait
en moins de 2 s en isolation (`godot --headless --script`, scène minimale) et via `curl` direct
(8,4 s). La requête n'échouait donc que dans le contexte de la scène complète (4 personnages,
terrain, ronces). Cause retenue : contention du `WorkerThreadPool` de Godot — `HTTPRequest`
est threadé par défaut (`use_threads = true`), et la tâche réseau restait en attente derrière
d'autres tâches du pool (physique, shaders) le temps du chargement de la scène. Correctif :
`_http.use_threads = false` dans `LLMDecider._ready()` — la requête est alors traitée par
polling direct dans `_process()`, sans passer par le pool. Après correctif, deux requêtes
consécutives ont abouti en ~1 s chacune dans la scène complète.

Effet de bord positif constaté en cours de diagnostic : le modèle `gemma3:1b` ne respectait
pas de façon fiable le vocabulaire fermé demandé via `"format": "json"` (réponses JSON valides
mais hors schéma, ex. clé `direction` absente ou valeur `intention` hors énumération). Corrigé
en remplaçant `"format": "json"` par un schéma JSON strict (`type/properties/enum/required`)
dans la requête `/api/generate`, qui force un décodage contraint côté Ollama — les deux appels
suivants ont produit une sortie strictement conforme.

## Correctifs post-campagne (2026-08-26)
La première campagne (`results/llm_vs_automate_v1/`) a révélé un écart de survie marqué
(automate 65%, llm_mock 45%, llm 20%) et deux non-conformités aux actions officielles de la
Phase 7, corrigées avant toute nouvelle interprétation :

1. **Logging prompt/réponse absent** (action 4 de la roadmap : "logger prompt/réponse... avec
   identifiant de modèle, paramètres et latence"). Seuls le modèle, la latence et le résultat
   interprété étaient loggés. `LLMDecider` stocke désormais `_last_prompt`/`_last_raw_response`
   et les inclut dans `llm_decision` et `llm_decider_erreur` — traçabilité complète, sans
   secret (Ollama local, aucune clé transmise).
2. **Espace d'action non équivalent à la référence** (action 3 : "action limitée au même
   espace d'actions que la référence"). L'automate vise la position exacte du roncier
   mémorisé (`memory_direction`) ; le LLM ne pouvait choisir qu'une direction cardinale parmi
   8, un handicap structurel qui confondait "le LLM décide moins bien" et "le LLM vise moins
   précisément". Correctif : quand l'intention retenue est `manger` et qu'un roncier est
   mémorisé, `_apply_success` utilise `memory_direction` (identique à l'automate) au lieu de
   la direction cardinale annoncée par le modèle — le LLM choisit l'intention, le moteur
   calcule la géométrie, exactement comme le fait `BaselineDecider`. Les intentions
   `suivre`/`eviter` restent sur direction cardinale (non corrigées : aucune occurrence dans
   la campagne, `social_radius` non activé dans `llm_vs_automate_v1.json`) — limitation
   documentée, à traiter si une campagne active un jour le volet social avec un décideur LLM.

Validé : déplacement réel divergent de la direction cardinale annoncée par le modèle lors
d'une décision `manger` avec roncier mémorisé (mouvement vers le roncier, pas vers "N" comme
annoncé) — confirme que `memory_direction` est bien appliqué.

## Campagne relancée après correctifs — effondrement de gemma3:4b puis changement de modèle
Première relance (toujours `gemma3:4b`) : résultats *dégradés* par rapport à la campagne
initiale (survie 20% → 15%, `mean_memorized_ronces` tombé à 0.0 sur les 20 enregistrements
`llm`). Investigation : sur les 5 seeds, le modèle répond quasi systématiquement
`("manger", "E")` (228/228, 227/228, etc.), indépendamment de la faim ou de la mémoire
réelles — effondrement du modèle sur une réponse fixe, pas un bug du correctif (le correctif
lui-même reste prouvé correct par ailleurs). Conséquence : les agents marchent droit vers
l'est jusqu'au mur de la carte et ne découvrent jamais de roncier.

Décision : remplacer `llm_model` par défaut de `experiments/llm_vs_automate_v1.json` par
`gemma3:1b` (validé empiriquement plus tôt dans la session : réponses variées, schéma
respecté, latence ~1 s). Le choix n'est pas motivé par une supériorité générale des petits
modèles, seulement par l'absence d'effondrement observée avec celui-ci sur ce prompt précis —
si `gemma3:1b` déçoit à son tour, le vrai correctif durable sera un prompt few-shot, pas un
nouveau changement de modèle à l'aveugle.

**Résultats finaux (`gemma3:1b`, `results/llm_vs_automate_v1/`, 5 seeds × 3 déciders) :**

| Décideur | Survie | Distance moy. | Mûres mangées | Ronciers mémorisés |
|---|---|---|---|---|
| automate | 65% | 373.9 | 1.5 | 0.45 |
| llm_mock | 40% | 385.5 | 1.1 | 0.3 |
| llm (gemma3:1b) | 40% | 188.8 | 1.25 | 0.4 |

Taux d'erreur LLM 0.35%, latence moyenne 1409 ms. Le décideur LLM égale désormais le taux de
survie du mock et reste net en dessous de l'automate mais dans un ordre de grandeur cohérent
(contre un effondrement quasi total avec `gemma3:4b`) — résultat jugé exploitable comme
première mesure de référence, pas comme conclusion définitive sur la capacité d'un LLM local
à ce jeu.

## Commentaire
2026-08-26 (session suivante) : écart trouvé lors d'un contrôle manuel de l'Inspecteur — le
défaut `llm_model` du registre (`scripts/variable_registry.gd`) était resté codé en dur sur
`gemma3:4b` (modèle écarté pour effondrement), alors que seule la configuration
`experiments/llm_vs_automate_v1.json` avait été alignée sur `gemma3:1b`. Tout agent
`decider_type=llm` sans override explicite aurait donc utilisé le modèle écarté par défaut.
Corrigé (défaut passé à `gemma3:1b`).
