---
name: synthese-projet
description: Génère un état des lieux complet du projet IA_Life (objectif, carte, tous les objets présents, toutes les caractéristiques des personnages, toutes les variables du monde configurables, mécaniques, UX/parcours utilisateur, outillage, roadmap graphisme, points ouverts) et l'écrit dans _docs/ sous un nom horodaté. À utiliser quand l'utilisateur demande une synthèse, un état des lieux, un point d'étape complet du projet, ou de documenter "tout ce qui est implémenté".
tools: Read, Glob, Bash, Write
---

# Synthèse complète du projet IA_Life

## Principe
Cette skill produit un document autonome (lisible sans connaître le reste du dépôt) qui
décrit l'état réel du code à l'instant présent. **Ne jamais recopier une synthèse
précédente ni supposer une valeur par défaut de mémoire** — toutes les valeurs
(constantes, `@export`, plages de sliders) doivent être lues dans le code au moment de
l'exécution, elles évoluent au fil des sessions.

## Étape 1 — Lire l'intégralité des sources pertinentes
Lire ces fichiers en entier avant de rédiger quoi que ce soit :
- `scripts/main.gd` — construction de la scène : dimensions de la map, murs, terrain
  (relief, cuvettes de spawn), décor (rochers/arbres), spawn des personnages, spawn des
  ronces, caméra, UI, mode headless/screenshot.
- `scripts/character.gd` — toutes les variables `@export` du personnage (valeurs par
  défaut) et la logique de comportement (faim, mémoire, cueillette, mort, animation).
- `scripts/game_config.gd` — toutes les variables globales configurables (`GameConfig`)
  et leurs valeurs par défaut.
- `scripts/game_speed.gd` — variable de vitesse globale.
- `scripts/ronce.gd` — comportement d'un roncier.
- `scripts/free_camera.gd` — modes de caméra disponibles et leurs paramètres.
- `scripts/game_logger.gd` — ce qui est loggé.
- `scripts/ui_manager.gd` — chaque slider exposé à l'utilisateur : nom affiché, plage
  min/max (constantes en tête de fichier), variable liée. C'est la source de vérité pour
  "quelles variables du monde/personnage sont réglables en jeu et dans quelle plage".
- `scripts/triplanar.gdshader` — paramètres du matériau (utile pour la section rendu).
- `DESIGN/roadmap_graphisme.md` (si présent) — état des phases graphiques.
- `_docs/decisions/INDEX.md` — décisions archivées (statut proposé/validé/invalidé).
- `tests_manuels.md` — tests manuels en attente (signale ce qui n'est pas encore validé).
- `README.md` — structure générale du dépôt, pour ne rien oublier comme fichier.

Si un de ces fichiers n'existe pas ou plus, ne pas le mentionner comme une erreur :
adapter le document à l'état réel du dépôt.

## Étape 2 — Construire le document
Structure attendue (adapter les titres si la réalité du code diverge, mais couvrir
chaque point) :

1. **Objectif** — but du projet (reformulé à partir de `_docs/but du projet.txt` et/ou
   `_contexte/contexte.md` si présent), stack technique.
2. **Carte et environnement** — dimensions exactes de la map, hauteur/épaisseur des
   murs et leur matériau, paramètres du relief procédural (résolution, amplitude,
   fréquence de bruit, marge d'aplanissement aux bords), cuvettes de spawn si présentes
   (rayon, profondeur, points concernés), décor (type d'objets, quantité, méthode de
   génération/seed).
3. **Objets présents sur la map** — chaque type d'objet placé dans la scène (sol, murs,
   rochers, arbres, ronces, personnages) avec sa quantité ou règle de génération et son
   rôle fonctionnel (collision, interaction, purement décoratif).
4. **Personnages** — pour chaque variable `@export` de `character.gd` : nom, valeur par
   défaut, rôle, et si elle est réglable via un slider (`ui_manager.gd`) préciser le
   libellé affiché et la plage min/max. Couvrir explicitement : vitesse de déplacement,
   gravité, faim et taux de déplétion, vieillissement, capacité à se nourrir, capacité
   et taux de décroissance de la mémoire spatiale, zone d'exploration, apparence
   (couleur, position de spawn). Décrire aussi le cycle de vie (naissance → comportement
   → mort) et l'animation procédurale.
5. **Ronces et mûres** — toutes les variables de `GameConfig` (valeur par défaut, rôle,
   plage de réglage en jeu si exposée), règle de répartition sur la map (quadrants).
6. **Caméra et interface** — modes de caméra disponibles et leur déclenchement, éléments
   du menu bas et des panneaux personnage, modale "Données du jeu" et ce qu'elle permet
   de régler.
7. **UX / parcours utilisateur** — décrire l'expérience du point de vue de la personne
   qui lance `python run.py`, dans l'ordre chronologique réel :
   - Ce qui est visible et actif dès le lancement (vue caméra initiale, panneaux
     personnage déjà affichés ou non, curseur capturé/visible).
   - Les actions disponibles et leur découvrabilité (rien n'est expliqué en jeu tant
     qu'aucun tutoriel/texte d'aide n'existe dans le code — le signaler si c'est le cas) :
     déplacement caméra (ZQSD/E/C/souris/Maj), clic sur un nom pour changer de vue,
     molette en suivi, Échap pour libérer la souris, boutons du menu bas.
   - Le retour visuel donné à chaque état/action (barre de faim qui descend, mûres
     portées/ramassées/mangées affichées, label "DEAD" à la mort, bascule du personnage,
     sections repliables Réglages/Historique, changement de matériau plein/vide d'une
     ronce, curseur capturé qui bloque les clics UI tant qu'on n'appuie pas sur Échap).
   - Les points de friction ou d'ambiguïté potentiels identifiés en lisant le code (ex :
     aucune indication du rôle des sliders au premier lancement, aucun message si Godot
     ou un asset est introuvable, aucune confirmation avant "Relancer" qui efface la
     partie en cours).
   - Ne pas se limiter à lister les widgets (déjà couvert en section 6) : raconter le
     parcours et l'expérience ressentie, comme le ferait un compte-rendu de test
     utilisateur.
8. **Simulation et outillage** — vitesse de jeu (plage UI vs plage recommandée en
   headless si différente), logging (`GameLogger`, format, catégories), mode headless
   (`run_headless.py`), capture d'écran automatisée (`run_screenshot.py`), skills
   d'analyse/expérimentation disponibles.
9. **Rendu graphique** — état de chaque phase de la roadmap graphisme si le fichier
   existe, sinon décrire simplement l'éclairage/matériaux/shader en place.
10. **État de validation** — ce qui est implémenté vs validé manuellement en jeu (croiser
    `_docs/decisions/INDEX.md` et `tests_manuels.md`), bugs connus non résolus.
11. **Points ouverts** — écarts entre l'objectif initial et l'état actuel (ex. LLM non
    branché, communication inter-IA non implémentée si c'est toujours le cas).

Rester factuel : ne pas qualifier une mécanique de "fonctionnelle" ou "validée" si aucun
test manuel ne le confirme dans `tests_manuels.md` / `_docs/decisions/`.

## Étape 3 — Archiver les synthèses précédentes
Avant d'écrire la nouvelle synthèse, chercher les documents existants :
```
Glob _docs/*_synthese-projet.md
```
S'il y en a, créer `_docs/archives/` si absent, puis déplacer (Bash `mv`, pas de copie
qui laisserait un doublon) chacun des fichiers trouvés vers `_docs/archives/` en
conservant son nom horodaté d'origine. `_docs/` ne doit contenir qu'une seule synthèse
à la fois — la plus récente.

## Étape 4 — Nommer et écrire le fichier
Obtenir l'horodatage courant :
```bash
date +"%Y-%m-%d_%Hh%M"
```
Écrire le document dans `_docs/<horodatage>_synthese-projet.md` (`Write`).

## Étape 5 — Restituer
Indiquer à l'utilisateur le chemin du fichier créé et, s'il y en avait, le nombre de
synthèses archivées. Ne pas recopier le contenu intégral dans la réponse (le document
est déjà écrit) — un résumé de 2-3 lignes des sections couvertes suffit, sauf si
l'utilisateur demande explicitement de l'afficher.
