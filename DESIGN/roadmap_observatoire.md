# Roadmap — direction visuelle Observatoire

Référence : `DESIGN/chartes_visuelles_propositions.md`, piste B. Objectif : intégrer cette direction dans le jeu, par incréments contrôlés. Le moodboard reste une cible d'ambiance, pas une spécification géométrique exacte.

## Phase 1 — Identité et lisibilité [EN COURS]

État au 2026-10-02 : intégration et tests automatisés réalisés ; contrôles visuels encore en attente dans `tests_manuels.md`. Ne pas marquer `[FAIT]` avant validation.

- Intégrer la palette Rouge / Bleu / Vert / Jaune dans les personnages, leurs repères et les commandes associées.
- Intégrer les polices IBM Plex Sans et Mono depuis leur source libre, avec la notice de licence.
- Unifier l'interface courante autour des panneaux bleu nuit, des textes clairs et de l'accent cyan. Rendre faim, mort et danger identifiables par un libellé ou une forme en plus de la couleur.
- Tests : compilation/chargement Godot, contrôles automatisés pertinents, puis contrôle visuel en jeu de la lisibilité des quatre agents et de leurs états. Inscrire tout contrôle manuel non effectué dans `tests_manuels.md`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Décor de l'arène [TODO]

Travaux anticipés au 2026-10-02 : modèles CC0, 108 arbres aux collisions désactivées sur demande, mûres repositionnées et relief multi-échelle intégrés ; tests automatisés passés. Contrôles visuels et de déplacement en attente dans `tests_manuels.md`. Le statut formel reste `[TODO]` tant que la phase 1 n'est pas close.

- Harmoniser murs, rochers, arbres et ronciers avec le rendu sobre du moodboard ; garder les objets et ressources immédiatement repérables.
- Chercher d'abord des assets gratuits à licence compatible sur le web. Si aucun ne convient, créer les éléments nécessaires ; recourir aux outils IA locaux seulement si utile.
- Conserver les collisions, positions et règles de simulation ; tester notamment l'absence de changement de parcours ou d'interaction induit par les seuls visuels.
- Tests : chargement Godot, contrôles de collision et de comportement pertinents, comparaison visuelle de plusieurs points de vue ; inscrire les contrôles manuels restants dans `tests_manuels.md`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Personnages et états en 3D [TODO]

- Améliorer la silhouette low-poly des quatre agents et les représentations de faim, mort et danger sans remplacer l'identité de leur couleur.
- Chercher d'abord des modèles et animations gratuits compatibles ; créer ou adapter seulement ce qui manque. Préserver l'usage réservé du rig actuel au personnage de développement tant qu'aucune décision nouvelle ne modifie cette règle.
- Tests : animation, lisibilité à distance, collisions, cueillette, mort et comparaison des comportements avant/après ; consigner les validations manuelles en attente.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
