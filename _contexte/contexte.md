# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 4 personnages lowpoly, dont un est piloté par le développeur et les autres par des LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible ; T0 v4 franchit le gate de la première preuve alimentaire.
La Phase 3 valide le bridge TCP/JSONL et les adaptateurs Gymnasium T0/monde.
La roadmap est en Phase 4 : T1 v4 atteint 96/96 premiers choix corrects, mais 70/96 consommations,
sous le seuil requis ; la navigation après le premier pas reste à diagnostiquer.
Les tests finaux T0/T1 restent fermés ; T2/T3 ne sont pas engagés. L'axe danger reste en pause.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-09-10 : seconde itération de placement sur approche de roncier validée techniquement
  (smoke, sweep 12 seeds, 1 728/1 728 placements) mais gate causal toujours en échec. Le probe
  de portée 10/12/15 m invalide l'hypothèse d'une réaction trop tardive : une fuite rectiligne
  perturbe la ressource sans fournir de contournement. Voir
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
- 2026-09-10 : contournement stateful testé sur calibration — coût évité nul et 10/12 contre
  `viser`, mais 5/12 seulement contre `aleatoire`, survie maximale 0,42. Échec du gate ; v3
  propose une récupération de collision non mesurée. Voir
  `_docs/decisions/2026-09-10_contournement-stateful.md`.
- 2026-09-10 : réorientation adoptée — la roadmap alimentaire progressive devient le chemin
  critique : persistance entre épisodes, micro-tâche, interface d'entraînement puis monde complet.
  L'axe danger devient une extension conditionnelle ; les résultats et seeds historiques restent
  isolés. Voir `_docs/decisions/2026-09-10_reorientation-apprentissage.md`.
- 2026-09-12 : T0 v2 fixe une ronce à 2 m sans récompense de distance ; scénario physique,
  table persistante, validation et exécution parallèle par lignées sont prêts. La campagne n'a pas
  été lancée ; aucun gain n'est conclu. Voir `_docs/decisions/2026-09-12_t0-alimentaire-v2.md`.
- 2026-09-18 : T0 v2 atteint son gate sur 1 248 résultats valides : `scripted` et les trois
  lignées `trained` réussissent 96/96 au checkpoint 1 000 ; les contrôles restent inférieurs.
- 2026-09-19 : correction — le gate T0 v2 n'est pas atteint. Gain `trained`@1000 contre
  `random_valid` = 0,271 agrégé (0,25-0,28 par lignée), sous le seuil de 0,30. Calibration
  complémentaire : `random_valid` seul tombe de 0,73 (2 m) à ~0,31-0,47 (3 m). Voir
  `_docs/decisions/2026-09-19_gate-t0-non-atteint.md`.
- 2026-09-24 : T0 v3 (ronce à 3 m) est invalidé : 1 248 résultats conformes, mais `trained`
  atteint 0,458 contre 0,604 pour `random_valid` et échoue au seuil absolu. T1 reste gelé ; voir
  `_docs/decisions/2026-09-24_t0-v3-gate-non-atteint.md`.
- 2026-09-26 : T0 v4 franchit le gate sur 1 248 résultats : `trained` 96/96, initial 12/96,
  aléatoire 57/96. La recharge reproduit les décisions ; preuve limitée aux huit secteurs T0.
  Voir `_docs/decisions/2026-09-26_t0-v4-gate-atteint.md`.
- 2026-09-26 : Phase 3 valide le bridge TCP/JSONL et les adaptateurs Gymnasium T0/monde :
  12 tests d'intégration, vérification SB3 et 24/24 secteurs T0 des checkpoints retenus.
  Voir `_docs/decisions/2026-09-26_phase3-interface-t0.md`.
- 2026-09-27 : T1 v2/v3/v4 échouent au gate. V4 apprend le premier choix (96/96), mais
  consomme dans 70/96 cas, sous le seuil de 0,80. Phase 4 ouverte ; diagnostic de navigation
  requis avant tout nouveau contrat. Voir `_docs/decisions/2026-09-27_t1-v4-gate-non-atteint.md`.
