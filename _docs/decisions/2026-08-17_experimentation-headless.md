# Mode headless + skills d'analyse/expérimentation

**Date :** 2026-08-17
**Statut :** proposé

## Décision
Le jeu peut désormais tourner sans fenêtre (`godot.exe --headless`) avec des variables de
simulation injectées via un fichier JSON, pour permettre des campagnes de tests automatisées
sans intervention manuelle sur l'UI. Deux skills accompagnent ce dispositif :
- `analyse-partie` : parse un log de session et en tire une analyse structurée par personnage.
- `experimentation-headless` : construit des overrides à partir d'une demande utilisateur, lance
  un ou plusieurs runs headless, puis réutilise `analyse-partie` pour interpréter les résultats.

## Implémentation
- `scripts/main.gd` : `_load_headless_overrides()` lit `IA_LIFE_HEADLESS_CONFIG` (variable
  d'environnement pointant vers un JSON), applique `game_config`/`game_speed`/`character_defaults`,
  et gère l'arrêt automatique (`quit_on_all_dead`, `max_wall_seconds`).
- `scripts/game_config.gd` : `apply_overrides(values: Dictionary)` générique (via `set()`).
- `run_headless.py` (nouveau) : lance Godot headless avec un override JSON passé en argument,
  timeout Python de sécurité (150s par défaut).
- `.claude/skills/analyse-partie/SKILL.md` et `.claude/skills/experimentation-headless/SKILL.md`
  (nouveaux).

## Plafond de vitesse et correction du nommage des logs (2026-08-17)
Campagne diagnostique (6 paliers, 60 runs) : au-delà d'environ x96 (formule
`4.0 / (move_speed × delta_physique)`), risque de tunneling physique — un personnage peut
traverser une ronce en un seul tick sans déclencher l'`Area3D` de détection. Dégradation
confirmée empiriquement à x300. Plafond recommandé fixé à x80, documenté dans
`.claude/skills/experimentation-headless/SKILL.md`. En parallèle, `GameLogger` nommait les
logs à la seconde près, provoquant des écrasements entre runs headless rapprochés (3 runs
perdus lors du diagnostic) — corrigé par l'ajout du PID du process au nom de fichier.

## Campagne de validation mémoire + collision ronces (2026-08-17)
8 runs headless (x50, réglages par défaut) après ajout du système de mémoire et de la
collision physique des ronces : 4/4 morts sur chaque run, mûres ramassées = mûres mangées
à chaque fois (cohérent avec les seuils cueillette/consommation), ~92% des souvenirs
oubliés avant la mort (cohérent avec le taux de décroissance). Aucune anomalie détectée.

## Commentaire
(à compléter lors de la validation/invalidation)
