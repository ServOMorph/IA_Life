# Signals — ia_life (MAJ 2026-09-30)

## Actions ouvertes

- [P1|ouvert] Exécuter la Phase 0 de `roadmap_survie_llm.md` (contrat des actions, validation moteur, repli, déclencheurs, config `experiments/llm_survie_v1.json`).
  fait quand: `experiments/llm_survie_contrat_v1.md` est écrit, la config est validée par `VariableRegistry` et les runs `automate` existants sont inchangés.
  réf: `roadmap_survie_llm.md`, `_docs/decisions/2026-09-30_survie-pilotee-par-llm.md`, `scripts/llm_decider.gd`.
- [P2|ouvert] Rétablir Ollama avant la Phase 4 : le serveur ne répond pas sur `127.0.0.1:11434` (connexion refusée, `ollama list` en timeout).
  fait quand: `ollama list` répond et `gemma3:1b` est disponible.
  réf: `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`.
- [P3|ouvert] Rétablir le contrôle d'intégrité du kit absent.
  fait quand: `python scripts/check_kit.py` s'exécute et ses écarts sont traités ou consignés.
  réf: `.claude/commands/close.md` (étape 10) ; `scripts/check_kit.py` absent, écart connu consigné à la clôture du 2026-09-30.
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

- Nouvelle orientation : LLM (`gemma3:1b`) sur Rouge/Bleu/Vert/Jaune ; « Test » inchangé. Roadmap `roadmap_survie_llm.md` créée, Phase 0 [EN COURS], aucun code écrit.
- Points arbitrés : cible = identifiant de roncier ; ramasser/manger explicites (repas refusé au-dessus de `eat_hunger_threshold` 50, 3 mûres max) ; mémoire illimitée par coordonnées ; pas de repousse ; danger à 0 ; décision asynchrone sans pause ; mesure à x1, `--jobs 1`.
- Chiffres de carte (registre, non re-vérifiés en jeu) : 24 ronciers × 3 mûres, 6 mûres pour une vie complète, faim à 0,6/s par défaut. Latence LLM de 1,4 s mesurée en août, à remesurer.
- Vitesse de faim : à ajuster éventuellement en Phase 4, sur la faim réellement perdue en attente.
- Communication entre agents : reportée après cette roadmap.
- T3 v3 : confirmation en critère non atteint (7/8, `trained` 0,628, scripté 0,875 < 0,90) ; cartes finales `410000201..264` consommées ; axe en pause.
- Les modifications ROBERTO/com_telephone, `AGENTS.md`, `GEMINI.md`, `.claude/CLAUDE.md` et `.claude/commands/roberto.md` du working tree ne font pas partie de cette clôture.

## Dernière session (2026-09-30)

# Session du 2026-09-30

## Décisions prises
- Axe apprentissage T0-T3 mis en pause ; nouvelle orientation : quatre agents pilotés par LLM local.
- Décision asynchrone sans pause (l'agent poursuit son action pendant l'attente) ; mesure à x1, `--jobs 1`, dépendante du matériel.

## Livrables produits ou modifiés
- `roadmap_survie_llm.md` : créée (Phases 0-5, Phase 0 en cours).
- `_docs/decisions/2026-09-30_survie-pilotee-par-llm.md` et `INDEX.md` : décision consignée (proposé).

## Hypothèses validées / invalidées
- EN ATTENTE : `gemma3:1b` sait choisir une cible parmi des ronciers nommés ; coût de latence sur la survie ; niveau de faim adapté.
- EN ATTENTE : reproductibilité du LLM réel (non attendue) ; tests rejouables avec mock uniquement.

## Prochaine étape exacte
Phase 0 : écrire le contrat (schéma d'actions, validation moteur, repli, déclencheurs) et la config `llm_survie_v1.json`.

## Question bloquante pour la session suivante
Aucune (le critère de succès de la Phase 5 sera défini à son ouverture).
