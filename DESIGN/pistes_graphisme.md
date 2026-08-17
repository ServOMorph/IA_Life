# Pistes graphisme — DESIGN

Date : 2026-08-17

## Constat — état actuel du rendu

Analyse de `project.godot`, `scenes/Main.tscn`, `scripts/main.gd`, `scripts/character.gd`, `scripts/ronce.gd`, `scripts/free_camera.gd`.

- Renderer : **Forward+** (bon point — supporte SSAO, SSR, glow, volumetric fog, PCSS nativement, sans coût de licence).
- **Aucun `WorldEnvironment`** dans la scène (`Main.tscn` ne contient que le nœud racine + script). Pas de ciel, pas de lumière ambiante, pas de post-traitement → fond noir par défaut, rendu plat.
- Une seule `DirectionalLight3D`, ombres activées mais aucun réglage de qualité (pas de PCSS/soft shadows).
- Géométrie 100 % primitives Godot : sol = `BoxMesh` uni, murs = `BoxMesh` uni, personnages = 2 `BoxMesh` empilées (corps + tête, sans membres ni articulation), ronces = `SphereMesh`.
- Matériaux : `StandardMaterial3D` en couleur plate uniquement — aucune texture, aucune normal map, aucun roughness travaillé.
- Aucun post-processing (tonemapping, glow, DOF, color grading, AA).
- Contrainte du projet (`contexte.md`) : scène construite entièrement par code, pas d'édition via l'éditeur de scène.

**Mise à jour 2026-08-17** : la contrainte "personnages sans animation" est levée (décision utilisateur) — l'animation (marche/idle a minima) est désormais un objectif du plan, intégrée à la piste D ci-dessous.

En clair : le rendu actuel est un prototype fonctionnel, pas un rendu soigné. C'est cohérent avec la phase du projet (mécaniques avant graphisme), mais tout le potentiel du renderer Forward+ est inexploité.

## Cadrage réaliste

"Hyperréaliste" avec des outils gratuits (pas de Unreal/Unity + assets payants, pas de ray tracing matériel exploité par Godot) a un plafond : on peut atteindre un rendu **stylisé-réaliste soigné** (éclairage physique, textures PBR, post-processing propre), pas du photoréalisme type cinématique. Le déclarer maintenant pour éviter un objectif final irréaliste — les pistes ci-dessous visent ce plafond haut, en partant simple comme demandé.

À noter aussi : le temps investi en graphisme n'avance pas l'objectif d'étude comportementale des IA — c'est un axe parallèle, pas bloquant pour le reste, mais qui consomme du budget session.

## Pistes de travail (indépendantes, combinables)

### A — Lumière et post-traitement (gain immédiat, coût quasi nul)
- Ajouter un `WorldEnvironment` avec `ProceduralSkyMaterial` (ciel + lumière ambiante réalistes sans aucun asset externe).
- Activer SSAO, SSR, glow, tonemap ACES/Filmic, anti-aliasing (TAA ou MSAA).
- Ombres douces (PCSS), lumière directionnelle réglée en teinte "golden hour" pour donner du volume.
- Outils : natif Godot, zéro téléchargement.
- Rapport effort/gain : le meilleur du plan — à faire en premier.

### B — Matériaux PBR simples (sol, murs)
- Remplacer les couleurs unies par des textures PBR gratuites CC0 (Poly Haven — herbe, terre, pierre, écorce).
- Shader triplanar pour éviter l'étirement de texture sur les `BoxMesh` sans réunwrap.
- Outils : Poly Haven (gratuit, CC0), shader triplanar Godot (code, pas d'asset payant).
- Effort : faible à moyen.

### C — Environnement / terrain
- Remplacer le sol plat par un terrain avec relief léger (plugin open source **Terrain3D**) : dénivelés, chemins, zones d'herbe haute/basse.
- Décor : rochers, arbres, végétation via packs low-poly CC0 (Kenney.nl, Quaternius) — cohérent avec le style lowpoly déjà en place.
- Point d'attention : le pathfinding actuel des personnages est un simple clamp aux limites de la map (`character.gd`) — un terrain non plat demanderait d'adapter le déplacement (suivi du sol en Y).
- Effort : moyen, dépend de l'intégration du plugin.

### D — Personnages et animation
Deux approches possibles, non exclusives dans le temps (D1 peut être une étape intermédiaire avant D2) :

**D1 — Animation procédurale sur la géométrie actuelle (rapide, sans nouvel asset)**
- Garder les 2 `BoxMesh` (corps + tête) mais les animer par code/`AnimationPlayer` : bobbing vertical à la marche, tilt/balancement du corps, léger squash au contact du sol, orientation vers la direction de déplacement (actuellement absente — les personnages glissent sans se tourner).
- État idle vs marche déclenché sur `velocity.length()`.
- Outils : natif Godot (`AnimationPlayer` ou tween en code), zéro asset externe.
- Effort : faible. Gain de lisibilité immédiat (on distingue vivant/mort/en mouvement au premier coup d'œil), cohérent avec le style low-poly actuel.

**D2 — Modèles riggés avec animation squelettique (qualité finale visée)**
- Remplacer les boîtes par des modèles low-poly gratuits déjà riggés (Quaternius propose des packs personnages CC0 avec squelette + animations marche/idle incluses) ou un modèle modélisé/riggé sous Blender.
- Si modèle custom : rig sous Blender (gratuit) puis animation manuelle, ou passage par Mixamo (gratuit) pour un rig humanoïde auto + bibliothèque d'animations prêtes (marche, idle, mort).
- Export glTF vers Godot, lecture via `AnimationPlayer`/`AnimationTree`.
- Point d'attention : la mort actuelle est gérée par code (`rotation_degrees.z = 90.0` dans `character.gd`) — à remplacer par une animation dédiée une fois le rig en place.
- Effort : moyen à élevé selon le niveau de détail visé (packs prêts à l'emploi = effort moyen ; modèle+rig custom = effort élevé).

### E — Ressources interactives (ronces/mûres)
- Remplacer la sphère pleine/vide par un modèle de buisson bas-poly avec mûres visibles (pack nature CC0 ou modélisation rapide Blender).
- La logique plein/vide (`ronce.gd`, `full_mat`/`empty_mat`) reste inchangée — seul le visuel change.
- Effort : faible.

### F — UI
- Pas de scène `.tscn` dédiée trouvée pour l'UI (construite par code dans `ui_manager.gd`, non auditée visuellement ici). À reprendre dans une passe dédiée une fois le rendu 3D stabilisé, pour garder une cohérence esthétique globale.

## Trajectoire suggérée

1. **A** seule change déjà radicalement la perception du rendu, sans aucun asset externe — à valider en premier avant d'investir dans des assets.
2. **B + E** : diversification visuelle à faible effort, toujours sans dépendance lourde.
3. **D1** : animation procédurale sur la géométrie actuelle — faible effort, gain de lisibilité fort, ne bloque rien de la suite.
4. **C** : terrain et décor, plus structurant, impacte le déplacement des personnages.
5. **D2** : passage à des modèles riggés avec animation squelettique — le plus coûteux, à faire une fois le reste stabilisé pour ne pas re-brancher deux fois le rig sur des mécaniques encore mouvantes (faim/mort/déplacement).

## Outils gratuits identifiés
- Godot natif : `WorldEnvironment`, `ProceduralSkyMaterial`, SSAO/SSR/glow, shader triplanar, `AnimationPlayer`/`AnimationTree`.
- Poly Haven (texture PBR + HDRI, CC0).
- Kenney.nl / Quaternius (packs low-poly nature/personnages riggés, CC0).
- Blender (modélisation + rig, gratuit, export glTF natif vers Godot).
- Mixamo (rig humanoïde auto + bibliothèque d'animations, gratuit).
- Terrain3D (plugin Godot open source, terrain avec relief).
