# Contexte — ia_life

## Objectif (immuable sauf décision explicite)
Créer un environnement Godot avec 4 personnages lowpoly, dont un est piloté par le développeur et les autres par des LLM, capables de se déplacer et de communiquer entre eux (loggé), afin d'étudier l'évolution de leurs comportements face aux modifications de l'environnement de jeu.

## Stack / contraintes techniques (stable, rarement modifié)
Godot 4.5 (GDScript), LLM local via Ollama (`gemma3:1b` en référence pour les campagnes ;
`gemma3:4b` disponible mais s'effondre sur ce prompt — voir décisions).

## État actuel (réécrit intégralement à chaque /close)
Laboratoire headless reproductible : configurations versionnées, logs JSONL et campagnes parallélisées.
La roadmap d'apprentissage alimentaire reste en Phase 2 : T0 v2 et T0 v3 échouent le gate face à
`random_valid`. T0 v3 à 3 m produit 1 248 résultats conformes, mais `trained` atteint 0,458 contre
0,604 pour l'aléatoire ; déplacer la ronce ne suffit donc pas. T1 reste gelé jusqu'à une décision
sur le pivot ou l'abandon de T0. Le contournement danger v2 échoue au gate et v3 reste non mesuré,
désormais extension conditionnelle. Les seeds réservés de danger, T0 et T1 restent fermés.

## Décisions structurantes (append only — 10 entrées max, 5 lignes max/entrée, archiver au-delà)
- 2026-09-06 : Phases 0-1 de `roadmap_environnement_apprenable_v3.md` closes — mécanique de zones
  dangereuses (Area3D statiques, RNG dérivé de la seed, coût de faim au temps simulé = taux max,
  télémétrie `danger_*`) validée headless + fenêtré. Outillage dev : autoload `DevState` (overrides
  seed / nb de zones), `run_danger_windowed.py`, panneau dev enrichi ; fix `AnimationPlayer.speed_scale`
  indexé sur `GameSpeed.time_scale`. Prochaine : Phase 2 (perception + oracle).
- 2026-09-07 : Phase 2 de `roadmap_environnement_apprenable_v3.md` close — perception du danger
  raccordée à `_perceive`, décideur `fixed_policy_danger` (ignorer/eviter/viser) en surcouche
  isolée de la politique alimentaire, événement scripté `teleport_agent`. Gate causal franchi sur
  scénario scripté (seed 2) : exposition eviter 0,75 s < ignorer 1,73/1,47 s < viser 11,98 s,
  reproductible ; aucune régression sur l'oracle Phase 1. Prochaine : Phase 3 (calibration).
- 2026-09-08 : Phase 3 engagée, gate causal jamais franchi mais 3 causes d'échec en cascade
  corrigées (bug tirage `aleatoire` par frame, surcouche danger bornée par
  `danger_reaction_range`, plafond de survie remonté par `hunger_depletion_rate` 0,70 —
  `danger_zone_oracle_base_v2.json`, v1 conservé). Densité de zones testée jusqu'à 20 (tendance
  monotone, pas encore suffisant). Voir
  `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md`.
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
