## v0.5 — 2026-08-17

### Ajouté
- Capture d'écran automatisée (`run_screenshot.py`) : lance le jeu en fenêtre réelle,
  sauvegarde le viewport en PNG après un délai, permet une vérification visuelle sans
  intervention manuelle.
- Relief procédural rendu plus escarpé (amplitude 1.2 -> 5.0) et cuvettes de spawn
  (dépression douce) autour des 4 points d'apparition des personnages.
- Skill `synthese-projet` : génère un état des lieux complet du projet (personnages,
  variables du monde, carte, UX, outillage) dans `_docs/`, avec archivage automatique
  des synthèses précédentes.

### Corrigé
- Bug de rendu majeur : le terrain était invisible depuis le dessus (winding de mesh
  inversé, culling par défaut de Godot), diagnostiqué à tort au premier abord comme un
  problème de texture puis d'auto-ombrage. Corrigé par `render_mode cull_disabled` sur
  le shader triplanar.

### Modifié
- Luminosité de la scène augmentée (énergie de la lumière directionnelle, exposition du
  tonemap) — non validée visuellement de façon décisive.

## v0.4 — 2026-08-17

### Ajouté
- Matériaux PBR CC0 (Poly Haven) via shader triplanar pour le sol et les murs ; ronces
  remodelées en buisson (cluster de sphères).
- Animation procédurale des personnages : orientation vers la direction de déplacement,
  bobbing de marche, animation de mort progressive (tween).
- Cycle caméra 3 clics sur le nom d'un personnage : 3e personne, 1re personne ("yeux",
  regard souris contraint à ~±90° de lacet / ~±63° de tangage relatif au corps), retour
  exact à la caméra précédente.
- Terrain à relief procédural (bruit simplex + `HeightMapShape3D`, aplani en bordure de
  map) et décor procédural (rochers, arbres), en remplacement du sol plat — choisi plutôt
  que le plugin Terrain3D pour rester cohérent avec l'approche "tout par code" du projet.

### Connu
- Clignotement occasionnel de la texture d'herbe non résolu (aliasing spéculaire probable).

## v0.3 — 2026-08-17

### Ajouté
- Cueillette de mûres (ronces) : cueillette/consommation automatiques selon seuils de
  faim, capacité à se nourrir par personnage, modale "Données du jeu" configurable en
  direct (`GameConfig`).
- Mode headless (`run_headless.py`) + skills `analyse-partie`/`experimentation-headless`
  pour tester des réglages sans interface.
- Logging complet de session (`GameLogger`), archivé dans `logs/`.
- Mémoire spatiale des ronciers par personnage (capacité 0-10, renforcement/oubli
  progressif), avec retour ciblé vers le roncier mémorisé le plus proche en cas de faim.
- Collision physique des ronces (`StaticBody3D`), en complément de la détection.

### Modifié
- Vitesse de simulation étendue jusqu'à x50 (plafond headless recommandé x80).
- Caméra : suivi continu d'un personnage + zoom molette, bouton "Large" pour revenir au
  plan d'ensemble.
- Panneaux perso toujours visibles avec sections repliables ; distribution équitable des
  ronces par quadrant de map.

## v0.2 — 2026-08-17

### Ajouté
- Analyse du rendu graphique actuel et pistes d'amélioration gratuites (DESIGN/pistes_graphisme.md).
- Roadmap graphisme en 6 phases (DESIGN/roadmap_graphisme.md).

### Modifié
- Contrainte "personnages sans animation" levée — animation (marche/idle) intégrée au plan.

## v0.1 — 2026-08-17

### Ajouté
- Scaffold Godot programmatique : map 160x160, 4 personnages lowpoly, murs, caméra libre
  ZQSD, `run.py`.
- Déplacement aléatoire avec rebond aux collisions, zone de déplacement par personnage.
- Menu bas d'écran : panneaux de stats/édition par personnage (coins), focus caméra au
  clic, slider de vitesse de simulation globale, bouton de reset complet.
- Système de faim/vieillissement/mort par personnage.
- Archive des décisions d'évolution (`_docs/decisions/`).
