# Signals — design (MAJ 2026-10-02)

## Actions ouvertes
- [P1] Valider visuellement l'interface et le décor Observatoire, puis retirer chaque contrôle confirmé de la file manuelle — fait quand: les sections DESIGN de `tests_manuels.md` sont vides et les phases 1-2 peuvent être closes ; réf: `DESIGN/roadmap_observatoire.md`, `tests_manuels.md`.
- [P2] Reprendre la phase 3 (personnages et états 3D) après le checkpoint — fait quand: silhouettes et états sont intégrés et testés sans étendre le rig de développement aux agents ordinaires ; réf: `DESIGN/roadmap_observatoire.md`, `.claude/memory.md`.
- [P2] Écart connu à corriger en phase de maintenance du protocole : `scripts/check_kit.py` est introuvable, donc le contrôle d'intégrité de `/close` n'a pas pu être exécuté — fait quand: le script est restauré ou son successeur documenté et le contrôle passe ; réf: `.claude/commands/close.md` (étape 10).

## Contexte chaud
- Le décor compte 108 arbres ; leurs formes de collision existent mais sont désactivées à la demande de l'utilisateur. Le relief a changé : les résultats expérimentaux antérieurs ne sont pas directement comparables.
- Le contrôle de densité des arbres a été confirmé par l'utilisateur ; les autres contrôles visuels restent en attente.
- Contrôle d'intégrité du kit non exécutable : script prescrit introuvable ; écart consigné ci-dessus.

## Dernière session
# Session du 2026-10-02

## Décisions prises
- Direction Observatoire retenue ; décor low-poly CC0, 108 arbres aux collisions désactivées et relief multi-échelle à zones accidentées.

## Livrables produits ou modifiés
- `DESIGN/roadmap_observatoire.md`, chartes et moodboards : nouvelle progression visuelle ; ancienne roadmap archivée.
- `scripts/observatory_style.gd`, `scripts/ui_manager.gd`, polices IBM Plex : identité, repères et états de l'interface.
- `scripts/main.gd`, `scripts/triplanar.gdshader`, modèles Kenney CC0 : décor, mûres ancrées au feuillage et relief revu.
- Tests ciblés du style, du décor et du relief ; contrôles non validés consignés dans `tests_manuels.md`.

## Hypothèses validées / invalidées
- VALIDE : le chargement Godot et les tests automatisés ciblés passent sur l'état courant.
- EN ATTENTE : lisibilité et déplacements sur le terrain en fenêtre ; comparabilité des campagnes historiques rompue par le relief.

## Prochaine étape exacte
Faire les contrôles manuels DESIGN, clore les phases 1-2 seulement après validation, puis reprendre la phase 3 après `/compact` confirmé.

## Question bloquante pour la session suivante
Aucune.
