# Signals — design   (MAJ 2026-08-17)

## Actions ouvertes
- [P1|ouvert] Réaliser la Phase 1 de la roadmap graphisme (lumière et post-traitement) — fait quand: WorldEnvironment + post-processing (SSAO/SSR/glow/tonemap/AA) implémentés et test manuel validé — réf: DESIGN/roadmap_graphisme.md (Phase 1), scripts/main.gd (_build_light)

## Dernière session (2026-08-17)
<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
# Session du 2026-08-17

## Décisions prises
- Autorisation permanente de l'agent design à lire/modifier des fichiers hors DESIGN/ dès lors qu'ils concernent le design du jeu.
- Levée de la contrainte "personnages sans animation" — animation (marche/idle a minima) intégrée au plan.
- Trajectoire graphisme validée : A (lumière/post-traitement) → B+E (matériaux PBR/ronces) → D1 (animation procédurale) → C (terrain/décor) → D2 (personnages riggés) → écriture roadmap suivante.

## Livrables produits ou modifiés
- DESIGN/pistes_graphisme.md : créé, 6 pistes détaillées avec outils gratuits.
- DESIGN/roadmap_graphisme.md : créé, 6 phases, Phase 1 en cours.
- DESIGN/_contexte/contexte.md : contrainte animation mise à jour, décisions ajoutées.
- .claude/memory.md : entrée autorisation hors DESIGN/.

## Hypothèses validées / invalidées
- VALIDE : le rendu actuel sous-exploite le renderer Forward+ (pas de WorldEnvironment, matériaux plats, aucun post-processing).
- VALIDE : animation nécessaire — décision utilisateur explicite, contrainte initiale levée.
- EN ATTENTE : Phase 1 de la roadmap non commencée en code.

## Prochaine étape exacte
Démarrer la Phase 1 : WorldEnvironment + ProceduralSkyMaterial + post-processing (SSAO/SSR/glow/tonemap/AA) + ombres douces sur la DirectionalLight3D.

## Question bloquante pour la session suivante
Aucune.
