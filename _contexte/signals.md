# Signals — ia_life (MAJ 2026-10-02)

## Actions ouvertes

- [P1|ouvert] Valider ou remplacer le critère de succès de la Phase 5 (proposé par l'assistant, non co-défini) avant d'exploiter le résultat.
  fait quand: l'utilisateur a validé ou remplacé `experiments/llm_survie_critere_v1.md` et le rapport est relu en conséquence.
  réf: `experiments/llm_survie_critere_v1.md`, `experiments/llm_survie_rapport_v1.md`, `tools/analyze_llm_survie.py`.
- [P1|ouvert] Trancher le sort de la mémoire cartographique `llm_survie` : gate d'usage non atteint (carte 5/8 en direction inexplorée, 3/4 près d'un bord). Choisir entre retirer du choix les directions « bord » (contrainte moteur), réviser le prompt, ou accepter l'état. Actif par défaut : les runs `llm_survie` ne sont plus comparables à la Phase 5 sans `llm_survie_map_memory: false`.
  fait quand: une décision est consignée dans `_docs/decisions/2026-10-02_memoire-cartographique-llm-survie.md` et la config de référence des campagnes est fixée (carte active ou non).
  réf: `scripts/survie_map_memory.gd`, `scripts/llm_survie_ollama_backend.gd`, `tools/check_llm_survie_map_usage.gd`, `results/llm_survie_carte_usage.json`.
- [P2|ouvert] Démonstration fenêtrée de la survie pilotée par LLM (Phase 4) sur le bureau virtuel IA_Life, y compris le chat LLM repliable et la carte mémorisée.
  fait quand: les contrôles de la section Phase 4 et de la section Chat LLM / carte de `tests_manuels.md` sont validés et les sections supprimées.
  réf: `tests_manuels.md`, `run_survie_demo.py`, `experiments/llm_survie_v1.json`.
- [P2|ouvert] `scripts/ui_manager.gd` (section « Chat LLM » repliable, défilement stable, repli des panneaux) n'est pas commité : le fichier mélange aussi les changements du thème Observatoire (flux DESIGN, dépend de `scripts/observatory_style.gd` et `assets/fonts/` non versionnés).
  fait quand: `ui_manager.gd` est commité avec les fichiers Observatoire, ou ses hunks sont séparés.
  réf: `git diff scripts/ui_manager.gd`, `DESIGN/roadmap_observatoire.md`.
- [P3|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; `scripts/check_kit.py` absent, écart connu consigné aux clôtures du 2026-09-30, 2026-10-01 et 2026-10-02.
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

- Mémoire cartographique `llm_survie` livrée (non commitée pour `ui_manager.gd` seulement) : cases de 10 m parcourues, bords touchés, état par direction (30 m), tour déclenché par `bord_decouvert`, section « CARTE MÉMORISÉE » dans le prompt. Variable `llm_survie_map_memory` (défaut actif) ; désactivée, prompt identique à la v1.
- Banc d'usage `tools/check_llm_survie_map_usage.gd` (Ollama réel, `gemma3:1b`, 12 situations) : direction inexplorée 5/8 avec carte contre 1/8 sans ; bord 3/4 contre 3/4 ; gate (>= 6/8, 4/4, > témoin) non atteint. Un seul ajustement de prompt effectué (1/8 -> 5/8).
- Tests automatiques : 6 tests carte dans `tools/run_manual_checks.gd`, suite complète verte (`python tools/run_manual_checks.py`).
- Chat LLM par personnage (section repliable du panneau, prompt complet et réponse, 40 échanges, défilement stable) ; panneaux qui se rétrécissent au repli.
- Roadmap `roadmap_survie_llm.md` exécutée en entier (Phases 0 à 5), résultat : vie moyenne automate 292 s, `llm_survie` 542 s (6 cartes, x1, `--jobs 1`), 0 repli ; critère non validé, prompt directif, cueillette libre.
- Ollama doit être lancé (`ollama serve`) pour la démonstration, le banc d'usage et les campagnes `llm_survie`.
- Flux DESIGN parallèle non commité (Observatoire : `scripts/observatory_style.gd`, `assets/fonts/`, `DESIGN/`) : les erreurs de chargement des polices en headless viennent de là (import non fait), sans casser les tests.
- Working tree hors session non commité : `.claude/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.claude/commands/roberto.md` supprimé, `ROBERTO/com_telephone/*`, `scripts/main.gd`, logs `experiments/t0_v3_results.jsonl.workers/`, `.uid` divers.

## Dernière session (2026-10-02)

# Session du 2026-10-02

## Décisions prises
- Chat LLM par personnage dans le panneau (repliable, prompt et réponse complets) ; défilement sans saut ; panneaux redimensionnés au repli.
- Mémoire cartographique ajoutée à `llm_survie` (cases, bords, état par direction), active par défaut, désactivable.

## Livrables produits ou modifiés
- `scripts/survie_map_memory.gd`, `llm_survie_engine.gd`, `llm_survie_ollama_backend.gd`, `llm_survie_turns.gd`, `character.gd`, `variable_registry.gd` : livrés.
- `tools/run_manual_checks.gd` (6 tests carte, suite verte), `tools/check_llm_survie_map_usage.gd` (banc Ollama) : livrés.
- `scripts/ui_manager.gd` : modifié, non commité (mélangé au thème Observatoire).

## Hypothèses validées / invalidées
- VALIDE : la mémoire des bords et des zones, son injection dans la vue et le prompt, et le déclenchement de tour (tests automatiques).
- INVALIDE : `gemma3:1b` n'exploite pas pleinement la carte (gate d'usage non atteint : 5/8 et 3/4) ; près d'un bord il choisit encore une direction interdite.
- EN ATTENTE : effet de la carte sur la survie (aucune campagne rejouée) ; critère Phase 5 non validé.

## Prochaine étape exacte
Trancher le sort de la carte (contrainte moteur sur les directions « bord », révision du prompt ou statu quo), puis fixer la config de référence avant toute campagne `llm_survie`.

## Question bloquante pour la session suivante
Faut-il retirer du choix du LLM les directions marquées « bord de carte » (contrainte moteur) ou garder une mémoire purement informative ?
