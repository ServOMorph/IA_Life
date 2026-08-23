# Signals — ia_life   (MAJ 2026-08-23)

## Actions ouvertes
- [P1|ouvert] Décider si le personnage riggé (Phase 5, `assets/models/character.glb`) doit
  être étendu aux 4 personnages normaux ou rester un outil de test.
  fait quand: décision prise avec l'utilisateur
  réf: `_docs/decisions/2026-08-18_personnage-rigge-perso-test.md`,
  `DESIGN/roadmap_graphisme.md` (Phase 5)

## Contexte chaud
- Zone `design` (`DESIGN/roadmap_graphisme.md`) : Phase 5 avancée et validée (rig +
  animations sur le personnage de test) dans une session sans passer par `/close design`
  — penser à clore cette zone séparément (`_contexte/signals.md` de design encore sur
  l'état antérieur ; fichiers DESIGN/ modifiés non commités : signals.md et
  roadmap_graphisme.md, à valider lors de la clôture de la zone design).
- Blender installé localement (`D:\blender`, via winget) pour permettre la régénération du
  modèle riggé sans dépendance à un poste tiers.
- Dossier `_docs/Analyse du projet/` : non suivi par git, origine hors de cette session,
  laissé de côté.
- Refonte visuelle des ronces faite en session (buisson vert + mûres noires) — validation
  visuelle globale du rendu confirmée (test 15 validé le 2026-08-23 ; voir
  `_docs/decisions/2026-08-22_ronces-mures-visuelles.md`).

## Dernière session (2026-08-23)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-23

## Décisions prises
- Roadmap du mode dev terminée et archivée ; les tests de paramètres/mémoire sont automatisés.
- La touche E du personnage de test ramasse désormais une mûre proche ; le log temporaire de déplacement est retiré.

## Livrables produits ou modifiés
- `tools/run_manual_checks.py` : lance les vérifications automatisées 6, 8, 9, 10 et 11.
- `scripts/character.gd`, `scripts/main.gd`, `scripts/ui_manager.gd` : cueillette manuelle E en mode dev.
- `tests_manuels.md` : tests validés retirés ; aucune attente restante.
- `_docs/archives/2026-08-23_roadmap_mode-dev.md` : roadmap clôturée et archivée.

## Hypothèses validées / invalidées
- VALIDE : navigation/mémoire, oubli, remplacement du souvenir faible et slider Mémoire.
- VALIDE : rendu ronces/mûres et correction visuelle de l'enfoncement des personnages.

## Prochaine étape exacte
Décider si le personnage riggé de test doit être étendu aux quatre personnages normaux.

## Question bloquante pour la session suivante
Le personnage riggé doit-il rester limité au mode dev ?
