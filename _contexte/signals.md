# Signals — ia_life (MAJ 2026-10-01)

## Actions ouvertes

- [P1|ouvert] Valider ou remplacer le critère de succès de la Phase 5 (proposé par l'assistant, non co-défini) avant d'exploiter le résultat.
  fait quand: l'utilisateur a validé ou remplacé `experiments/llm_survie_critere_v1.md` et le rapport est relu en conséquence.
  réf: `experiments/llm_survie_critere_v1.md`, `experiments/llm_survie_rapport_v1.md`, `tools/analyze_llm_survie.py`.
- [P2|ouvert] Démonstration fenêtrée de la survie pilotée par LLM (Phase 4) sur le bureau virtuel IA_Life.
  fait quand: les 5 contrôles de la section Phase 4 de `tests_manuels.md` sont validés et la section supprimée.
  réf: `tests_manuels.md`, `run_survie_demo.py`, `experiments/llm_survie_v1.json`.
- [P3|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; `scripts/check_kit.py` absent, écart connu consigné aux clôtures du 2026-09-30 et du 2026-10-01.
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

- Roadmap `roadmap_survie_llm.md` exécutée en entier (Phases 0 à 5), commit `7b3873b6`. Prochaine session : reprise directe de la suite (critère Phase 5, puis évolutions du décideur).
- Résultat Phase 5 (6 cartes, x1, `--jobs 1`, `gemma3:1b`) : vie moyenne automate 292 s, automate cueillette libre 345 s, `llm_survie` 542 s ; `llm_survie` devant l'automate sur 6 cartes sur 6 ; 3 704 tours, 0 repli, 0 refus.
- Réserves : le prompt décrit la stratégie ; la cueillette est libre à tout niveau de faim pour le LLM ; critère non validé ; un seul modèle et une version de prompt ; résultats dépendants du matériel.
- Confort mode dev ajouté : panneau repliable (F6), F1-F4 suivent l'agent à la caméra, marqueurs au-dessus des 5 personnages, lanceurs en fenêtre maximisée.
- Ollama doit être lancé (`ollama serve`) pour la démonstration et les campagnes `llm_survie`.
- Changements du working tree hors session, non commités : `.claude/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.claude/commands/roberto.md` supprimé, `ROBERTO/com_telephone/*`, logs `experiments/t0_v3_results.jsonl.workers/`, `scripts/danger_detour.gd.uid`.
- T3 v3 : confirmation en critère non atteint (7/8) ; cartes finales `410000201..264` consommées ; axe en pause.

## Dernière session (2026-10-01)

# Session du 2026-10-01

## Décisions prises
- Roadmap exécutée sans checkpoints `/compact` ; décideur `llm_survie` livré (cible roncier, actions explicites, tours asynchrones, schéma Ollama `anyOf`).
- Lanceurs fenêtrés en `--maximized` (pas de plein écran réel) ; mode dev : F6 replie le panneau, F1-F4 suivent l'agent à la caméra sans téléportation.

## Livrables produits ou modifiés
- `scripts/llm_survie_*.gd`, `scripts/ronce_memory.gd`, `scripts/character.gd`, `scripts/ronce.gd` : livrés, tests manuels du harnais verts.
- `scripts/main.gd`, `scripts/ui_manager.gd` : F6, F1-F4, marqueurs de localisation ; validés par l'utilisateur en jeu.
- `experiments/llm_survie_*` (contrat, critère, rapport, config, 3 campagnes), `tools/analyze_llm_survie.py` : livrés.
- `roadmap_survie_llm.md` : Phases 0 à 5 [FAIT].

## Hypothèses validées / invalidées
- VALIDE : `gemma3:1b` pilote 4 agents sans repli ni refus, avec un prompt strict ; vie moyenne 542 s contre 292 s (automate), 6/6 cartes.
- INVALIDE : prompt libre (réponse figée sur `manger`, puis `explorer` seul) -> pivot vers actions légales listées, schéma `anyOf`, directions et cibles bloquées exclues.
- EN ATTENTE : critère de succès Phase 5 non validé par l'utilisateur ; gain attribuable en partie à la cueillette libre et au prompt directif.

## Prochaine étape exacte
Valider ou remplacer le critère de la Phase 5, puis décider de la suite (autre modèle, prompt moins directif, communication entre agents).

## Question bloquante pour la session suivante
Le critère de succès de la Phase 5 (`experiments/llm_survie_critere_v1.md`) est-il validé tel quel ?
