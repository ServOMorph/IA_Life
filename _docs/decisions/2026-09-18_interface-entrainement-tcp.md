# Interface d'entraînement T1 — bridge TCP/JSONL local

Date : 2026-09-18. Statut : adopté pour la Phase 3 de la roadmap d'apprentissage fonctionnel.

## Décision

Le transport du nouvel environnement d'entraînement est le bridge TCP/JSONL local. Il expose
un adaptateur Python Gymnasium ; Godot reste l'autorité du reset, de la physique, des contacts,
de la cueillette et de la consommation. Le chemin T0 tabulaire direct reste disponible comme
contrôle de référence et ne dépend pas de ce transport.

## Motifs

Le projet tourne avec Godot `4.5.stable` en renderer Forward+ et possède déjà un bridge TCP local.
Godot RL Agents propose un wrapper Stable-Baselines3, mais sa documentation demande l'éditeur
Godot .NET pour l'entraînement interactif et son tutoriel de custom environment cible encore
Godot 4.0. Son intégration exigerait un add-on tiers et un smoke test d'un environnement distinct,
alors que le bridge local peut porter exactement le contrat T1 sans nouvelle dépendance.

Gymnasium impose que `step()` renvoie observation, récompense, `terminated`, `truncated` et
`info`, puis que tout épisode clos soit suivi de `reset()`. L'adaptateur vérifiera ce contrat avec
`stable_baselines3.common.env_checker.check_env` quand Stable-Baselines3 est disponible.

## Exigences du protocole

- connexion limitée à `127.0.0.1`, port explicite et délai d'attente côté client ;
- commandes `reset`, `step` et `close` avec identifiants d'épisode et de pas ;
- refus d'un pas avant reset, après fin, ou portant un identifiant périmé ;
- un reset reconstruit les stocks, positions, collisions, compteurs et RNG depuis sa seed ;
- l'action est maintenue durant un nombre fixé de ticks physiques ; aucune mutation ne survient
  pendant l'attente d'une action ;
- le dernier tick est traité avant la réponse ; réussite et mort sont `terminated`, horizon
  externe est `truncated` ;
- les erreurs de transport ou de moteur sont invalides et ne deviennent jamais une troncature.

## Portée

Cette décision ne valide ni Godot RL Agents ni PPO. Une migration future vers Godot RL Agents
nécessite un smoke test versionné, sans modifier les résultats ni les seeds T1 déjà réservés.

## Sources

- [Gymnasium — Env](https://gymnasium.farama.org/api/env/) : contrat `reset`/`step`, séparation
  `terminated`/`truncated`.
- [Stable-Baselines3 — Environment Checker](https://stable-baselines3.readthedocs.io/en/master/common/env_checker.html) : contrôle de conformité Gymnasium.
- [Godot RL Agents — README](https://github.com/edbeeching/godot_rl_agents) : wrapper SB3 et
  prérequis .NET pour l'entraînement interactif.
