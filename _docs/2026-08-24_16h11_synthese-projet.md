# Synthèse projet — IA_Life

État des lieux généré le 2026-08-24. Document autonome : toutes les valeurs citées ont été
lues dans le code au moment de la rédaction.

## 1. Objectif

Environnement Godot contenant des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux par écrit (échanges logués), afin
d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de
jeu — et plus largement d'évaluer comment une modification du jeu (ex. ajout d'une source de
nourriture) modifie le comportement observé. Le projet est pensé pour évoluer fortement, sans
figer prématurément son architecture.

Stack : Godot 4.5 (GDScript), scène construite entièrement par code (aucune scène éditée dans
l'éditeur Godot). LLM externe non encore choisi/branché.

## 2. Carte et environnement

- Map carrée fermée, `MAP_SIZE = 160.0` (soit ±80 autour de l'origine).
- 4 murs (`WALL_HEIGHT = 3.0`, `WALL_THICKNESS = 1.0`), matériau triplanar brique
  (`brick_wall_001`, échelle de texture 0.5).
- Sol : mesh de terrain procédural (résolution `80×80`), matériau triplanar herbe
  (`leafy_grass`, échelle 0.25), collision par `HeightMapShape3D`.
- Relief : bruit simplex (`FastNoiseLite`, fréquence `0.045`), amplitude `5.0`, dérivé de la
  seed d'expérience. Aplani sur les 12 derniers mètres avant les murs
  (`TERRAIN_FLAT_MARGIN = 12.0`), aplani au centre dans un rayon de `45.0` m
  (`CENTER_FLAT_RADIUS`) et autour de chaque point de spawn dans un rayon de `20.0` m
  (`SPAWN_FLAT_RADIUS`). Une cuvette (`VALLEY_RADIUS = 20.0`, profondeur `3.5`) est en plus
  creusée sur chacun des 4 points de spawn.
- Décor procédural, dérivé de la seed d'expérience : 8 rochers (BoxMesh, échelle aléatoire
  0.5–1.1) et 6 arbres (tronc cylindrique + feuillage sphérique, échelle aléatoire 0.85–1.3),
  répartis aléatoirement sur la map (marge de 3 m avant les murs).

## 3. Objets présents sur la map

| Objet | Quantité / règle | Rôle |
|---|---|---|
| Sol (`StaticBody3D "Floor"`) | 1, mesh de terrain | Collision (HeightMapShape3D) + rendu |
| Murs (`StaticBody3D "Wall"`) | 4 | Collision (BoxShape3D) + rendu, bordent la map |
| Rochers (`StaticBody3D "Rock"`) | 8 | Décor + collision (BoxShape3D) |
| Arbres (`Node3D "Tree"`) | 6 | Décor ; seul le tronc a une collision (CylinderShape3D), le feuillage est purement visuel |
| Personnages normaux | 4 (Rouge, Bleu, Vert, Jaune) | Agents comportementaux, géométrie boîte |
| Personnage de test | 1, uniquement si `IA_LIFE_DEV_MODE=1` | Agent contrôlable manuellement, modèle riggé |
| Ronces (`Area3D "Ronce"`) | `GameConfig.ronce_count` (24 par défaut), répartis en 4 quadrants égaux (+ reste) | Détection de contact (SphereShape3D rayon 2.0) + collision physique solide dédiée (StaticBody3D "RonceCollision", cylindre rayon 1.0 hauteur 1.4) |
| Mûres | `GameConfig.berries_per_ronce` par ronce (3 par défaut), purement visuelles (petites sphères noires retirées une à une à la cueillette) | Représentation du stock de la ronce, pas d'objet logique séparé |

En mode dev, 4 ronces supplémentaires sont ajoutées à des offsets fixes autour du spawn du
personnage de test (`(±6, 0)`, `(0, ±6)`).

## 4. Personnages

Variables `@export` de `scripts/character.gd`, avec, si réglable en jeu, le libellé du
slider et sa plage (`scripts/ui_manager.gd`) :

| Variable | Défaut | Réglable en jeu | Rôle |
|---|---|---|---|
| `move_speed` | 2.5 | "Vitesse" (0.5–10.0) | Vitesse de déplacement |
| `map_half_x` / `map_half_z` | 18.0 (écrasé au spawn à ~79.1, quasi toute la map) | "Exploration" (5–80) | Demi-étendue de la zone où l'agent peut se déplacer |
| `gravity` | 9.8 | non | Gravité appliquée hors sol |
| `hunger` | 100.0 | non (forçable via touches dev H/G) | Niveau de faim courant (0–100) |
| `hunger_depletion_rate` | 0.6/s | non | Vitesse de déplétion de la faim |
| `aging_factor` | 1.0 | "Vieillissement" (0.1–5.0) | Multiplicateur de la déplétion de faim |
| `feeding_capacity` | 1.0 | "Capacité à se nourrir" (0.1–3.0) | Multiplicateur des PV gagnés par mûre mangée |
| `memory_capacity` | 5 | "Mémoire" (0–10) | Nombre de ronciers mémorisables simultanément |
| `memory_decay_rate` | 0.15 | non | Vitesse d'estompage d'un souvenir de roncier |
| `exploration_tendency` | 0.5 (neutre) | non (uniquement via config d'expérience) | Réduit linéairement l'intervalle entre réorientations d'errance |
| `social_radius` | 0.0 (perception désactivée) | non | Rayon de détection des autres agents |
| `follow_probability` | 0.0 | non | Probabilité d'adopter un comportement de suivi à la rencontre d'un autre agent |
| `avoid_probability` | 0.0 | non | Probabilité d'adopter un comportement d'évitement |
| `display_name`, `manual_control`, `immortal`, `rl_controlled` | — | non | Contrôle interne (perso de test / mode RL), pas de sliders |

**Cycle de vie** : naissance à l'un des 4 points de spawn (coins de la map), objectif initial
"errance". À chaque frame physique : la faim décroît (`hunger_depletion_rate * aging_factor`,
sauf si `immortal`, où elle est clampée à 1.0 minimum) ; si elle atteint 0, l'agent meurt
(`_die()`). Un contact avec une ronce déclenche une tentative de cueillette si la faim dépasse
`pickup_hunger_threshold` (défaut 90) et que l'inventaire n'est pas plein
(`max_berries_carried`, défaut 3) ; une mûre est mangée automatiquement dès que la faim
descend sous `eat_hunger_threshold` (défaut 50) et qu'il en reste en inventaire, avec un gain
de PV de `(100 / full_life_berries) * feeding_capacity`. Le personnage mémorise
l'emplacement des ronciers visités (mémoire à capacité limitée, la plus faible est oubliée en
premier) et s'y dirige en cas de faim si aucune ronce n'est visible. La perception sociale
(si `social_radius > 0`) détecte les agents proches, journalise les rencontres, et peut
déclencher un suivi ou un évitement selon les probabilités configurées.

**Animation** : les 4 agents normaux utilisent l'animation procédurale de la Phase 3 (bobbing
de marche, orientation vers la direction de déplacement, tween de mort). Le personnage de
test (mode dev uniquement) utilise le modèle riggé Blender (`assets/models/character.glb`,
animations Idle/Walk/Death via `AnimationPlayer`).

## 5. Ronces et mûres (`GameConfig`, persisté dans `logs/game_config.json`)

| Variable | Défaut | Slider ("Données du jeu") | Rôle |
|---|---|---|---|
| `max_berries_carried` | 3 | "Mûres max portées" (1–10) | Inventaire max de mûres transportées |
| `pickup_hunger_threshold` | 90.0 | "Seuil cueillette (faim)" (0–100) | Faim minimale pour déclencher une cueillette |
| `eat_hunger_threshold` | 50.0 | "Seuil consommation (faim)" (0–100) | Faim maximale pour déclencher une consommation |
| `full_life_berries` | 6.0 | "Mûres pour vie complète" (1–20) | Nombre de mûres nécessaires pour regagner 100 PV |
| `ronce_count` | 24 | "Nombre de ronces" (1–30, appliqué au prochain Relancer) | Nombre total de ronciers sur la map |
| `berries_per_ronce` | 3 | "Mûres par ronce" (1–10, appliqué au prochain Relancer) | Stock initial de mûres par roncier |
| `light_energy` | 3.0 | "Intensité lumineuse" (0–8) | Énergie de la lumière directionnelle |

Répartition : la map est divisée en 4 quadrants égaux, `ronce_count` réparti aussi
équitablement que possible entre eux (le reste de la division va aux premiers quadrants) ;
position aléatoire dans chaque quadrant.

## 6. Caméra et interface

**Modes de caméra** (`scripts/free_camera.gd`) :
- **Libre** (par défaut) : ZQSD + E/C (haut/bas) + souris, vitesse 10.0, ×3 avec Maj.
- **Suivi 3e personne** : offset `(0, 12, 8)`, zoom à la molette (0.3×–3.0×).
- **1re personne contrainte** : lacet limité à ±90°, tangage à ±63° relatif au corps du
  personnage.
- **Orbite** (personnage de test, mode dev uniquement) : distance 3–15 m (molette),
  hauteur de pivot 1.5 m, tangage clampé.
- Cycle par clic sur le nom d'un personnage : Libre/autre → Suivi → 1re personne → retour
  exact à la caméra précédente. Échap bascule capture/libération de la souris (la souris est
  capturée dès le lancement).

**Menu bas d'écran** : slider "Vitesse jeu" (0.1×–50×) à gauche, boutons de sélection des 4
personnages au centre, boutons "Données du jeu" / "Large" (reset vue) / "Relancer" à droite —
"Relancer" recharge la scène sans confirmation.

**Panneaux personnage** (un par coin) : nom coloré, libellé "DEAD" si mort, barre de faim,
section "Réglages" repliée par défaut (sliders individuels vitesse/exploration/
vieillissement/capacité à se nourrir/mémoire), section "Historique" dépliée par défaut
(mûres ramassées/mangées, ronciers mémorisés). Une section d'état (position, vitesse
courante, exploration, mûres portées) existe dans le code (`etat_content`) mais reste
toujours masquée : aucun bouton ne la révèle actuellement — code mort ou fonctionnalité
inachevée à clarifier.

**Modale "Données du jeu"** : expose tous les réglages `GameConfig` listés en section 5,
sauvegardés sur disque immédiatement (sauf nombre de ronces/mûres par ronce, appliqués au
prochain "Relancer").

**Mode dev** (`IA_LIFE_DEV_MODE=1`) : bandeau de rappel des raccourcis, panneau
"Personnage de test" (sliders capacité à se nourrir/mémoire dédiés + stats en direct),
checklist de tests manuels en jeu (touche T) générée depuis `tests_manuels.md` (vide
actuellement, donc aucune entrée à afficher).

## 7. UX / parcours utilisateur

Au lancement (`python run.py`) : vue caméra large fixe `(0, 60, 80)`, mode Libre. La souris
est **capturée dès le premier frame** — aucun indice visuel n'informe qu'il faut appuyer sur
Échap pour la libérer et pouvoir cliquer sur les boutons du menu bas ou des panneaux ; c'est
un point de friction pour une première prise en main. Les 4 panneaux personnages sont déjà
affichés dans les coins, section Historique dépliée, Réglages repliée.

Aucun tutoriel ni texte d'aide n'existe en dehors du mode dev (le bandeau de raccourcis
n'apparaît que si `IA_LIFE_DEV_MODE=1`). Les actions ne sont découvrables qu'en lisant le
code ou la documentation : déplacement caméra (ZQSD/E/C/souris/Maj), clic sur un nom de
personnage pour le cycle de vue à 3 clics, molette pour zoomer en vue Suivi/Orbite, boutons
"Données du jeu"/"Large"/"Relancer".

Retour visuel disponible : barre de faim qui descend en continu, bascule immédiate vers le
libellé "DEAD" à la mort (le contenu vivant du panneau disparaît), mûres retirées
visuellement du buisson une à une à chaque cueillette, compteurs "Mûres ramassées"/"Mûres
mangées" mis à jour dans la section Historique.

Points de friction identifiés en lisant le code : aucun message affiché en jeu si Godot ou
un asset (par ex. `character.glb`) est introuvable — l'échec ne se manifeste que dans les
logs ou par un comportement dégradé silencieux ; le bouton "Relancer" efface la partie en
cours sans confirmation ni avertissement ; les sliders des panneaux/modale n'affichent aucun
texte d'aide sur leur effet au premier lancement.

## 8. Simulation et outillage

- **Vitesse de simulation** : `GameSpeed.time_scale`, réglable en jeu de 0.1× à 50× ; en
  mode headless, fixée par `simulation.game_speed` de la configuration d'expérience.
- **Logging** (`GameLogger`) : un fichier texte lisible et un fichier `.jsonl` structuré par
  session (`schema_version` 1, horodaté, PID dans le nom). Catégories observées dans le code :
  `session`, `headless`, `rl`, `rl_bridge`, `dev`, `config`, `camera`, `spawn`, `objectif`,
  `decision`, `memoire`, `cueillette`, `repas`, `mort`, `position`, `zone`, `social`,
  `environment_event`, `experiment`, `summary`. Un `summary.json` est écrit en fin de run
  headless (statut, raison d'arrêt, configuration normalisée, événements exécutés, et par
  agent : paramètres, vivant/mort, objectif courant, faim, mûres ramassées/mangées/portées,
  ronciers mémorisés, réorientations d'errance, distance parcourue, zones visitées/
  découvertes/revisitées, rencontres sociales, durée de contact social, décisions de
  suivi/évitement, durée de vie).
- **Scripts de lancement** : `run.py` (jeu normal), `run_dev.py` (mode dev), `run_headless.py`
  (sans fenêtre, overrides JSON via `IA_LIFE_HEADLESS_CONFIG`, timeout configurable, révision
  git journalisée), `run_screenshot.py` (fenêtre réelle, capture PNG automatisée),
  `run_rl.py` (mode RL, créé le 2026-08-24 — absent jusqu'ici, ce qui empêchait le bridge
  RL de démarrer).
- **Outillage d'expérimentation** : `tools/run_campaign.py`, `tools/aggregate_results.py`,
  `tools/run_smoke_tests.py`, `tools/run_manual_checks.py` (ce dernier couvre désormais les
  anciens tests manuels 6, 8, 9, 10 et 11).
- **Bridge RL** (`scripts/rl_bridge.gd`, `rl/client_random.py`) : serveur TCP/JSONL local
  (port 11008), protocole synchrone `reset`/`step`/`close`, espace d'action Discrete(7), pas
  de simulation de 0.25 s. Validé le 2026-08-24 : épisode complet sans NaN, reward/terminated/
  truncated journalisés, comportement reproductible sur deux runs à seed identique (écart
  mineur observé sur la faim finale malgré des observations et actions identiques — non
  encore expliqué, à surveiller).
- **Skills projet** : `analyse-partie`, `experimentation-headless`, `synthese-projet` (celle
  générant ce document).

## 9. Rendu graphique

`DESIGN/roadmap_graphisme.md` — Phases 1 à 5 **[FAIT]**, Phase 6 (bilan + rédaction de la
roadmap graphisme suivante) restante :

- Ciel procédural + lumière directionnelle teintée golden hour, SSAO/SSR/glow (intensité 0.6,
  bloom 0.1) activés, tonemap ACES (exposition 2.0), TAA activé.
- Matériaux PBR CC0 (Poly Haven) via shader triplanar (`scripts/triplanar.gdshader`) pour sol
  et murs (roughness minimale 0.6, intensité de normal map 0.6).
- Terrain à relief procédural (section 2), décor procédural (section 3).
- Ronces en buisson vert (7 lobes) avec mûres noires visibles retirées une à une à la
  cueillette (refonte du 2026-08-22).
- Animation procédurale pour les 4 agents normaux ; rig Blender complet (armature, skinning,
  Idle/Walk/Death) réservé au personnage de développement (décision du 2026-08-23).

## 10. État de validation

`tests_manuels.md` est vide : plus aucun test manuel n'est en attente (couverts par
validation manuelle passée ou par `tools/run_manual_checks.py`). Le bug de clignotement de
texture d'herbe, longtemps listé comme ouvert dans `DESIGN/`, est résolu et confirmé depuis
le 2026-08-17 (CHANGELOG v0.6) — l'information n'avait simplement pas été répercutée dans
`DESIGN/_contexte/` avant la réconciliation du 2026-08-24.

`_docs/decisions/INDEX.md` recense 13 décisions, toutes `validé` sauf deux qui restent au
statut `proposé` depuis le 2026-08-17 (ronces/mûres/modale "Données du jeu", mode headless +
skills) alors qu'elles sont en usage productif et non remises en cause depuis — incohérence
de statut à signaler, non corrigée ici faute d'instruction explicite.

## 11. Points ouverts

- **Aucun LLM branché** : les 4 agents restent pilotés par un automate déterministe
  (`BaselineDecider`). Le pilotage par LLM est la Phase 7 de `roadmap_experimentation.md`,
  explicitement bloquée tant que les Phases 1 à 6 ne sont pas closes.
- **Communication écrite inter-IA** (prévue dans l'objectif initial, `_docs/but du projet.txt`)
  : non implémentée. Le seul canal social actuel est une perception de proximité qui déclenche
  un comportement de suivi ou d'évitement, sans échange de message.
- **Vue caméra par personnage / vue du dessus dédiée** (prévues dans l'objectif initial) :
  partiellement couvertes par le mode 1re personne contrainte et la vue libre ; pas de vue
  simultanée "ce que voit chaque IA" ni de vue du dessus dédiée.
- **Section d'état des panneaux personnage** (position/vitesse/exploration/mûres) : présente
  dans le code mais jamais rendue accessible en jeu (section 6).
- **`VariableRegistry`** (Phase 1 de `roadmap_experimentation.md`) non créé : les variables de
  `character.gd`/`GameConfig` restent définies indépendamment dans le code et l'UI.
- **Contexte narratif** : décision actée le 2026-08-24 (cadre non historique, île isolée —
  `DOCUMENTATION/orientation_contexte.md`), mais aucun travail de worldbuilding (nom, ton,
  identité visuelle) engagé.
- **Extension du rig Blender** aux 4 agents normaux : explicitement reportée (décision du
  2026-08-23).
- **Traits comportementaux** `curiosity`, `goal_persistence`, `risk_tolerance`, préférence
  pour les zones connues : non conçus (Phase 2 de `roadmap_experimentation.md`).
- **Coopération, communication, agressivité** (Phase 6 de `roadmap_experimentation.md`) :
  reportées tant que suivi/évitement ne sont pas jugés stables et mesurés.
