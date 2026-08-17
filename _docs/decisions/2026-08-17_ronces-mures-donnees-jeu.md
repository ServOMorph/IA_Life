# Ronces à mûres, cueillette/consommation automatiques, modale Données du jeu

**Date :** 2026-08-17
**Statut :** proposé

## Décision
- Des ronces (sphères violettes) sont disséminées aléatoirement sur la map au lancement,
  chacune portant un nombre configurable de mûres.
- Un personnage peut porter jusqu'à 3 mûres (configurable). Faute d'IA/LLM branché, la
  décision de cueillir est simulée automatiquement : au contact d'une ronce, le personnage
  cueille une mûre uniquement si sa faim est sous un seuil configurable (par défaut 80) et
  s'il n'a pas déjà atteint le max porté.
- La consommation est également automatique : dès que la faim d'un personnage passe sous
  un seuil configurable (par défaut 50) et qu'il porte au moins une mûre, il en mange une.
  6 mûres redonnent toute la vie (100 PV) par défaut ; ce nombre est configurable.
- Une ronce cueillie ne repousse pas (jusqu'au reset complet du jeu).
- Chaque personnage a une "capacité à se nourrir" (`feeding_capacity`, slider dans son
  panneau) qui multiplie les PV gagnés par mûre mangée.
- Un bouton "Données du jeu" dans le menu bas ouvre une modale centrée permettant de
  configurer en direct : max mûres portées, seuils de cueillette/consommation, nombre de
  mûres pour vie complète. Le nombre de ronces et de mûres/ronce y sont aussi réglables
  mais ne s'appliquent qu'au prochain "Relancer" (respawn de scène).

## Implémentation
- `scripts/game_config.gd` (nouveau, autoload `GameConfig`) : constantes globales
  configurables + `pv_per_berry(feeding_capacity)`.
- `scripts/ronce.gd` (nouveau, `Area3D`) : détecte le contact via `body_entered`,
  expose `harvest_one()`, matériau différent si vide.
- `scripts/character.gd` : `berries_carried`, `feeding_capacity`, `_on_ronce_contact()`,
  `_try_eat_berry()` appelés dans `_physics_process`.
- `scripts/main.gd` : `_spawn_ronces()` place `GameConfig.ronce_count` ronces aléatoirement
  dans les limites de la map.
- `scripts/ui_manager.gd` : bouton + modale "Données du jeu" (`_build_game_data_panel`,
  helper générique `_build_slider_row`), slider "Capacité à se nourrir" et label mûres
  portées dans le panneau perso existant. Compteurs "Mûres ramassées/mangées (total)"
  affichés en permanence dans le panneau, y compris après la mort.
- `project.godot` : déclaration de l'autoload `GameConfig`.

## Ajustement d'équilibrage (2026-08-17)
Premier test : tous les personnages morts sans avoir ramassé de mûre. Cause : avec les
valeurs initiales (8 ronces sur 160x160, `hunger_depletion_rate` 2.0/s soit ~50s de survie,
rayon de collision ronce 0.9), la probabilité de croiser une ronce en marche aléatoire avant
de mourir était trop faible. Ajustement des valeurs par défaut :
- `hunger_depletion_rate` : 2.0 -> 0.6 (survie ~166s)
- `GameConfig.ronce_count` : 8 -> 24
- `GameConfig.pickup_hunger_threshold` : 80 -> 90
- rayon de collision ronce : 0.9 -> 2.0 (rayon visuel 0.8 -> 1.3)

## Sections repliables (2026-08-17)
Le panneau perso est réorganisé en sections repliables via une flèche (▼/▶) :
"État" (dépliée par défaut), "Réglages" (repliée par défaut), "Historique" (dépliée,
visible même mort). Helper générique `_build_collapsible_section()` dans `ui_manager.gd`.

## Panneaux perso permanents (2026-08-17)
Les 4 panneaux perso sont désormais affichés en permanence dès le lancement (construits
dans `setup()`), sans clic requis. Le bouton coloré du menu bas ne sert plus qu'à centrer
la caméra sur le personnage (`_camera.focus_on`) — il n'ouvre/ferme plus le panneau. La
barre de PV (faim) est sortie de la section repliable "État" et affichée en permanence en
bas du panneau, indépendamment du pli/dépli des sections.

## Renommage et masquage État (2026-08-17)
Le libellé "Zone" est renommé "Exploration" (slider Réglages + relevé interne). La
section "État" (position, vitesse, exploration, mûres portées) n'est plus affichée
(`etat_content.visible = false`, plus de section repliable/titre) mais reste construite
et mise à jour en interne par `_update_panel_texts`.

## Caméra accrochée + bouton Large (2026-08-17)
Clic sur un nom dans le menu bas accroche la caméra en continu sur le personnage
(`free_camera.gd::follow()`, suivi chaque frame, mouvement libre désactivé tant que
le suivi est actif) au lieu d'un simple recentrage ponctuel (`focus_on` supprimé).
Bouton "Large" ajouté dans le menu bas : coupe le suivi et remet la caméra en plan
d'ensemble initial (`reset_view()`), aussi réutilisé par `main.gd` à l'initialisation.

## Zoom molette en suivi caméra (2026-08-17)
Pendant le suivi d'un personnage, la molette de la souris rapproche/éloigne la caméra
(`_follow_zoom`, borné 0.3-3.0, applique un facteur sur `FOLLOW_OFFSET`). Réinitialisé
à 1.0 par `reset_view()` (bouton "Large").

## Vitesse jeu x50 + logging de session (2026-08-17)
- Slider "Vitesse jeu" étendu de 5x à 50x max.
- `scripts/game_logger.gd` (nouveau, autoload `GameLogger`) : écrit un fichier
  `logs/session_<horodatage>.log` par partie (nouveau à chaque "Relancer"), timestampé
  en secondes écoulées. Événements loggés : apparition perso, cueillette, repas (PV
  gagnés), mort (bilan mûres ramassées/mangées), tout changement de config (vitesse
  jeu, sliders perso, modale Données du jeu), suivi/retour caméra.
- `logs/` ajouté au `.gitignore`.

## Distribution équitable des ronces par quadrant (2026-08-17)
Les ronces étaient réparties uniformément sur toute la map (pas de garantie d'un nombre égal
par zone de spawn), ce qui mélangeait "hasard de déplacement" et "chance de position" dans les
résultats observés (cf. session du 01-24-07 : Bleu 0 mûre vs Rouge 11). La map est désormais
divisée en 4 quadrants alignés sur les 4 coins de spawn, et `GameConfig.ronce_count` est réparti
à parts égales entre les 4 (`main.gd::_spawn_ronces()`). Objectif : isoler le hasard de la marche
aléatoire comme variable propre avant de faire varier d'autres paramètres.

## Mémoire spatiale des ronciers (2026-08-17)
Chaque personnage mémorise les ronciers découverts au contact. `memory_capacity` (0-10,
slider Réglages) plafonne le nombre de souvenirs simultanés. Chaque souvenir a une force
initiale à 10 qui décroît avec le temps (indexée sur `time_scale`) et se renforce à 10 en
cas de revisite ; à 0 le souvenir est oublié. Mémoire pleine : le souvenir le plus faible
est remplacé (modèle inspiré du renforcement/oubli de la mémoire humaine). Quand la faim
dépasse le seuil de cueillette et qu'au moins un roncier est mémorisé, le personnage se
dirige vers le plus proche au lieu de marcher aléatoirement. Implémentation :
`scripts/character.gd` (`_remember_ronce`, `_decay_memories`, `_direction_to_nearest_memory`),
slider "Mémoire" + compteur "Ronciers mémorisés" dans `scripts/ui_manager.gd`.

## Collision physique des ronces (2026-08-17)
Les ronces ne disposaient que d'une `Area3D` de détection (rayon 2.0), sans bloquer
physiquement les personnages. Ajout d'un `StaticBody3D` + `CollisionShape3D` (cylindre,
rayon 1.0) sous chaque ronce dans `scripts/main.gd::_spawn_ronce`, en complément de
l'`Area3D` inchangée. Vérifié en headless (8 runs x50) : cueillette/mémorisation
inchangées, aucune régression détectée.

## Commentaire
(à compléter lors de la validation/invalidation)
