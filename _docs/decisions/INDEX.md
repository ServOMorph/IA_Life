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
| 2026-08-30 | Apprentissage intra-vie sur la faim (Phases 3-4) : gate franchi sur un seed, mais l'effet ne généralise pas sur deux seeds ; `learning_rate` sans levier. Diagnostic racine : 5 défauts structurels. Suite = `roadmap_apprentissage_v2.md` (approche par étapes, benchmark avant/après) | invalidé | [detail](2026-08-30_apprentissage-intra-vie-faim.md) |
| 2026-08-31 | Calibrage environnement + oracle (Phase 1 v2) : `FixedPolicyDecider`, bras de campagne (`arms`), environnement de référence gelé (`vision` 15 / `hunger` 0,7 / `ronce` 30). Gate franchi à n=12 : `pf_er_rm` 0,83 vs `pf_er_er` 0,17. Bit apprenable = décision S2 (viser souvenir vs errer). `pf_rv_rm` ≡ `automate` ; `aleatoire` meilleur bras (0,92). Mesure M0 prise | proposé | [detail](2026-08-31_calibrage-environnement-oracle.md) |
| 2026-09-01 | Phase 2 v2 — refonte du signal : récompense événementielle (+1 cueillette, coût survie −c·Δt, −1 terminal) + amorçage TD (`Q += α[r + γ·maxQ(s',·) − Q]`, γ 0,9) + versionnage du format de table. Franchit le plateau sans-apprentissage à M1 ; gate « ≥ 9/12 » non atteignable (survie saturée). Mécanisme conservé dans le code | validé | [detail](2026-09-01_phase2-signal-recompense-td.md) |
| 2026-09-01 | Phase 3 (espace d'action S3 ×5 + `souvenir_ancien`) + bifurcation environnement (re-gel v2 : `eat_hunger_threshold` 90, `hunger_depletion_rate` 0,9, rupture M0 v1 assumée) + **suspension de l'axe apprentissage** (branche « Échec » : `adaptatif_courant` ne bat pas `adaptatif_v1` ni la sélection aléatoire au seed apparié, 4-3/12 survie). Code Phases 2-3 conservé ; M2-M5 et Phase 6 non engagées | validé | [detail](2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md) |
| 2026-09-01 | Environnement apprenable v3 : zones dangereuses localisées retenues comme préalable expérimental. La reprise de `roadmap_apprentissage_v2.md` dépend d'un oracle fixe puis d'une confirmation sur 12 seeds réservés ; aucun raccord au learner avant ce gate | validé pour planification | [detail](2026-09-01_environnement-apprenable-v3-zones-dangereuses.md) |
