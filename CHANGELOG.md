## v0.11 — 2026-08-23

### Ajouté
- Contrat d'expérience versionné, validation des variables, événements environnementaux,
  campagnes reproductibles, logs JSONL, résumés et agrégation de résultats.
- Perception sociale, suivi et évitement paramétrables avec métriques dédiées.
- Dossier DOCUMENTATION et commande `python tools/run_smoke_tests.py`.

### Modifié
- Le rig Blender est officiellement réservé au personnage de développement.

## v0.9 — 2026-08-22

### Modifié
- Ronces refondues visuellement : buisson vert réaliste (7 lobes, couleur fixe qui ne
  change plus quand le roncier est vide) + mûres noires visibles sur le buisson (une
  sphère par mûre restante), retrait visuel d'une mûre à chaque cueillette ; suppression
  de la bascule plein/vide par matériaux.
- Sliders "Capacité à se nourrir" / "Mémoire" dans le panneau "Personnage de test" (mode
  dev) et détail de test scrollable dans la checklist.

### Validé
- Test manuel 5 ("Capacité à se nourrir" : gain de PV proportionnel au slider) confirmé
  en jeu et retiré de `tests_manuels.md` — restent les items 6, 8-12.

## v0.8 — 2026-08-18

### Ajouté
- Personnage riggé (Phase 5 graphisme) : armature + animations Idle/Walk/Death générées via
  Blender headless (`tools/blender/build_character.py` -> `assets/models/character.glb`),
  intégré uniquement sur le personnage de test (mode dev).
- Blender installé localement (`D:\blender`) pour régénérer le modèle sans dépendance
  externe.
- Touche K (mode dev) : tue le personnage de test à la demande (vérifie l'animation Death).
- Touche G (mode dev) : force la faim haute (déclenche la cueillette). Shift+F1-F4 :
  téléporte un personnage au contact de la ronce la plus proche (F1-F4 seul téléporte
  désormais au centre de la map).
- Persistance des réglages du jeu sur disque (`GameConfig`, `logs/game_config.json`) et
  nouveau réglage "Intensité lumineuse".

### Modifié
- Checklist en jeu (Phase 3 mode dev) : sélection individuelle par test (panneau détail
  Valide/Invalide/Fermer) au lieu d'un formulaire global, état persisté par test
  (`logs/dev_checklist_state.json`), masquage automatique des tests déjà validés.
- Caméra orbite (personnage de test) : correctif du pitch inversé, clamp au-dessus du
  terrain.

### Corrigé
- Items 1-4 de `tests_manuels.md` (bascule ronce, animation procédurale des 4 personnages,
  cueillette/consommation de base) validés et retirés après confirmation en jeu.

## v0.7 — 2026-08-18

### Ajouté
- Phase 3 du mode dev : checklist de tests manuels en jeu (touche T), sauvegarde des
  résultats dans `logs/dev_session_<horodatage>.json`.
- Personnage de test contrôlable manuellement (mode dev) : touche F5, déplacement ZQSD
  relatif à une caméra en orbite 3e personne pilotée à la souris, immortel. Remplace la
  dépendance à la téléportation F1-F4 seule pour observer cueillette/collision en direct.
  Panneau "Personnage de test" (mûres portées/ramassées, faim) en bas d'écran.
- Suivi caméra automatique lors d'une téléportation F1-F4.
- Aplanissement léger du terrain autour du spawn central (personnage de test).

### Modifié
- Touches dev réaffectées : H = forcer faim basse (repas), E = réservée à une future
  action du personnage de test (aucun effet pour l'instant).
- Luminosité ambiante réduite de 10%.

### Corrigé
- Propriété invalide `directional_shadow_normal_bias` (Godot 4.5) -> `shadow_normal_bias`.

## v0.6 — 2026-08-17

### Ajouté
- Mode dev (`run_dev.py`, `IA_LIFE_DEV_MODE`) : raccourcis clavier de déclenchement
  contrôlé (geler/reprendre la simulation, avancer d'une frame, forcer la faim,
  téléporter un personnage au contact d'une ronce), bandeau UX "MODE DEV" et indicateur
  "Temps gelé" — pour tester les mécaniques bloquées en observation directe.

### Corrigé
- Scène qui apparaissait comme une scène de nuit malgré la luminosité augmentée en
  session précédente : ciel, lumière directionnelle et exposition retravaillés (vérifié
  par capture d'écran automatisée avant/après).

### Validé
- Terrain, relief, cuvettes de spawn, faim/vieillissement/mort, vitesse de simulation et
  absence de clignotement de texture d'herbe — confirmés manuellement en jeu.

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
## v0.10 — 2026-08-23

### Ajouté
- Suite automatisée `tools/run_manual_checks.py` pour les tests de paramètres et de mémoire
  (6, 8, 9, 10 et 11).
- Touche E du personnage de test : ramasse une mûre proche en mode dev.

### Corrigé
- Retrait du log de diagnostic temporaire du déplacement ; enfoncement visuel des personnages
  et rendu des ronces/mûres validés.

### Modifié
- Roadmap du mode dev clôturée et archivée dans `_docs/archives/2026-08-23_roadmap_mode-dev.md`.
