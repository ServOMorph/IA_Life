# Roadmap — Graphisme

Créée le : 2026-08-17
Basée sur : `pistes_graphisme.md`

## Phase 1 — Lumière et post-traitement [FAIT]
Piste A. Aucun asset externe requis.

- Ajouter un `WorldEnvironment` avec `ProceduralSkyMaterial` (ciel + lumière ambiante).
- Activer SSAO, SSR, glow, tonemap ACES/Filmic, anti-aliasing (TAA ou MSAA).
- Ombres douces (PCSS) sur la `DirectionalLight3D`, réglage de teinte (golden hour).
- Test : ajouter une entrée dans `tests_manuels.md` (racine) pour valider visuellement le rendu (comparatif avant/après, absence de régression sur la lisibilité de la scène) avant de marquer la phase [FAIT].

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Matériaux PBR et ressources visuelles [FAIT]
Pistes B + E.

- Textures PBR CC0 (Poly Haven) pour le sol et les murs, shader triplanar pour éviter l'étirement sur les `BoxMesh`.
- Modèle de buisson/ronce (pack nature CC0 ou modélisation rapide) à la place de la `SphereMesh` pleine/vide, sans toucher à la logique `ronce.gd`.
- Test : validé en jeu (items 1-4 de `tests_manuels.md`, CHANGELOG v0.6/v0.8). Le rendu des
  ronces a ensuite été refondu le 2026-08-22 (buisson vert + mûres visibles, suppression de
  la bascule plein/vide) — voir `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`,
  validation confirmée le 2026-08-23 (test manuel 15).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Animation procédurale des personnages [FAIT]
Piste D1. Aucun nouvel asset, sur la géométrie actuelle (corps + tête).

- Orientation du personnage vers sa direction de déplacement (absente actuellement).
- Bobbing/tilt de marche, état idle vs marche selon `velocity.length()`.
- Animation de mort dédiée en remplacement du `rotation_degrees.z = 90.0` codé en dur.
- Test : validé en jeu (« animation procédurale des 4 personnages », item de
  `tests_manuels.md`, CHANGELOG v0.8).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Terrain et décor [FAIT]
Piste C. Décision 2026-08-17 : relief procédural par code (bruit simplex + `HeightMapShape3D`)
plutôt que le plugin Terrain3D — voir `_docs/decisions/2026-08-17_terrain-relief-procedural.md`.

- Relief léger généré par bruit simplex, aplani en bordure de map (murs).
- Personnages/ronces repositionnés à leur hauteur de terrain au spawn ; suivi de la hauteur en jeu géré par la collision physique (`HeightMapShape3D`) plutôt qu'un clamp Y.
- Décor procédural (rochers, arbres) sans dépendance externe.
- Test : validé en jeu (« Terrain, relief, cuvettes de spawn » — CHANGELOG v0.6).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 5 — Personnages riggés et animation squelettique [FAIT — limité au personnage de développement]
Piste D2. Remplace la géométrie boîte + animation procédurale de la phase 3 par un vrai rig,
mais uniquement pour le personnage de test (mode dev).

- Choix du modèle : modélisation custom (Blender + rig, généré par script
  `tools/blender/build_character.py` -> `assets/models/character.glb`) — décision 2026-08-17,
  débloquée le 2026-08-18.
- Intégration `AnimationPlayer`/`AnimationTree` (marche, idle, mort) sur le personnage de test.
- Décision du 2026-08-23 : le rig reste réservé au personnage de développement ; les 4 agents
  normaux conservent la géométrie boîte + animation procédurale (Phase 3) afin de préserver la
  priorité expérimentale — voir `_docs/decisions/2026-08-23_rig-limite-personnage-dev.md`.
  Toute extension future exige une nouvelle décision et une validation dédiée.
- Test : validé en jeu le 2026-08-18 — voir
  `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 6 — Écriture de la roadmap suivante [TODO]
- Bilan de ce qui reste hors périmètre de cette roadmap (piste F — UI ; ajustements suite aux retours des phases précédentes).
- Rédaction de `roadmap_<sujet-suivant>.md` dans `DESIGN/`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
