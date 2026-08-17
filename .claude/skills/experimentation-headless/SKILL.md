---
name: experimentation-headless
description: Lance une ou plusieurs parties IA_Life en arrière-plan (sans fenêtre) avec des variables de simulation modifiées, pour tester une hypothèse ou un réglage demandé par l'utilisateur, puis analyse les logs produits. À utiliser quand l'utilisateur demande de tester/comparer des réglages, de lancer plusieurs parties automatiquement, de vérifier l'effet d'un changement de variable sur la simulation, ou d'itérer sur un paramètre jusqu'à obtenir un comportement donné.
tools: Read, Glob, Bash, Edit
---

# Expérimentation headless IA_Life

## Principe
Cette skill fait tourner le jeu sans fenêtre (`godot.exe --headless`) via `run_headless.py`, avec
des réglages injectés par un fichier JSON (variable d'environnement `IA_LIFE_HEADLESS_CONFIG`,
lue par `scripts/main.gd::_load_headless_overrides()`). Chaque run produit un fichier dans
`logs/session_*.log`, identique au format d'une partie jouée normalement.

**Elle ne modifie jamais les valeurs par défaut dans le code** (`scripts/game_config.gd`,
`scripts/character.gd`) — les overrides ne vivent que dans le JSON passé à un run donné. Si une
expérimentation confirme qu'un changement doit devenir la nouvelle valeur par défaut, le proposer
explicitement à l'utilisateur et l'appliquer comme une modification de code normale (avec entrée
dans `_docs/decisions/`), pas silencieusement dans le cadre de cette skill.

## Format des overrides
Dictionnaire JSON, toutes les clés optionnelles :
```json
{
  "game_config": { "ronce_count": 40, "pickup_hunger_threshold": 95 },
  "game_speed": 5.0,
  "character_defaults": { "hunger_depletion_rate": 0.4, "move_speed": 3.0 },
  "quit_on_all_dead": true,
  "max_wall_seconds": 120
}
```
- `game_config` : n'importe quel champ de `scripts/game_config.gd` (lire ce fichier pour la liste
  actuelle à jour — ne jamais supposer, les champs évoluent).
- `game_speed` : valeur initiale de `GameSpeed.time_scale` pour tout le run. **Rester à x80 maximum**
  (voir "Limites connues" — au-delà, risque de tunneling physique qui fait perdre des données de
  cueillette).
- `character_defaults` : appliqué à CHAQUE personnage au spawn via `character.set(clé, valeur)` —
  n'importe quel `@export var` de `scripts/character.gd` (`hunger_depletion_rate`, `move_speed`,
  `aging_factor`, `feeding_capacity`, `map_half_x`/`map_half_z`...).
- `quit_on_all_dead` (def. `true`) : arrête le process dès que les 4 personnages sont morts.
- `max_wall_seconds` (def. `120`) : garde-fou — arrêt forcé après N secondes réelles même si tous
  ne sont pas morts (utile si un override empêche la mort, ex. `hunger_depletion_rate: 0`).

## Procédure

1. **Clarifier l'hypothèse** : quelle variable l'utilisateur veut tester, et quel résultat serait
   "intéressant" (temps de survie, mûres mangées, tel comportement précis). Si la demande ne
   précise pas de valeur/plage, proposer une valeur raisonnable plutôt que de bloquer, mais le dire
   explicitement dans la réponse finale.

2. **Lire l'état actuel des mécaniques** avant de construire les overrides — `scripts/game_config.gd`
   et `scripts/character.gd` — pour connaître les valeurs par défaut en vigueur et les noms de
   champs exacts.

3. **Construire le JSON d'overrides** correspondant à la demande. Ne définir que les clés qui
   changent réellement par rapport au défaut (pas besoin de tout lister).

4. **Lancer le(s) run(s)** :
   ```bash
   python run_headless.py '{"game_config": {"ronce_count": 40}}'
   ```
   - Une seule partie suffit pour une vérification ponctuelle.
   - Pour une question statistique ("est-ce que X change vraiment la survie moyenne ?"), lancer
     plusieurs runs (3 à 5) avec le même override et comparer, car chaque partie a une composante
     aléatoire (spawn de ronces, marche aléatoire des personnages).
   - Pour une comparaison A/B, lancer le même nombre de runs avec et sans l'override, en gardant
     tout le reste identique.
   - Chaque run est bloquant (le script attend la fin) : les lancer séquentiellement, pas en
     parallèle (un seul process Godot headless à la fois pour ne pas mélanger les logs).

5. **Identifier les logs produits** : `Glob logs/*.log`, prendre les fichiers les plus récents
   (un par run lancé à l'étape 4 — noter les horodatages avant/après pour ne pas confondre avec
   d'anciennes sessions).

6. **Analyser chaque log** en réutilisant la méthode de la skill `analyse-partie` (parsing des
   lignes `[XX.Xs][catégorie] message`, chronologie par personnage, corrélation avec les
   `[config]`/`[headless]`, calcul des métriques de survie et de cueillette/repas).

7. **Agréger si plusieurs runs** : moyenne/écart du temps de survie, du nombre de mûres
   ramassées/mangées, taux de survie, causes de mort dominantes — pour donner une réponse
   statistiquement honnête plutôt qu'un seul run anecdotique.

8. **Restituer** : hypothèse testée, réglages utilisés, résultat observé (chiffré), interprétation,
   et une recommandation concrète si pertinent (valeur à adopter par défaut, ou nouvelle
   expérimentation à lancer). Proposer explicitement d'itérer (autre valeur, autre variable) plutôt
   que de considérer la question close après un seul passage.

9. **Notifier la fin de la campagne** : une fois TOUS les runs lancés à l'étape 4 terminés (pas après
   chaque run individuel), afficher un overlay plein écran de 2 secondes avant de restituer l'analyse :
   ```powershell
   powershell -File ".claude/skills/experimentation-headless/scripts/notify_overlay.ps1" -Message "IA_Life : J'ai fini"
   ```
   - Ne déclencher cette notification que pour une campagne lancée en arrière-plan (`run_in_background`)
     dont l'utilisateur n'observe pas activement le déroulement — pas pour un run ponctuel synchrone où
     la réponse arrive de toute façon immédiatement après.
   - Le message peut être adapté au contexte (ex: `"IA_Life : campagne ronce_count terminée"`) tant que
     le préfixe `IA_Life :` est conservé.

## Limites connues
- Un seul run headless à la fois (pas de parallélisation) : `run_headless.py` bloque jusqu'à la fin
  du process Godot ou jusqu'au timeout Python (150s par défaut, distinct de `max_wall_seconds` côté
  jeu qui doit toujours lui être inférieur).
- Le fichier de config temporaire (`%TEMP%/ia_life_headless_config.json`) est écrasé à chaque run —
  ne pas compter dessus pour retrouver les réglages d'un run passé : le log lui-même contient déjà
  la ligne `[headless] Overrides appliqués ...` avec le JSON utilisé, c'est la source de vérité.
- Si Godot n'est pas trouvé (`D:/Godot/godot.exe`), `run_headless.py` échoue immédiatement — vérifier
  avant de lancer une série de runs.
- **Plafond de vitesse ≈ x80-x96 (tunneling)** : `move_speed` par défaut (2.5) et le rayon de
  collision des ronces (2.0, diamètre 4.0) donnent un seuil théorique de tunneling à
  `4.0 / (move_speed × delta_physique)` ≈ x96 (physique à 60Hz) — au-delà, un personnage peut
  traverser une ronce en un seul tick sans être détecté par l'`Area3D`, faussant les données de
  cueillette. Confirmé empiriquement à x300 (taux de "0 mûre" et volume de cueillette nettement
  dégradés vs x50-x200). Rester à x80 maximum pour une campagne fiable ; si `move_speed` ou le
  rayon des ronces changent, recalculer ce seuil avant de relancer une campagne à haute vitesse.
- **Collision de nom de fichier de log** : `GameLogger` nommait les fichiers à la seconde près
  (`session_AAAA-MM-JJ_HH-MM-SS.log`). À très haute vitesse, deux process headless lancés dans la
  même seconde pouvaient s'écraser mutuellement (3 runs perdus ainsi lors du diagnostic du
  2026-08-17). Corrigé en ajoutant le PID du process au nom de fichier
  (`session_..._pidNNNN.log`) — toujours vérifier que le nombre de logs produits correspond au
  nombre de runs lancés avant d'agréger des résultats.
