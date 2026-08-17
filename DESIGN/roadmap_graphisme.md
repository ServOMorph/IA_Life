# Roadmap — Graphisme

Créée le : 2026-08-17
Basée sur : `pistes_graphisme.md`

## Phase 1 — Lumière et post-traitement [EN COURS]
Piste A. Aucun asset externe requis.

- Ajouter un `WorldEnvironment` avec `ProceduralSkyMaterial` (ciel + lumière ambiante).
- Activer SSAO, SSR, glow, tonemap ACES/Filmic, anti-aliasing (TAA ou MSAA).
- Ombres douces (PCSS) sur la `DirectionalLight3D`, réglage de teinte (golden hour).
- Test : ajouter une entrée dans `tests_manuels.md` (racine) pour valider visuellement le rendu (comparatif avant/après, absence de régression sur la lisibilité de la scène) avant de marquer la phase [FAIT].

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 2 — Matériaux PBR et ressources visuelles [TODO]
Pistes B + E.

- Textures PBR CC0 (Poly Haven) pour le sol et les murs, shader triplanar pour éviter l'étirement sur les `BoxMesh`.
- Modèle de buisson/ronce (pack nature CC0 ou modélisation rapide) à la place de la `SphereMesh` pleine/vide, sans toucher à la logique `ronce.gd`.
- Test : entrée `tests_manuels.md` pour validation visuelle (textures correctement mappées, pas de distorsion, bascule plein/vide toujours lisible).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 3 — Animation procédurale des personnages [TODO]
Piste D1. Aucun nouvel asset, sur la géométrie actuelle (corps + tête).

- Orientation du personnage vers sa direction de déplacement (absente actuellement).
- Bobbing/tilt de marche, état idle vs marche selon `velocity.length()`.
- Animation de mort dédiée en remplacement du `rotation_degrees.z = 90.0` codé en dur.
- Test : entrée `tests_manuels.md` pour validation visuelle (transition idle/marche/mort fluide, cohérente avec l'état réel du personnage).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 4 — Terrain et décor [TODO]
Piste C.

- Intégration du plugin Terrain3D, relief léger, chemins, zones d'herbe haute/basse.
- Adaptation du déplacement des personnages au sol non plat (suivi de la hauteur Y — actuellement un simple clamp X/Z).
- Décor CC0 (rochers, arbres) via Kenney/Quaternius.
- Test : entrée `tests_manuels.md` pour validation visuelle et fonctionnelle (personnages ne traversent pas le relief, pas de blocage sur les pentes).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 5 — Personnages riggés et animation squelettique [TODO]
Piste D2. Remplace la géométrie boîte + animation procédurale de la phase 3 par un vrai rig.

- Choix du modèle : pack low-poly riggé CC0 (Quaternius) ou modèle custom (Blender + rig, éventuellement Mixamo pour un rig humanoïde auto).
- Intégration `AnimationPlayer`/`AnimationTree` (marche, idle, mort).
- Remplacement de l'animation de mort procédurale (phase 3) par l'animation squelettique dédiée.
- Test : entrée `tests_manuels.md` pour validation visuelle (animations synchronisées avec l'état du personnage, pas de glissement de pieds, transition mort correcte).

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.

## Phase 6 — Écriture de la roadmap suivante [TODO]
- Bilan de ce qui reste hors périmètre de cette roadmap (piste F — UI ; ajustements suite aux retours des phases précédentes).
- Rédaction de `roadmap_<sujet-suivant>.md` dans `DESIGN/`.

**⏸ Checkpoint** — Demander à l'utilisateur de faire `/compact` avant de continuer.
Attendre sa réponse écrite. Ne pas commencer la phase suivante sans confirmation.
