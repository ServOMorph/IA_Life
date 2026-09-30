# T1 v4 — cause de navigation isolée et hypothèse v5 gelée

Date : 2026-09-28. Statut : diagnostic validé ; candidat v5 proposé, non entraîné.

## Diagnostic hors validation

Les trois checkpoints T1 v4 retenus à 1 000 épisodes ont été rejoués sur les 32 cartes
d'entraînement `360000001..360000032`, jamais sur les réserves de validation ou de test. Chaque
checkpoint a exécuté trois modes avec le même premier choix glouton : politique v4 complète,
maintien du premier cap, et recalcul privilégié du cap vers la cible.

| Mode | Premiers choix corrects | Consommations | Épisodes avec au moins un éloignement |
| --- | ---: | ---: | ---: |
| Politique v4 complète | 96/96 | 74/96 | 47/96 |
| Maintien du premier cap | 96/96 | 96/96 | 0/96 |
| Recalcul vers la cible | 96/96 | 96/96 | 0/96 |

Les échecs v4 contiennent des cycles comme `3,2,3,2...`, `1,3,0...` ou une direction répétée
jusqu'au mur. La distance diminue d'abord, puis augmente ou stagne. Maintenir le premier cap avec
la même physique et le même horizon supprime tous les échecs observés.

Conclusion causale limitée au diagnostic : la table des pas suivants est responsable des échecs
observés. Sa clé conserve le secteur et la classe de distance initiaux, plus l'action précédente,
mais pas la position courante ni la direction relative. Le même état tabulaire représente donc
des géométries différentes. Le premier choix, la collision avec le roncier et l'horizon restent
solvables sur ce lot.

## Décision proposée

Le contrat v5 transforme T1 en choix unique suivi d'une compétence motrice déclarée qui maintient
le cap. Cette séparation correspond au périmètre T1 « choix de ressource » ; elle ne revendique
pas un apprentissage de navigation. Le contrôle privilégié de recalcul vers la cible reste exclu
de la campagne.

Le contrat et les réserves neuves ont été gelés dans
`experiments/apprentissage_t1_contrat_v5.md`. À ce stade du diagnostic, aucune campagne v5
n'avait été lancée ; l'implémentation, les tests et le probe devaient précéder toute ouverture
de validation.

## Suite du 2026-09-28

Les prérequis ont ensuite passé et la validation v5 a atteint son gate avec 96/96 consommations
et premiers choix pour `trained`. Voir `_docs/decisions/2026-09-28_t1-v5-gate-atteint.md`.

## Reproduction

Pour chaque initialisation `360001001..360001003`, exécuter la scène
`tools/t1_navigation_diagnostic.tscn` avec son checkpoint v4 à 1 000 épisodes, puis analyser le
JSONL avec `tools/analyze_t1_navigation_diagnostic.py`. Les sorties brutes versionnées sont
`experiments/t1_v4_navigation_diagnostic_360001001.jsonl` à
`experiments/t1_v4_navigation_diagnostic_360001003.jsonl`.
