# Rapport — survie pilotée par LLM (Phase 5, v1)

Critère appliqué : `experiments/llm_survie_critere_v1.md` (proposé par l'assistant, validé par l'utilisateur le 2026-10-03 avec amendements : comparateur principal = automate témoin à cueillette libre, succès = « exécuteur viable d'une stratégie décrite », portée limitée à 1 modèle, 1 prompt, 6 cartes).

## Verdict selon le critère amendé (2026-10-03)

- Critère 1 (robustesse) : atteint (inchangé).
- Critère 2 (performance, contre le témoin) : atteint. 542 / 345 = 1,57 (seuil 0,80).
- Critère 3 (lecture forte, contre le témoin) : atteint. `llm_survie` supérieur ou égal au témoin sur 5 cartes sur 6 (seuil 4 sur 6) ; exception : 26093005 (437 contre 451).
- Succès : atteint, au sens « exécuteur viable d'une stratégie décrite ». Les amendements sont posthoc et ne changent pas le verdict.
Données : `results/_llm_survie_v1_automate`, `results/_llm_survie_v1_llm`, `results/_llm_survie_v1_automate_libre`
(dossiers locaux, ignorés par git) ; synthèse machine : `results/_llm_survie_v1_rapport.json` ;
script : `python tools/analyze_llm_survie.py`.

## Conditions

- 6 cartes (seeds 26093001 à 26093006), `game_speed = 1.0`, `max_simulation_seconds = 1200`, danger désactivé, vision 25 m, mémoire illimitée sans oubli.
- Bras `llm_survie` : `gemma3:1b`, `--jobs 1`, aucun autre processus lourd. Bras `automate` : `--jobs 6` (déterministe).
- Matériel : AMD Ryzen 7 5700X (8 cœurs, 16 threads), 47,9 Go de RAM, Windows 11, Ollama 0.31.2. Le GPU utilisé par Ollama n'a pas été relevé.
- Résultats dépendants du matériel (latence du LLM), non rejouables à l'identique.

## Résultats

Durée de vie moyenne des quatre agents par carte, en secondes simulées (aucun survivant à 1200 s) :

| Seed | automate | automate, cueillette libre (témoin) | llm_survie |
|---|---|---|---|
| 26093001 | 278 | 382 | 604 |
| 26093002 | 361 | 250 | 583 |
| 26093003 | 229 | 306 | 542 |
| 26093004 | 313 | 313 | 500 |
| 26093005 | 229 | 451 | 437 |
| 26093006 | 340 | 368 | 583 |
| Moyenne | 292 | 345 | 542 |

- Critère 1 (robustesse) : atteint. 6 runs sur 6 terminés, 3 704 tours LLM au total, 0 repli, 0 refus.
- Critère 2 (performance) : atteint. Ratio `llm_survie` / `automate` = 1,86 (seuil 0,80).
- Critère 3 (lecture forte) : atteint. `llm_survie` supérieur ou égal à l'automate sur 6 cartes sur 6.
- Mûres mangées (somme des 4 agents, moyenne par carte) : environ 54 pour `llm_survie` contre 18 pour l'automate.
- Latence moyenne par réponse : 1,7 à 3,0 s selon la carte (quatre requêtes se partagent le même serveur Ollama).
- Distribution des actions `llm_survie` : `aller_vers` 2 368, `explorer` 686, `ramasser` 326, `manger` 324.

## Lecture et limites

1. L'automate ne cueille qu'au-dessous de `pickup_hunger_threshold` (90) ; `llm_survie` cueille à tout moment (contrat). Le bras témoin (automate, seuil à 100) remonte à 345 s : cette règle explique une partie de l'écart, mais `llm_survie` reste à 1,57 fois le témoin et le dépasse sur 5 cartes sur 6 (la carte 26093005 est quasi à égalité, 437 contre 451).
2. Le prompt décrit la stratégie (règles explicites, actions légales listées, directions déjà bloquées exclues du schéma, cibles bloquées retirées). Sans ces aides, `gemma3:1b` se fige sur une action : 27 réponses `manger` sur 27 avec le premier prompt, puis 100 % `explorer` tant que les règles n'étaient pas dans le prompt. Le résultat mesure donc un LLM exécutant une stratégie décrite, avec latence, pas un raisonnement spatial autonome.
3. Pas de repousse et stock fini de 72 mûres : la durée de vie est plafonnée par la carte pour les deux bras.
4. Comparaison non équitable par construction : l'automate décide instantanément, `llm_survie` perd de la faim en attente de réponse (voir `llm_survie_faim_perdue_attente` dans les résumés).
5. Un seul modèle, une seule version de prompt, 6 cartes : pas de test statistique ; 6 cartes sur 6 est un résultat consistant, pas une preuve de généralité.
6. Le critère a été validé par l'utilisateur après la mesure (2026-10-03), avec amendements posthoc.
