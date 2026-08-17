# Synthèse du projet — IA_Life

Date : 2026-08-17 13h32

## 1. Objectif
Environnement Godot avec des personnages lowpoly, chacun destiné à être piloté par un
LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier
l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

But global : faire évoluer des IA dotées d'un corps dans un jeu vidéo, relever et
analyser leurs comportements, évaluer l'impact des modifications du jeu sur ces
comportements (ex. ajout de nourriture + système de vie).

Stack : Godot 4.5 (GDScript), scène construite entièrement par code (`scripts/main.gd`,
pas de scène `.tscn` éditée à la main hormis `scenes/Main.tscn` qui référence le script).
Aucun LLM n'est branché à ce jour : les décisions de cueillette/consommation sont
simulées par seuils automatiques en attendant.

## 2. Carte et environnement

**Dimensions** : map carrée de 160x160 (`MAP_SIZE`), murs de 3.0 de haut, 1.0
d'épaisseur (`WALL_HEIGHT`, `WALL_THICKNESS`), matériau brique (`brick_wall_001`,
triplanar, échelle 0.5).

**Sol / relief procédural** : mesh généré par `SurfaceTool` (résolution de grille 80x80,
`TERRAIN_RESOLUTION`), hauteur calculée par bruit simplex (`FastNoiseLite`, seed 1337,
fréquence 0.045), amplitude 5.0 (`TERRAIN_AMPLITUDE`). Le relief s'aplatit sur une marge
de 12 unités près des murs (`TERRAIN_FLAT_MARGIN`) pour garder les murs plantés sur du
plat. Collision physique correspondante via `HeightMapShape3D`. Matériau : texture PBR
triplanar `leafy_grass`, échelle 0.25.

**Cuvettes de spawn** : chacun des 4 points de spawn des personnages ((-40,-40),
(40,-40), (-40,40), (40,40)) creuse une petite dépression dans le terrain (rayon 20,
profondeur 3.5, transition lissée par interpolation smoothstep — `_valley_offset()`).
Non encore confirmée visuellement à l'échelle rapprochée (vérifiée uniquement en vue
d'ensemble).

**Décor** : généré aléatoirement (seed fixe 1337, donc reproductible) dans une zone
retirée des murs de 3 unités :
- 8 rochers (`BoxMesh` déformé, taille aléatoire 0.5-1.1x, rotation Y aléatoire,
  matériau gris mat, collision boîte).
- 6 arbres (tronc cylindrique + houppier sphérique, taille aléatoire 0.85-1.3x,
  collision cylindrique sur le tronc uniquement).
Tous deux posés à la hauteur du terrain à leur position (`_terrain_height`).

**Shader triplanar** (`scripts/triplanar.gdshader`) : projection sur 3 axes pondérée par
la normale (`blend_sharpness` 4.0), utilisé pour le sol et les murs. `render_mode
cull_disabled` (ajouté suite à un bug de winding inversé sur le mesh de terrain qui le
rendait invisible depuis le dessus). `min_roughness` 0.6, `normal_strength` 0.6.

## 3. Objets présents sur la map
| Objet | Quantité / règle | Rôle |
|---|---|---|
| Sol (terrain) | 1, mesh procédural | Support de déplacement, collision, support visuel des cuvettes de spawn |
| Murs | 4 (un par côté) | Limite physique de la map |
| Rochers | 8, position aléatoire (seed fixe) | Décor + collision (obstacle) |
| Arbres | 6, position aléatoire (seed fixe) | Décor + collision sur le tronc |
| Ronces (buissons de mûres) | `GameConfig.ronce_count` (def. 24), réparties à parts égales entre les 4 quadrants de la map | Ressource de nourriture : détection (`Area3D`) + collision physique (`StaticBody3D` cylindre rayon 1.0) |
| Personnages | 4 (Rouge, Bleu, Vert, Jaune), un par coin | Entités simulées |
| Caméra | 1, `free_camera.gd` | Vue du joueur/observateur |
| UI (CanvasLayer) | 1 | Menu bas, panneaux persos, modale Données du jeu |

## 4. Personnages (`scripts/character.gd`)
Toutes les variables sont des `@export`, donc réglables individuellement par personnage
(via `character_defaults` en mode headless, ou en jeu via les sliders listés).

| Variable | Valeur par défaut | Rôle | Réglable en jeu |
|---|---|---|---|
| `map_half_x` / `map_half_z` | ~78.6 (calculé depuis `MAP_SIZE`) | Demi-étendue de déplacement (clamp de position) | Oui — slider "Exploration", 5 à 80 |
| `move_speed` | 2.5 | Vitesse de déplacement | Oui — slider "Vitesse", 0.5 à 10.0 |
| `gravity` | 9.8 | Gravité appliquée quand pas au sol | Non |
| `hunger` | 100.0 | Points de vie / faim, 0 = mort | Affiché (barre de vie), pas réglable directement |
| `hunger_depletion_rate` | 0.6 | Vitesse de déplétion de la faim (par seconde simulée) | Non (réglable seulement via override headless) |
| `aging_factor` | 1.0 | Multiplicateur de la déplétion de faim (vieillissement) | Oui — slider "Vieillissement", 0.1 à 5.0 |
| `feeding_capacity` | 1.0 | Multiplicateur des PV gagnés par mûre mangée | Oui — slider "Capacité à se nourrir", 0.1 à 3.0 |
| `memory_capacity` | 5 | Nombre max de ronciers mémorisés simultanément | Oui — slider "Mémoire", 0 à 10 |
| `memory_decay_rate` | 0.15 | Vitesse d'oubli d'un souvenir de roncier | Non |
| `display_name` | "" (assigné au spawn) | Nom affiché | Non |

Variables internes non exportées mais suivies : `is_dead`, `berries_carried` (0 à
`GameConfig.max_berries_carried`), `berries_picked_total`, `berries_eaten_total`.

**Cycle de vie** :
1. Apparition à un coin fixe, position Y = hauteur du terrain + 1.0, direction de marche
   aléatoire.
2. Chaque frame physique : la faim décroît (`hunger_depletion_rate * aging_factor *
   delta_simulé`, `delta_simulé` dépend de `GameSpeed.time_scale`).
3. Marche aléatoire par défaut (changement de direction toutes les 1.5 à 4s, ou rebond
   à une collision) ; si la faim dépasse `GameConfig.pickup_hunger_threshold` et qu'au
   moins un roncier est mémorisé, se dirige vers le plus proche mémorisé.
4. Au contact d'un roncier (`_on_ronce_contact`) : mémorise sa position (renforce si déjà
   connu), cueille une mûre si faim > seuil de cueillette et pas déjà au max porté.
5. Consommation automatique dès que faim < seuil de consommation et au moins une mûre
   portée (`pv_per_berry(feeding_capacity)` PV gagnés, capé à 100).
6. Mort à faim = 0 : figé, bascule (`rotation:z` à 90°, position Y à 0.35) sur 0.6s
   (tween cubique), log du bilan de mûres.

**Animation procédurale** : orientation vers la direction de déplacement (slerp),
bobbing vertical + tilt du corps en marche (fonction de la vitesse), retour lissé au
repos (idle) à l'arrêt.

**Apparence** : corps = `BoxMesh` 0.6x1.0x0.4, tête = `BoxMesh` 0.4x0.4x0.4, couleur
unie par personnage (Rouge 0.8/0.2/0.2, Bleu 0.2/0.4/0.8, Vert 0.2/0.7/0.3, Jaune
0.9/0.7/0.1). Collision : capsule (rayon 0.35, hauteur 1.4).

## 5. Ronces et mûres (`scripts/game_config.gd`, `scripts/ronce.gd`)
Autoload `GameConfig`, valeurs globales (pas par personnage) :

| Variable | Valeur par défaut | Rôle | Réglable en jeu |
|---|---|---|---|
| `max_berries_carried` | 3 | Nombre max de mûres portées par un personnage | Oui — modale "Données du jeu", 1 à 10 |
| `pickup_hunger_threshold` | 90.0 | Faim au-dessus de laquelle un personnage cueille | Oui — 0 à 100 |
| `eat_hunger_threshold` | 50.0 | Faim en dessous de laquelle un personnage mange | Oui — 0 à 100 |
| `full_life_berries` | 6.0 | Nombre de mûres nécessaires pour regagner 100 PV | Oui — 1 à 20 |
| `ronce_count` | 24 | Nombre total de ronces sur la map | Oui, mais appliqué seulement au prochain "Relancer" — 1 à 30 |
| `berries_per_ronce` | 3 | Nombre de mûres par ronce | Oui, appliqué au prochain "Relancer" — 1 à 10 |

Formule : `pv_per_berry(feeding_capacity) = (100 / full_life_berries) * feeding_capacity`.

**Répartition** : les ronces sont réparties à parts égales entre les 4 quadrants de la
map (alignés sur les 4 coins de spawn), positions aléatoires dans chaque quadrant, pour
éviter que le hasard de répartition ne biaise les résultats entre personnages.

**Roncier** (`ronce.gd`) : `Area3D` avec détection par contact (`body_entered`),
`harvest_one()` décrémente son stock, matériau visuel différent plein/vide (violet
0.25/0.15/0.35 plein, gris-vert 0.3/0.3/0.25 vide). Mesh en "buisson" (cluster de 5
lobes sphériques via `SurfaceTool.append_from`). Collision physique séparée
(`StaticBody3D` + cylindre rayon 1.0) en plus de la zone de détection.

## 6. Caméra et interface

**Caméra** (`scripts/free_camera.gd`) : 3 modes.
- `FREE` : déplacement clavier ZQSD + E/C (haut/bas), souris pour orienter, Maj pour
  accélérer (x3 par défaut). Position/rotation initiales : (0, 60, 80) / (-30°, 0, 0).
- `FOLLOW` (3e personne) : suit un personnage à un offset (0, 12, 8), zoom à la molette
  (0.3x à 3.0x).
- `FPS` (1re personne contrainte) : position aux yeux du personnage (hauteur 1.2, léger
  décalage avant), regard limité à ±90° en lacet et ±63° en tangage par rapport à
  l'orientation du corps.
- Cycle par clic sur le nom d'un personnage dans le menu : 1er clic = FOLLOW, 2e clic =
  FPS, 3e clic = retour à la caméra précédente (position/rotation restaurées si c'était
  FREE). Bouton "Large" : retour direct à la vue d'ensemble initiale.

**UI** (`scripts/ui_manager.gd`) :
- Menu bas : slider "Vitesse jeu" (0.1x à 50x), boutons nominatifs par personnage
  (couleur du perso), bouton "Données du jeu", bouton "Large", bouton "Relancer" (reset
  complet de la scène + nouvelle session de log).
- 4 panneaux personnage permanents (un par coin d'écran), avec :
  - Nom, état "DEAD" si mort.
  - Section "Réglages" (repliable, repliée par défaut) : sliders Vitesse, Exploration,
    Vieillissement, Capacité à se nourrir, Mémoire.
  - Section "Historique" (repliable, dépliée par défaut, visible même mort) : mûres
    ramassées/mangées (total), ronciers mémorisés (N/capacité).
  - Barre de faim (PV), toujours visible, indépendante des sections repliables.
  - Section "État" (position, vitesse, exploration, mûres portées) : construite et mise
    à jour en interne mais masquée (`visible = false`).
- Modale "Données du jeu" (centrée, bascule à un clic) : sliders pour les 6 variables de
  `GameConfig` listées en section 5.

## 7. Simulation et outillage

**Vitesse de jeu** : `GameSpeed.time_scale`, autoload global, multiplie le `delta`
physique appliqué à la faim et au déplacement. Slider UI limité à 50x. En mode headless,
un override JSON peut fixer une valeur différente, mais il est recommandé de ne pas
dépasser 80x (au-delà, risque de tunneling physique : un personnage peut traverser une
ronce en un seul tick sans déclencher la détection).

**Logging** (`scripts/game_logger.gd`, autoload `GameLogger`) : un fichier par partie
dans `logs/session_<horodatage>_pid<PID>.log`, format `[  XX.Xs][catégorie] message`
(secondes réelles écoulées, pas simulées). Catégories : `session`, `spawn`, `cueillette`,
`repas`, `mémoire`, `mort`, `config`, `camera`, `headless`, `screenshot`.

**Mode headless** (`run_headless.py`) : lance Godot avec `--headless` (aucun rendu GPU —
utilisable uniquement pour la logique/logs, pas pour la capture d'écran) et un fichier
JSON d'overrides (variable d'environnement `IA_LIFE_HEADLESS_CONFIG`) permettant de
modifier `game_config`, `game_speed`, `character_defaults`, avec arrêt automatique
(`quit_on_all_dead`, `max_wall_seconds`).

**Capture d'écran automatisée** (`run_screenshot.py`, ajouté cette session) : lance
Godot en fenêtre réelle (pas `--headless`, car le rendu GPU est nécessaire), attend un
délai configurable puis sauvegarde le viewport en PNG et quitte. Utilise le même
mécanisme d'overrides JSON avec une clé `screenshot: {path, delay_seconds}`.

**Skills disponibles** : `analyse-partie` (analyse de logs), `experimentation-headless`
(campagnes de tests automatisées), `synthese-projet` (cette skill).

## 8. Rendu graphique
Roadmap dédiée : `DESIGN/roadmap_graphisme.md`.
- **Phase 1** (lumière/post-traitement) : validée. Ciel procédural, SSAO, SSR, glow,
  tonemap ACES (exposition 1.6), TAA, lumière directionnelle (couleur chaude, énergie
  2.2, ombres PCSS avec bias 0.1 / normal bias 4.0).
- **Phase 2** (textures PBR triplanar sol/murs, ronces en buisson) : implémentée, non
  validée manuellement.
- **Phase 3** (orientation + animation procédurale des personnages) : implémentée, non
  validée manuellement.
- **Phase 4** (relief procédural, décor, cuvettes de spawn) : implémentée. Un bug de
  culling de mesh (winding inversé rendant le terrain invisible depuis le dessus) a été
  identifié et corrigé cette session (`render_mode cull_disabled`). Non validée
  manuellement à l'échelle rapprochée.
- **Phase 5** (personnages riggés, animation squelettique) et **Phase 6** (roadmap
  suivante) : non commencées.

## 9. État de validation
Aucune mécanique de jeu ni aucune phase graphique n'est à ce jour validée par test
manuel complet en jeu (`python run.py`) — la file d'attente est dans `tests_manuels.md`.
Les décisions archivées dans `_docs/decisions/INDEX.md` liées aux mûres/mémoire/données
du jeu et au mode headless sont au statut "proposé" ; celles liées au déplacement,
menu/caméra, simulation (faim/mort), animation des personnages et relief procédural
(choix technique) sont "validé".

Bugs connus non résolus :
- Clignotement occasionnel de la texture d'herbe (aliasing spéculaire probable).

Bugs identifiés et corrigés cette session :
- Terrain invisible depuis le dessus (winding de mesh inversé, culling par défaut) —
  corrigé par `render_mode cull_disabled` sur le shader triplanar.

## 10. Points ouverts
- Aucun LLM n'est branché : la cueillette/consommation reste simulée par seuils fixes.
- Communication inter-IA loguée : prévue dans l'objectif initial, non implémentée.
- Caméra dédiée par personnage (vue simultanée de ce que chacun voit) : remplacée par le
  cycle de caméra à 3 clics (un seul point de vue actif à la fois), pas de multi-vue
  simultanée.
- Cuvettes de spawn et relief escarpé (amplitude 5.0) : impact sur le déplacement des
  personnages en pente non vérifié en jeu.
