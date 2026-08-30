# Journal des décisions d'évolution

Archive des décisions de modification du projet (comportement, mécaniques, paramètres).
Une décision est notée dès qu'elle est prise, avec le statut `proposé`. Elle passe à
`validé` ou `invalidé` après observation, avec un commentaire expliquant le choix.

| Date | Décision | Statut | Détail |
|------|----------|--------|--------|
| 2026-08-16 | Déplacement des personnages sur toute la map + rebond aux collisions | validé | [detail](2026-08-16_deplacement-map-complete-rebond.md) |
| 2026-08-16 | Agrandissement map x4, 4 personnages/4 zones conservés | validé | [detail](2026-08-16_agrandissement-map-x4.md) |
| 2026-08-16 | Menu bas, panneaux persos par coin, focus caméra au clic | validé | [detail](2026-08-16_menu-persos-camera.md) |
| 2026-08-17 | Vitesse de simulation globale, faim/vieillissement/mort, reset complet | validé | [detail](2026-08-17_simulation-vitesse-faim-mort.md) |
| 2026-08-17 | Ronces à mûres, cueillette/consommation automatiques, modale Données du jeu | proposé | [detail](2026-08-17_ronces-mures-donnees-jeu.md) |
| 2026-08-17 | Mode headless + skills d'analyse/expérimentation | proposé | [detail](2026-08-17_experimentation-headless.md) |
| 2026-08-17 | Levée de la contrainte "personnages sans animation" | validé | [detail](2026-08-17_animation-personnages.md) |
| 2026-08-17 | Relief procédural par code plutôt que le plugin Terrain3D (Phase 4) | validé | [detail](2026-08-17_terrain-relief-procedural.md) |
| 2026-08-17 | Cycle caméra 3 clics sur le nom (3e personne / 1re personne / retour) | proposé | [detail](2026-08-17_camera-cycle-3clics.md) |
| 2026-08-18 | Personnage de test contrôlable manuellement (mode dev), remplace F1-F4 seul | validé | [detail](2026-08-18_personnage-test-controlable.md) |
| 2026-08-18 | Personnage riggé (Phase 5, Blender custom) branché uniquement sur le personnage de test | validé | [detail](2026-08-18_personnage-rigge-perso-test.md) |
| 2026-08-22 | Refonte visuelle des ronces : buisson vert fixe + mûres noires visibles (retrait à la cueillette) | validé | [detail](2026-08-22_ronces-mures-visuelles.md) |
| 2026-08-23 | Le rig Blender reste limité au personnage de développement | validé | [detail](2026-08-23_rig-limite-personnage-dev.md) |
| 2026-08-24 | Durée simulée déterministe et état initial séparé | validé | [detail](2026-08-24_experiment-config-deterministe.md) |
| 2026-08-25 | Inspecteur générique (piloté par le registre) remplace les sliders dupliqués des panneaux de coin | validé | [detail](2026-08-25_inspecteur-generique-phase5.md) |
| 2026-08-25 | Phase 6 : communication (partage inconditionnel), coopération (partage de nourriture si faim critique), agressivité (répulsion imposée) | validé | [detail](2026-08-25_phase6-mecaniques-sociales-avancees.md) |
| 2026-08-26 | Phase 7 : décideurs interchangeables (automate de référence / LLM Ollama local), repli automatique sur erreur | proposé | [detail](2026-08-26_decideurs-interchangeables-llm.md) |
| 2026-08-27 | Phase 8 : vision générique (portée/angle/occlusion), `social_radius` absorbé comme cas particulier | validé | [detail](2026-08-27_phase8-vision-perception.md) |
| 2026-08-29 | Correction du seuil de recherche de nourriture (automate et mock LLM) ; révèle l'absence de condition de sortie d'un objectif atteint | proposé | [detail](2026-08-29_correction-seuil-recherche-nourriture.md) |
| 2026-08-29 | Décideur adaptatif : l'action choisie est tenue pendant un intervalle de décision | proposé | [detail](2026-08-29_engagement-decision-adaptatif.md) |
| 2026-08-30 | Apprentissage intra-vie sur la faim (Phases 3-4) : gate franchi sur un seed, mais l'effet ne généralise pas sur deux seeds (avantage ~0,05 de reward, s'inverse) ; `learning_rate` sans levier — discrétisation probablement trop grossière | proposé | [detail](2026-08-30_apprentissage-intra-vie-faim.md) |
