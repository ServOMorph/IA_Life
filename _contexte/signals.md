# Signals — ia_life (MAJ 2026-09-06)

## Actions ouvertes

- [P1|ouvert] Engager la Phase 2 de l'environnement apprenable v3 : raccorder les zones à
  `_perceive`, décideur `fixed_policy_danger = ignorer|eviter|viser` en surcouche, config smoke à
  `events` scriptés, gate sur scénario scripté.
  fait quand: le gate Phase 2 est vérifié (eviter réduit l'exposition, viser l'augmente, ignorer
  inchangé ; aucun aléa consommé à la décision) et les livrables sont versionnés.
  réf: `roadmap_environnement_apprenable_v3.md` (Phase 2).
- [P3|dormant] Axe apprentissage v2 toujours suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT], gate réservé Phase 4 passé, puis bandeau v2 amendé.
  réf: `roadmap_environnement_apprenable_v3.md` (condition de déblocage),
  `roadmap_apprentissage_v2.md` (bandeau en tête).

## Contexte chaud

- `roadmap_environnement_apprenable_v3.md` : Phases 0-1 [FAIT]. Mécanique de zones dangereuses
  opérationnelle : placement déterministe (RNG dédié `seed + 7919`, 64 essais), télémétrie
  `danger_placement|danger_enter|danger_exposure|danger_exit` (`category` = nom de l'événement),
  coût de faim au temps simulé = taux max × durée (jamais somme sur chevauchement). Validée en
  headless (`run_manual_checks`, `check_telemetry.py`, `check_reproducibility.py` sur
  `danger_zone_smoke_v1.json`) et en fenêtré. Prochaine étape = Phase 2.
- Outillage de test fenêtré v3 : `run_danger_windowed.py` (Godot fenêtré + dev mode +
  `experiments/danger_zone_windowed_v1.json`, 12 zones, pas d'auto-quit) ; autoload `DevState`
  (`scripts/dev_state.gd`) qui porte les overrides seed / `danger_zone_count` à travers
  `reload_current_scene()` ; panneau dev enrichi (lignes « Seed » et « Zones dangereuses » +
  boutons Relancer, bouton « tuer le perso de test », raccourcis en grille groupée).
- Fenêtres Godot de ce projet : à lancer sur le bureau virtuel Windows « IA_Life »
  (`.claude/memory.md`). Le script ne force pas le bureau lui-même.
- `scripts/character.gd` : `AnimationPlayer.speed_scale` désormais indexé sur `GameSpeed.time_scale`
  (le perso de test « glissait » à `game_speed > 1`, anim non accélérée). Corrigé et validé.
- `tests_manuels.md` vidé : tests ROBERTO multi-projet validés au téléphone ; 4 tests zones
  dangereuses (rendu, placement, exposition, désactivation stricte) tous verts.
- Analyse v3 : les ronciers v2 sont homogènes, aucune direction n'a de coût causal stable. Le
  reward adaptatif ne mesure pas la perte de faim : un danger exigera une pénalité événementielle
  explicite, mais seulement après validation de l'oracle fixe (Phase 5 v3).
- `roadmap_apprentissage_v2.md` : Phases 0-3 [FAIT], Phases 4-6 [NON ENGAGÉE]. Bandeau
  « AXE SUSPENDU » en tête. Ne pas relancer M2 v2 / M3 / Phases 4-6 avant le gate v3 réservé.
- Résultat de suspension (M1 v2, env enrichi v2, 12 seeds) : `adaptatif_courant` survie 0,67 /
  mûres 12,9 = meilleur bras en agrégat, mais apparié au seed : 4-3/12 survie et 4-6/12 mûres
  vs `aleatoire` (0,58) ; 3-1/12 (8 nuls) vs `adaptatif_v1` (0,50). Non-séparable. `automate`
  s'effondre à 0,08 sur env v2.
- Deux environnements gelés coexistent :
  - `experiments/apprentissage_env_ref.json` (v1 : `hunger` 0,7, `eat_hunger_threshold` défaut 50).
  - `experiments/apprentissage_env_ref_v2.json` (v2 : `hunger` 0,9, `eat_hunger_threshold` 90,
    supprime le tampon de digestion). Rupture M0 v1 → Mf v1 assumée.
- Code Phases 2-3 apprentissage conservé et testé : `scripts/adaptive_decider.gd` (récompense
  événementielle +1/cueillette −c·Δt −1 terminal, amorçage TD γ 0,9, S3 = 5 actions, S2 +
  `souvenir_ancien`, `TABLE_SCHEMA_VERSION` `phase3-actions-1`). `tools/run_manual_checks.gd` :
  `SUCCÈS`.
- `politique_fixe_max_v1` dépend de l'environnement : `pf_er_rm` sur v1 (0,83), `pf_rm_er` sur
  v2 (0,58). `pf_rv_rm` ≡ `automate` bit à bit (les deux environnements).
- Vie médiane inutilisable comme métrique de résultat sur v2 : saturée à 300 dès que
  survie ≥ 0,5. Seules survie et mûres mangées discriminent.
- `results/` gitignoré. `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) —
  contourné par `--retries`.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée (`.claude/memory.md`).
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 16e confirmation.
- `scripts/adaptive_decider_v1.gd` : ne pas supprimer tant que la suspension n'est pas définitive.
- `roadmap_apprentissage.md` close archivée dans `_docs/archives/roadmap_apprentissage.md`.
- `AGENTS.md` / `GEMINI.md` : réalignés sur `.claude/CLAUDE.md` hors session (probable `/update`) —
  laissés en résidus non commités, à revoir/committer à part.

## Dernière session (2026-09-06)

# Session du 2026-09-06

## Décisions prises
- Phase 1 de `roadmap_environnement_apprenable_v3.md` close : mécanique de zones dangereuses
  (placement déterministe, télémétrie `danger_*`, coût de faim au temps simulé) validée headless
  et fenêtré. Gate complet franchi.
- Outillage de test fenêtré v3 retenu : `run_danger_windowed.py`, autoload `DevState`, panneau
  dev enrichi.

## Livrables produits ou modifiés
- Lot Phases 0-1 v3 (préexistant) commité : `scripts/danger_zone.gd`, `danger_zone_contract.gd`,
  `experiments/danger_zone_{contract_v1.md,oracle_base_v1.json,smoke_v1.json}`,
  `campaigns/danger_zone_oracle_v3.json`, + modifs `character/main/game_config/variable_registry/
  aggregate_results/check_telemetry/run_manual_checks`.
- Créés : `scripts/dev_state.gd`, `run_danger_windowed.py`, `experiments/danger_zone_windowed_v1.json`.
- Modifiés : `scripts/ui_manager.gd` (panneau dev), `scripts/main.gd` (overrides `DevState`),
  `project.godot` (autoload), `scripts/character.gd` (`speed_scale`), `tests_manuels.md` (vidé),
  `experiments/danger_zone_contract_v1.md` (schéma `category`), `.claude/memory.md` (note bureau).

## Hypothèses validées / invalidées
- VALIDE : zones dangereuses rendues (disques rouges), placées hors décor, `danger_enter`/
  `danger_exposure`/`danger_exit` avec coût = taux × durée, arrêt à la sortie ;
  `danger_zone_count: 0` désactive strictement (0 géométrie, 0 événement).
- VALIDE : à `game_speed > 1` l'anim de marche « glissait » (speed_scale non indexé). Corrigé.
- EN ATTENTE : une politique d'évitement bat-elle le hasard sur la tâche v3 ? (Phases 2-4)

## Prochaine étape exacte
Phase 2 de `roadmap_environnement_apprenable_v3.md` : perception `_perceive` des zones, décideur
`fixed_policy_danger` en surcouche, config smoke à `events` scriptés, gate sur scénario scripté.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
