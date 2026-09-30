# Roadmap — Survie pilotée par LLM

Créée le : 2026-09-30
Statut : **[EN COURS — Phase 0]**

## Objectif

Les quatre personnages autonomes (Rouge, Bleu, Vert, Jaune) sont pilotés chacun par un LLM local
(`gemma3:1b` via Ollama) qui décide de leurs déplacements et de leurs actions (ramasser, manger).
But : que les personnages vivent le plus longtemps possible. Le personnage « Test » (centre, piloté
par le développeur) n'est pas modifié.

L'axe apprentissage par renforcement (T0-T3) est en pause pendant cette roadmap.

## Périmètre verrouillé

| Sujet | Décision |
|---|---|
| Agents LLM | Rouge, Bleu, Vert, Jaune ; « Test » inchangé et jamais bloqué |
| Déplacement | Le LLM choisit une cible (identifiant de roncier) ; le moteur calcule la trajectoire |
| Exploration | Le LLM choisit une direction parmi 8 ; affinage reporté |
| Ramasser | Action explicite du LLM, possible à tout moment si contact et inventaire < 3 ; plus de cueillette automatique |
| Manger | Action explicite du LLM, refusée si faim > `eat_hunger_threshold` (valeur actuelle conservée) ; plus de repas automatique |
| Transport | 3 mûres max (`max_berries_carried`) |
| Mémoire | Coordonnées de chaque roncier vu ou touché ; capacité illimitée ; aucun oubli |
| Connaissance des mûres | Estimation : nombre observé à la dernière vue, décrémenté de ses propres cueillettes ; peut être périmée si un autre agent a cueilli ; corrigée à la vue suivante |
| Monde | Pas de repousse ; zones dangereuses désactivées (`danger_zone_count = 0`) |
| Temps | Pas de pause : pendant l'attente d'une réponse, l'agent poursuit son action en cours ; la simulation (faim, autres agents, « Test ») continue |
| Mesure | `game_speed = 1.0`, un run à la fois (`--jobs 1`) ; résultats dépendants du matériel, assumé et documenté |
| Modèle | `gemma3:1b` |
| Hors périmètre | Communication entre agents, repousse, danger, apprentissage |

## Choix techniques retenus

- **Nouveau décideur** distinct de `LLMDecider` (conservé pour les campagnes historiques), nouveau
  `decider_type` dédié. Les automatismes de cueillette et de repas ne sont désactivés que pour ce
  décideur ; `automate` reste strictement inchangé.
- **Déclenchement des tours** : sur événement (cible atteinte, cible devenue invalide, nouveau
  roncier vu, franchissement du seuil de repas, blocage, action terminée), avec un intervalle
  maximal de sécurité en temps simulé.
- **Décision asynchrone sans pause** : une seule requête en vol par agent ; l'agent poursuit son
  action en cours jusqu'à la réponse (arrêt sur place si l'action est terminée). La latence est un
  coût de survie réel, journalisé par agent (temps d'attente simulé, faim perdue en attente).
- **Vitesse de faim** : `hunger_depletion_rate` reste à sa valeur actuelle ; ajustement éventuel en
  Phase 4 sur la base de la latence et de la faim perdue en attente mesurées.
- **Vocabulaire fermé** par schéma JSON Ollama : `aller_vers(roncier_id)`, `explorer(direction)`,
  `ramasser`, `manger`, `attendre`. Toute action invalide est refusée par le moteur et journalisée ;
  repli défini en Phase 0.
- **Reproductibilité** : options Ollama `temperature = 0` et `seed` fixées, mais un run n'est pas
  rejouable (l'instant d'arrivée de la réponse varie). Les tests de reproductibilité se font avec
  le décideur mock uniquement.

## Risques et parades

- **Stock fini** (24 ronciers × 3 mûres = 72 mûres, 6 mûres pour une vie complète) : la durée de
  vie est plafonnée par la carte. Parade : critère comparatif à l'automate sur les mêmes cartes.
- **`gemma3:1b` faible en raisonnement spatial** : parade par cibles nommées avec distance
  précalculée, jamais de coordonnées brutes à interpréter.
- **Effondrement sur une réponse fixe** (déjà observé avec `gemma3:4b`) : parade par journalisation
  de la distribution des actions et, si besoin, prompt few-shot.
- **Latence = coût de survie dépendant du matériel** : la réponse arrive en temps réel, la faim
  baisse en temps simulé. `game_speed` > 1 ou des runs parallèles faussent la survie. Parade :
  mesure à x1 et `--jobs 1`, télémétrie d'attente par agent.
- **Comparaison inéquitable avec l'automate** (décision instantanée) : écart documenté dans le
  rapport de Phase 5, faim perdue en attente reportée à côté de la survie.
- **Ollama indisponible** : repli journalisé, jamais de blocage de run.

## Phases

### Phase 0 — Contrat [EN COURS]

- Spécifier le schéma d'action, les règles de validation moteur, le repli, les événements de
  déclenchement et l'intervalle maximal.
- Spécifier les événements de journalisation (`llm_turn`, action refusée, début/fin d'attente).
- Créer la configuration `experiments/llm_survie_v1.json` (4 agents LLM, danger à 0, mémoire
  illimitée sans oubli).

**Gate** : contrat écrit dans `experiments/llm_survie_contrat_v1.md` ; config validée par
`VariableRegistry` ; runs `automate` existants inchangés.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 1 — Mémoire par coordonnées et estimation des mûres [TODO]

- Mémoire indexée par identifiant stable de roncier : coordonnées, mûres estimées, date de dernière
  observation. Alimentée par la vision et par le contact.
- Suppression de la lecture omnisciente de `ronce.berries` pour ce décideur.
- Exposer le nombre de mûres visibles dans l'état de perception du roncier.

**Gate** : tests verts — mémorisation à la vue, au contact, décompte après cueillette propre,
estimation périmée puis corrigée à la vue suivante, aucun oubli sur un run long.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 2 — Actions explicites et navigation vers cible [TODO]

- Actions `aller_vers`, `explorer`, `ramasser`, `manger`, `attendre` exécutées par le moteur.
- Désactivation de la cueillette et du repas automatiques pour ce décideur uniquement.
- Détection d'arrivée, de blocage et de cible vide.
- Décideur mock scripté pour tester sans Ollama.

**Gate** : tests verts avec le mock — séquence complète aller/ramasser/manger, refus de manger
au-dessus du seuil, refus de ramasser à 3 mûres ou hors contact ; `automate` inchangé.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 3 — Décision asynchrone et déclenchement [TODO]

- Une requête en vol par agent ; poursuite de l'action en cours pendant l'attente.
- Déclenchement des décisions sur événement et intervalle maximal ; événement survenu pendant une
  attente mis en file pour la décision suivante.
- Télémétrie d'attente par agent : nombre de décisions, temps d'attente simulé, faim perdue en
  attente.

**Gate** : tests verts avec un mock à latence simulée — l'action en cours continue pendant
l'attente, aucune décision manquée ni doublée, télémétrie d'attente cohérente ; deux runs mock
sans latence au même seed identiques.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 4 — Prompt et intégration `gemma3:1b` [TODO]

- Prompt : faim, mûres portées, seuil de repas, ronciers connus (id, distance, direction, mûres
  estimées), ronciers visibles, dernière action et son résultat.
- Options déterministes, journalisation prompt/réponse/latence, distribution des actions.
- Démonstration fenêtrée sur le bureau virtuel IA_Life.

**Gate** : run réel headless complet sans blocage, taux d'erreur mesuré, aucune réponse figée ;
démonstration fenêtrée ajoutée à `tests_manuels.md`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

### Phase 5 — Mesure de survie [TODO]

- Critère de succès à définir avec l'utilisateur et à écrire avant toute mesure.
- Comparaison appariée à l'automate sur les mêmes cartes, à `game_speed = 1.0` et `--jobs 1`.
- Rapport : survie, durée de vie, mûres mangées, faim perdue en attente, latence moyenne, matériel.

**Gate** : à définir en ouverture de phase.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
