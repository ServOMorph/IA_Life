# Signals — ia_life (MAJ 2026-10-02)

## Actions ouvertes

- [P1|ouvert] Valider ou remplacer le critère de succès de la Phase 5 (proposé par l'assistant, non co-défini) avant d'exploiter le résultat.
  fait quand: l'utilisateur a validé ou remplacé `experiments/llm_survie_critere_v1.md` et le rapport est relu en conséquence.
  réf: `experiments/llm_survie_critere_v1.md`, `experiments/llm_survie_rapport_v1.md`, `tools/analyze_llm_survie.py`.
- [P2|ouvert] Démonstration fenêtrée de la survie pilotée par LLM (Phase 4) sur le bureau virtuel IA_Life, y compris le chat LLM repliable et le filtre des bords connus.
  fait quand: les contrôles de la section Phase 4 et de la section Chat LLM / carte de `tests_manuels.md` sont validés et les sections supprimées.
  réf: `tests_manuels.md`, `run_survie_demo.py`, `experiments/llm_survie_v1.json`.
- [P2|ouvert] Instruire les 5 échecs préexistants « Phase 8 vision » de `tools/run_manual_checks.gd` (`_test_vision_memorization`, `_test_vision_memory_capacity_no_churn`) : présents sans les changements de cette session, cause non instruite (possible lien avec `scripts/main.gd` modifié hors session).
  fait quand: la cause est identifiée et la suite complète est verte, ou l'écart est consigné comme connu.
  réf: `tools/run_manual_checks.gd` (autour de la ligne 179), `git diff scripts/main.gd`.
- [P3|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; `scripts/check_kit.py` absent, écart connu consigné aux clôtures du 2026-09-30, 2026-10-01 et 2026-10-02.
- [P3|ouvert] `python tools/run_manual_checks.py` renvoie le code 1 sans sortie ; contournement : lancer Godot directement (`D:/Godot/godot.exe --headless --path . --scene tools/manual_checks.tscn`).
  fait quand: le wrapper affiche la sortie de la suite et le bon code retour.
  réf: `tools/run_manual_checks.py`.
- [P4|dormant] Usage stratégique de la carte `llm_survie` (bords, zones explorées) : repoussé par l'utilisateur à plus tard.
  fait quand: une décision définit comment la carte entre dans la stratégie (prompt ou moteur) et une campagne la mesure.
  réf: `scripts/llm_survie_ollama_backend.gd` (`map_lines`), `_docs/decisions/2026-10-02_memoire-cartographique-llm-survie.md`.
- [P4|dormant] Axe apprentissage T3 en pause : décider d'un contrat de confirmation v2 ou de l'arrêt.
  fait quand: un contrat v2 est gelé (nouvelles cartes et graines, solvabilité sur échantillon dédié, seuil 0,60 tranché) ou l'arrêt est consigné.
  réf: `_docs/decisions/2026-09-30_t3-v3-confirmation-critere-non-atteint.md`, `experiments/apprentissage_t3_confirmation_contrat_v1.md`.
- [P4|dormant] Démonstration fenêtrée du décideur `politique_apprise` sur le bureau virtuel IA_Life.
  fait quand: les 4 contrôles de la section Phase 5 de `tests_manuels.md` sont validés et la section supprimée.
  réf: `tests_manuels.md`, `run_applied_demo.py`, `experiments/t3_applied_demo_v1.json`.
- [P4|dormant] Axe danger v3 en pause : finaliser ou écarter le candidat de contournement.
  fait quand: une décision relance ou clôt l'axe danger, avec un candidat et une campagne documentés si relancé.
  réf: `roadmap_environnement_apprenable_v3.md`, `scripts/danger_detour.gd`, `_docs/decisions/2026-09-10_contournement-stateful.md`.

## Contexte chaud

- Mémoire cartographique `llm_survie` révisée : le prompt est identique à la v1 (carte retirée), la découverte d'un bord ne déclenche plus de tour, seules les directions « bord » sont exclues du schéma Ollama (`excluded_directions`). Variable `llm_survie_map_memory` (défaut actif) ; une comparaison stricte avec la Phase 5 exige `llm_survie_map_memory: false`.
- Banc `tools/check_llm_survie_map_usage.gd` sans objet (carte hors prompt), non supprimé.
- Suite `tools/run_manual_checks.gd` : seuls les 5 échecs Phase 8 vision préexistants subsistent.
- Roadmap `roadmap_survie_llm.md` exécutée en entier (Phases 0 à 5), résultat : vie moyenne automate 292 s, `llm_survie` 542 s (6 cartes, x1, `--jobs 1`), 0 repli ; critère non validé.
- Ollama doit être lancé (`ollama serve`, relancé en fin de session, limite 2 h) pour la démonstration et les campagnes `llm_survie`.
- Working tree hors session non commité : `.claude/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.claude/commands/roberto.md` supprimé, `ROBERTO/com_telephone/*`, logs `experiments/t0_v3_results.jsonl.workers/`, `.uid` divers.

## Dernière session (2026-10-02)

# Session du 2026-10-02

## Décisions prises
- La carte de `llm_survie` ne sert qu'à retirer du choix d'explorer les directions menant à un bord connu ; aucune influence stratégique, prompt identique à la v1, usage stratégique reporté.

## Livrables produits ou modifiés
- `scripts/llm_survie_ollama_backend.gd`, `llm_survie_engine.gd`, `variable_registry.gd` : modifiés (exclusion des directions bord, prompt sans carte, plus de tour sur bord).
- `tools/run_manual_checks.gd` : tests adaptés et ajoutés (suite : seuls 5 échecs vision préexistants).
- `_docs/decisions/2026-10-02_memoire-cartographique-llm-survie.md`, `INDEX.md` : décision révisée, validée.

## Hypothèses validées / invalidées
- VALIDE : exclusion des directions bord garantie par construction, prompt identique avec ou sans carte (tests automatiques).
- INVALIDE : le banc d'usage n'a plus d'objet ; l'idée d'injecter la carte dans le prompt est abandonnée pour l'instant.
- EN ATTENTE : effet de l'exclusion sur la survie (aucune campagne) ; 5 échecs vision préexistants non instruits ; critère Phase 5 non validé.

## Prochaine étape exacte
Valider ou remplacer le critère Phase 5, puis instruire les échecs vision avant toute campagne `llm_survie`.

## Question bloquante pour la session suivante
Aucune
