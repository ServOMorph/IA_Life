# Signals — ia_life (MAJ 2026-09-07)

## Actions ouvertes

- [P1|ouvert] Engager la Phase 3 de l'environnement apprenable v3 : calibration sur seeds
  d'entraînement (grille zones × rayon × coût de faim, 5 bras × 12 seeds, `--jobs`/`--retries`).
  fait quand: le gate causal Phase 3 (4 critères écrits) est franchi et le meilleur candidat est
  classé par séparation des politiques.
  réf: `roadmap_environnement_apprenable_v3.md` (Phase 3).
- [P3|dormant] Axe apprentissage v2 toujours suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT], gate réservé Phase 4 passé, puis bandeau v2 amendé.
  réf: `roadmap_environnement_apprenable_v3.md` (condition de déblocage),
  `roadmap_apprentissage_v2.md` (bandeau en tête).

## Contexte chaud

- `roadmap_environnement_apprenable_v3.md` : Phases 0-2 [FAIT]. Perception du danger raccordée à
  `_perceive` (`danger_zone.gd::get_perception_type/get_perception_state`) ; `character.gd` calcule
  `danger_response_direction` en priorisant la zone physiquement active sur la zone seulement
  visible (couvre le cas « zone déjà occupée ») ; `fixed_policy_decider.gd` applique la surcouche
  `fixed_policy_danger = ignorer|eviter|viser` sans toucher à la politique alimentaire hors danger.
  Événement scripté `teleport_agent` ajouté (`experiment_config.gd`/`main.gd`). Gate causal vérifié
  sur `experiments/danger_zone_fixed_policy_scenario_v1.json` (seed 2) : exposition eviter 0,75 s <
  ignorer 1,73/1,47 s < viser 11,98 s, reproductible. Séquence `danger_enter`/`danger_exposure`/
  `danger_exit` couverte en headless par `experiments/danger_zone_scripted_events_v1.json`. Aucune
  régression sur l'oracle Phase 1 (`p1_fixed_policy_selftest.json` via `check_fixed_policy.py` —
  attention au timeout par défaut 200s, marginal pour cette config à `game_speed=1` ; relancer avec
  `--timeout 260` si échec par timeout). Prochaine étape = Phase 3 (calibration).
- Outillage de test fenêtré v3 : `run_danger_windowed.py` (Godot fenêtré + dev mode +
  `experiments/danger_zone_windowed_v1.json`, 12 zones, pas d'auto-quit) ; autoload `DevState`
  (`scripts/dev_state.gd`) qui porte les overrides seed / `danger_zone_count` à travers
  `reload_current_scene()` ; panneau dev enrichi (lignes « Seed » et « Zones dangereuses » +
  boutons Relancer, bouton « tuer le perso de test », raccourcis en grille groupée).
- Fenêtres Godot de ce projet : à lancer sur le bureau virtuel Windows « IA_Life »
  (`.claude/memory.md`). Le script ne force pas le bureau lui-même.
- Analyse v3 : les ronciers v2 sont homogènes, aucune direction n'a de coût causal stable. Le
  reward adaptatif ne mesure pas la perte de faim : un danger exigera une pénalité événementielle
  explicite, mais seulement après validation de l'oracle fixe (Phase 5 v3).
- `roadmap_apprentissage_v2.md` : Phases 0-3 [FAIT], Phases 4-6 [NON ENGAGÉE]. Bandeau
  « AXE SUSPENDU » en tête. Ne pas relancer M2 v2 / M3 / Phases 4-6 avant le gate v3 réservé.
- Deux environnements gelés coexistent :
  - `experiments/apprentissage_env_ref.json` (v1 : `hunger` 0,7, `eat_hunger_threshold` défaut 50).
  - `experiments/apprentissage_env_ref_v2.json` (v2 : `hunger` 0,9, `eat_hunger_threshold` 90,
    supprime le tampon de digestion). Rupture M0 v1 → Mf v1 assumée.
- `politique_fixe_max_v1` dépend de l'environnement : `pf_er_rm` sur v1 (0,83), `pf_rm_er` sur
  v2 (0,58). `pf_rv_rm` ≡ `automate` bit à bit (les deux environnements).
- Vie médiane inutilisable comme métrique de résultat sur v2 : saturée à 300 dès que
  survie ≥ 0,5. Seules survie et mûres mangées discriminent.
- `results/` gitignoré. `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) —
  contourné par `--retries`.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée (`.claude/memory.md`).
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 17e confirmation.
- `scripts/adaptive_decider_v1.gd` : ne pas supprimer tant que la suspension n'est pas définitive.
- `AGENTS.md` / `GEMINI.md` : modifiés hors session (réalignement `.claude/CLAUDE.md`), toujours en
  résidus non commités — à revoir/committer à part, hors périmètre de cette session.

## Dernière session (2026-09-07)

# Session du 2026-09-07

## Décisions prises
- Phase 2 de `roadmap_environnement_apprenable_v3.md` close : perception du danger raccordée à
  `_perceive`, décideur `fixed_policy_danger` (ignorer/eviter/viser) en surcouche isolée de la
  politique alimentaire.

## Livrables produits ou modifiés
- Modifiés : `scripts/character.gd`, `danger_zone.gd`, `fixed_policy_decider.gd`, `main.gd`,
  `experiment_config.gd`, `variable_registry.gd`, `tools/run_manual_checks.gd` (12 tests ajoutés).
- Créés : `experiments/danger_zone_scripted_events_v1.json`,
  `experiments/danger_zone_fixed_policy_scenario_v1.json`.

## Hypothèses validées / invalidées
- VALIDE : `eviter` réduit l'exposition (0,75 s), `ignorer` neutre (1,73/1,47 s), `viser`
  l'augmente (11,98 s) — gate causal franchi, reproductible (seed 2).
- VALIDE : aucun aléa supplémentaire consommé à la décision ; aucune régression sur l'oracle
  Phase 1 (`check_fixed_policy.py` vert).

## Prochaine étape exacte
Phase 3 : calibration sur seeds d'entraînement (grille zones × rayon × coût de faim, 5 bras ×
12 seeds).

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
