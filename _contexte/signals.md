# Signals — ia_life (MAJ 2026-10-09, clôture)

## Actions ouvertes

- [P2|ouvert] Démonstration fenêtrée sur le bureau virtuel IA_Life : survie pilotée par LLM (Phase 4), chat LLM repliable, filtre des bords connus, et contrôles visuels Observatoire (phases 1 et 2).
  fait quand: les sections Phase 4, Chat LLM / carte et DESIGN Observatoire (phases 1 et 2) de `tests_manuels.md` sont validées et supprimées.
  réf: `tests_manuels.md`, `run_survie_demo.py`, `experiments/llm_survie_v1.json`.
- [P3|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10), `scripts/check_kit.py` absent.
- [P4|dormant] Usage stratégique de la carte `llm_survie` (bords, zones explorées) : repoussé par l'utilisateur à plus tard.
  fait quand: une décision définit comment la carte entre dans la stratégie (prompt ou moteur) et une campagne la mesure.
  réf: `scripts/llm_survie_ollama_backend.gd`, `_docs/decisions/2026-10-02_memoire-cartographique-llm-survie.md`.
- [P4|dormant] Axe apprentissage T3 en pause : décider d'un contrat de confirmation v2 ou de l'arrêt.
  fait quand: un contrat v2 est gelé (nouvelles cartes et graines, solvabilité sur échantillon dédié, seuil 0,60 tranché) ou l'arrêt est consigné.
  réf: `_docs/decisions/2026-09-30_t3-v3-confirmation-critere-non-atteint.md`.
- [P4|dormant] Démonstration fenêtrée du décideur `politique_apprise` sur le bureau virtuel IA_Life.
  fait quand: les 4 contrôles de la section Phase 5 de `tests_manuels.md` sont validés et la section supprimée.
  réf: `tests_manuels.md`, `run_applied_demo.py`, `experiments/t3_applied_demo_v1.json`.
- [P4|dormant] Axe danger v3 en pause : finaliser ou écarter le candidat de contournement.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `scripts/danger_detour.gd`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Décors bloquants livrés : `decor_collisions` est activé par défaut ; les campagnes peuvent toujours le surcharger explicitement. Décision et limites : `_docs/decisions/2026-10-03_decor_collisions_gate.md`.
- Les campagnes `llm_survie` avec Ollama doivent tourner en temps réel et à `--jobs 1` : `--fixed-fps 60` provoque des expirations HTTP et des replis artificiels.
- La suite headless se lance par `python tools/run_manual_checks.py` (utilise `godot_console.exe`) ; elle est verte (code 0) au 2026-10-09.
- Working tree hors session non commité : `.claude/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, suppressions `ROBERTO/com_telephone/*`, PDF ROBERTO, journaux T0 et `.uid` divers.

## Dernière session (2026-10-09)

# Session du 2026-10-09

## Décisions prises
- Aucune décision d'évolution du projet.

## Livrables produits ou modifiés
- `tools/run_manual_checks.gd` : `restarted_main.free()` au lieu de `queue_free()` (test 6) ; supprime les 5 échecs Phase 8 vision.
- `tools/run_manual_checks.py` : lance `godot_console.exe` (le wrapper renvoyait le code 1 sans sortie avec `godot.exe`).

## Hypothèses validées / invalidées
- VALIDE : les 5 échecs Phase 8 vision venaient d'un défaut d'isolation des tests (ronciers du `Main` rechargé non libérés), pas du code vision ; suite complète en code 0.
- VALIDE : le wrapper affiche la sortie et le bon code retour.
- EN ATTENTE : contrôles manuels fenêtrés (Phase 4, Chat LLM, Observatoire 1 et 2).

## Prochaine étape exacte
Effectuer les contrôles manuels fenêtrés de `tests_manuels.md` (Ollama actif, bureau virtuel IA_Life).

## Question bloquante pour la session suivante
Aucune
