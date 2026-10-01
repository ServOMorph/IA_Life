# Contrat — survie pilotée par LLM (v1)

Roadmap : `roadmap_survie_llm.md`. Décision : `_docs/decisions/2026-09-30_survie-pilotee-par-llm.md`.
Configuration : `experiments/llm_survie_v1.json`. Décideur : `decider_type = "llm_survie"`.

Ce contrat est gelé à la fin de la Phase 0. Toute modification ultérieure passe par une version v2.

## 1. Périmètre

- Agents concernés : Rouge, Bleu, Vert, Jaune. « Test » (manuel) n'est jamais configuré et n'est jamais bloqué.
- Le LLM décide des déplacements (cible ou direction) et des actions ramasser/manger. Le moteur
  calcule les trajectoires, applique les règles et journalise.
- Hors périmètre : communication entre agents, repousse, danger, apprentissage.
- `automate` et les autres décideurs restent strictement inchangés : `llm_survie` n'ajoute qu'une valeur
  à l'énumération `decider_type` et n'active aucun nouveau comportement pour les autres valeurs.
- Tant que la Phase 4 n'est pas livrée, `llm_survie` utilise le décideur mock (aucune décision,
  l'agent reste à l'arrêt) : un run avec cette valeur n'est alors pas une mesure.

## 2. Vocabulaire d'actions

Réponse JSON imposée par le schéma Ollama (`format`), trois champs obligatoires :

| Champ | Type | Valeurs |
|---|---|---|
| `action` | enum | `aller_vers`, `explorer`, `ramasser`, `manger`, `attendre` |
| `roncier_id` | enum | identifiants des ronciers en mémoire (`R01`..`R24`) + `aucun`, construit à chaque requête |
| `direction` | enum | `N`, `NE`, `E`, `SE`, `S`, `SO`, `O`, `NO`, `aucune` |

Un champ non pertinent pour l'action vaut `aucun` / `aucune` ; sa valeur est alors ignorée.

Identifiant de roncier : `R%02d`, indice de création du roncier dans `main.gd` (déterministe pour une
seed). Défini et exposé en Phase 1 ; jamais de coordonnées brutes dans le prompt ni dans la réponse.

## 3. Validation par le moteur

Le schéma garantit la forme, pas la légalité. Le moteur valide chaque action au moment de son
application (état courant, pas l'état du prompt). Une action refusée n'a aucun effet, est journalisée
et déclenche un tour de décision.

| Action | Condition d'acceptation | Code de refus |
|---|---|---|
| `aller_vers(id)` | `id` en mémoire de l'agent | `cible_inconnue` |
| | mûres estimées de `id` > 0 | `cible_epuisee` |
| `explorer(direction)` | `direction` ≠ `aucune` | `direction_invalide` |
| `ramasser` | agent en contact avec un roncier | `hors_contact` |
| | mûres portées < `max_berries_carried` | `inventaire_plein` |
| | le roncier au contact a encore des mûres | `roncier_vide` |
| `manger` | mûres portées > 0 | `aucune_mure` |
| | faim ≤ `eat_hunger_threshold` | `trop_rassasie` |
| `attendre` | toujours acceptée | — |
| autre nom | jamais (garde-fou hors schéma) | `action_inconnue` |

Règles d'exécution :

- `ramasser` prend une mûre par action ; `pickup_hunger_threshold` est ignoré pour ce décideur.
- `manger` consomme une mûre par action, avec le gain de faim existant (`pv_per_berry`).
- `ramasser` et `manger` sont instantanés ; leur exécution est un événement « action terminée ».
- `aller_vers` : marche en ligne vers le roncier ; terminée à l'arrivée au contact (événement
  « cible atteinte »). `explorer` : marche selon la direction jusqu'au prochain tour. `attendre` :
  immobile jusqu'au prochain tour.
- `ramasser` et `manger` n'interrompent pas l'action de déplacement en cours.
- Arrivée à moins de 1 m de la position mémorisée d'une cible sans contact (roncier absent) : la
  cible est estimée vide (événement `cible_invalide`).
- Un tour ne peut pas enchaîner deux actions : une seule action par réponse.
- Quand l'action de déplacement en cours se termine sans nouvelle réponse, l'agent s'arrête sur place.
- La cueillette et le repas automatiques sont désactivés pour ce décideur uniquement.

## 4. Repli

Le repli ne passe jamais par l'automate (il fausserait la comparaison de Phase 5).

Cas de repli : timeout, connexion refusée, code HTTP ≠ 200, JSON illisible, champ manquant, valeur
hors énumération.

Comportement : l'agent poursuit l'action en cours ; s'il n'en a pas (ou si elle est terminée), il
s'arrête sur place (`attendre`). Le repli est compté et journalisé (`llm_survie_repli`). Après un
repli, la requête suivante n'est déclenchée qu'au plus tôt à l'échéance de l'intervalle maximal (pas
de martèlement d'Ollama indisponible). Le run n'est jamais bloqué ni interrompu.

Une action légale au format mais refusée par le moteur (section 3) n'est pas un repli : c'est un
refus, compté à part.

## 5. Déclencheurs de tour

Un tour = une requête au LLM. Une seule requête en vol par agent. Événements déclencheurs :

| Événement | Définition |
|---|---|
| `demarrage` | premier tour, à l'apparition de l'agent |
| `cible_atteinte` | contact avec la cible d'un `aller_vers` |
| `cible_invalide` | la cible passe à 0 mûre estimée (vue vide, contact vide) |
| `nouveau_roncier` | roncier jamais mémorisé vu ou touché |
| `seuil_repas` | la faim franchit `eat_hunger_threshold` vers le bas |
| `blocage` | déplacement horizontal < 0,5 m sur 3 s simulées pendant une action de mouvement |
| `action_terminee` | exécution de `ramasser` ou `manger` |
| `refus` | action refusée par le moteur |
| `intervalle_max` | `llm_decision_interval_seconds` (10 s simulées) écoulées depuis le dernier tour |

Les valeurs 0,5 m et 3 s sont des paramètres initiaux, à recalibrer en Phase 2 sur des cas de blocage
observés.

Événement survenu pendant une requête en vol : mis en file (dédoublonné par type et cible). Dès la
réponse appliquée, si la file n'est pas vide, une nouvelle requête part au tick suivant avec l'état à
jour ; la file est alors vidée. Aucun événement n'est perdu ni traité deux fois.

## 6. Décision asynchrone sans pause

- La simulation n'est jamais suspendue : la faim baisse, les autres agents et « Test » continuent.
- Pendant la requête, l'agent poursuit son action en cours (section 3, règles d'exécution).
- Réponse appliquée au tick suivant sa réception ; validation sur l'état courant.
- La latence est un coût de survie : télémétrie par agent (section 7).
- Mesure à `game_speed = 1.0` et `--jobs 1` ; avec un autre réglage, le temps réel de réponse ne
  correspond plus au temps simulé. Résultats dépendants du matériel, assumé.

## 7. Journalisation

Événements structurés (JSONL, catégorie = nom) :

| Événement | Champs |
|---|---|
| `llm_survie_tour` | `agent`, `tour_id`, `declencheurs`, `prompt`, `raw_response`, `action`, `roncier_id`, `direction`, `latence_ms`, `attente_sim_s`, `faim_perdue_attente` |
| `llm_survie_attente_debut` | `agent`, `tour_id`, `t_sim`, `faim`, `action_en_cours` |
| `llm_survie_attente_fin` | `agent`, `tour_id`, `t_sim`, `faim`, `attente_sim_s`, `faim_perdue_attente` |
| `llm_survie_refus` | `agent`, `tour_id`, `action`, `code`, `etat` (faim, portées, cible) |
| `llm_survie_repli` | `agent`, `tour_id`, `raison`, `detail`, `action_repli` |
| `llm_survie_action` | `agent`, `tour_id`, `action`, `issue` (`arrivee`, `blocage`, `ramasse`, `mange`, `interrompue`) |

Résumé par agent (`*.summary.json`, ajouté en Phase 3) : `llm_survie_tours`, `llm_survie_refus`,
`llm_survie_replis`, `llm_survie_latence_moyenne_ms`, `llm_survie_attente_sim_totale_s`,
`llm_survie_faim_perdue_attente`, `llm_survie_distribution_actions`.

`attente_sim_s` est mesuré en temps simulé ; `latence_ms` en temps réel. `faim_perdue_attente` est la
faim perdue entre l'envoi de la requête et l'application de la réponse.

## 8. Options Ollama

`temperature = 0`, `seed = decider_seed + hash(nom de l'agent)` ramené à un entier positif,
`num_predict` borné (64). Un run n'est pas rejouable (l'instant d'arrivée de la réponse varie) ;
la reproductibilité se teste avec le décideur mock uniquement.

## 9. Configuration `llm_survie_v1.json`

| Élément | Valeur | Justification |
|---|---|---|
| `agents.individual` | Rouge, Bleu, Vert, Jaune | « Test » non configuré |
| `decider_type` | `llm_survie` | nouveau décideur |
| `llm_model` | `gemma3:1b` | modèle verrouillé |
| `llm_decision_interval_seconds` | 10,0 | intervalle maximal de sécurité (temps simulé) |
| `llm_timeout_seconds` | 20,0 | au-delà, repli |
| `memory_capacity` | 100 | borne du registre, supérieure aux 24 ronciers : mémoire illimitée en pratique |
| `memory_decay_rate` | 0,0 | aucun oubli |
| `vision_range` | 25,0 | vision omnidirectionnelle à 25 m (valeur des démonstrations existantes) ; la valeur par défaut du registre (0) rend les agents aveugles |
| `danger_zone_count` | 0 | danger désactivé |
| `ronce_count` / `berries_per_ronce` | 24 / 3 | carte de référence, aucune repousse (aucune variable de repousse n'existe) |
| `game_speed` | 1,0 | mesure à l'échelle réelle |
| `max_simulation_seconds` | 1200 | borne haute, `quit_on_all_dead` actif |
| `seed` | 1337 | placement de carte |

Seuils conservés à leur valeur actuelle : `eat_hunger_threshold` 50, `max_berries_carried` 3,
`hunger_depletion_rate` 0,6 (réévaluation éventuelle en Phase 4).

## 10. Points ouverts pour les phases suivantes

- Seuils de blocage (0,5 m / 3 s) : à calibrer en Phase 2.
- Format exact du prompt et valeur de `num_predict` : Phase 4.
- Critère de succès : défini à l'ouverture de la Phase 5, avant toute mesure.
