# Signals — ia_life (MAJ 2026-09-01)

## Actions ouvertes

- [P1|ouvert] Engager la Phase 0 de l'environnement apprenable v3 : spécification des zones
  dangereuses, schéma de télémétrie, compatibilité zéro danger et verrouillage des 24 seeds.
  fait quand: le gate de la Phase 0 est vérifié et les fichiers de campagne sont versionnés.
  réf: `roadmap_environnement_apprenable_v3.md` (Phase 0),
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
- [P3|dormant] Axe apprentissage v2 toujours suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT], gate réservé Phase 4 passé, puis bandeau v2 amendé.
  réf: `roadmap_environnement_apprenable_v3.md` (condition de déblocage),
  `roadmap_apprentissage_v2.md` (bandeau en tête).

## Contexte chaud

- `roadmap_environnement_apprenable_v3.md` [PLANIFIÉE] : zones dangereuses localisées avec coût
  de faim, oracle `eviter|ignorer|viser`, calibration 12 seeds + confirmation 12 réservés.
  Mécanique non implémentée ; Phase 0 est la prochaine étape.
- Analyse v3 : les ronciers actuels sont homogènes et aucune direction n'a de coût causal stable.
  Le reward adaptatif ne mesure pas la perte de faim : un danger exigera une pénalité
  événementielle explicite, mais seulement après validation de l'oracle fixe.
- `roadmap_apprentissage_v2.md` : Phases 0-3 [FAIT], Phases 4-6 [NON ENGAGÉE]. Bandeau
  « AXE SUSPENDU » en tête. Ne pas relancer M2 v2 / M3 / Phases 4-6 avant le gate v3 réservé.
- Résultat de suspension (M1 v2, env enrichi v2, 12 seeds) : `adaptatif_courant` survie 0,67 /
  mûres 12,9 = meilleur bras en agrégat, mais apparié au seed : 4-3/12 survie et 4-6/12 mûres
  vs `aleatoire` (0,58) ; 3-1/12 (8 nuls) vs `adaptatif_v1` (0,50). Non-séparable. `automate`
  s'effondre à 0,08 sur env v2.
- Deux environnements gelés coexistent :
  - `experiments/apprentissage_env_ref.json` (v1 : `hunger` 0,7, `eat_hunger_threshold` défaut
    50) — M0 v1 / M1 v1 (`results/_benchmark_apprentissage_m0`, `_m1`).
  - `experiments/apprentissage_env_ref_v2.json` (v2 : `hunger` 0,9, `eat_hunger_threshold` 90,
    supprime le tampon de digestion) — M0 v2 / M1 v2. Rupture M0 v1 → Mf v1 assumée.
- Code Phases 2-3 conservé et testé : `scripts/adaptive_decider.gd` (récompense événementielle
  +1/cueillette −c·Δt −1 terminal, amorçage TD γ 0,9, S3 = 5 actions, S2 + `souvenir_ancien`,
  `TABLE_SCHEMA_VERSION` `phase3-actions-1`). `tools/run_manual_checks.gd` : `SUCCÈS`.
- `politique_fixe_max_v1` dépend de l'environnement : `pf_er_rm` sur v1 (0,83), `pf_rm_er` sur
  v2 (0,58). `pf_rv_rm` ≡ `automate` bit à bit (les deux environnements).
- Vie médiane inutilisable comme métrique de résultat sur v2 : saturée à 300 dès que
  survie ≥ 0,5. Seules survie et mûres mangées discriminent.
- `results/` gitignoré. Dossiers de cette session conservés : `_p3_oracle`, `_p3b_env_probe`,
  `_benchmark_apprentissage_m0_v2`, `_benchmark_apprentissage_m1_v2`.
- `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) — contourné par `--retries`.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée (`.claude/memory.md`).
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 15e confirmation.
- `scripts/adaptive_decider_v1.gd` : ne pas supprimer tant que la suspension n'est pas définitive
  (la roadmap prévoyait sa suppression à la clôture).
- `roadmap_apprentissage.md` close archivée dans `_docs/archives/roadmap_apprentissage.md`.

## Dernière session (2026-09-01)

# Session du 2026-09-01

## Décisions prises
- Zones dangereuses localisées retenues comme préalable expérimental ; la v2 reste suspendue
  jusqu'à validation d'un oracle fixe sur 12 seeds réservés.

## Livrables produits ou modifiés
- `roadmap_environnement_apprenable_v3.md` : plan en 6 phases avec gates causaux et réservés.
- `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md` + INDEX.
- `roadmap_apprentissage.md` déplacée dans `_docs/archives/` ; résidus temporaires supprimés.

## Hypothèses validées / invalidées
- VALIDE : le monde v2 n'offre aucun coût spatial stable et le hasard reste près du plafond utile.
- INVALIDE : une perte de faim due au danger serait apprise avec le reward actuel ; elle exige un
  événement négatif explicite après validation de l'oracle.
- EN ATTENTE : une politique d'évitement bat-elle le hasard sur la tâche v3 ?

## Prochaine étape exacte
Exécuter la Phase 0 de `roadmap_environnement_apprenable_v3.md`. Ne pas modifier le learner.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
