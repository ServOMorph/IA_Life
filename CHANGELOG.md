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
