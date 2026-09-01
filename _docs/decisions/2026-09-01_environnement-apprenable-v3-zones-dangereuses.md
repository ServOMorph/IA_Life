# Environnement apprenable v3 — zones dangereuses comme préalable

Date : 2026-09-01
Statut : validé pour planification ; mécanique non encore implémentée ni validée
Roadmap : `roadmap_environnement_apprenable_v3.md`

## Décision

Ne pas reprendre directement les Phases 4 à 6 de `roadmap_apprentissage_v2.md`. Construire d'abord
un environnement v3 où le choix de direction a une conséquence causale mesurable. Le premier
mécanisme retenu est une zone dangereuse localisée qui ajoute un coût de faim pendant l'exposition.

La reprise de la roadmap apprentissage v2 reste conditionnée à un oracle de politiques fixes : une
politique d'évitement doit battre une politique qui vise le danger et la sélection aléatoire sur
12 seeds réservés, selon des critères écrits avant mesure.

## Motif

L'environnement v2 ne distingue pas suffisamment les trajectoires : les ressources sont homogènes
et réparties aléatoirement, et la sélection d'action aléatoire égale la meilleure politique fixe à
0,58 de survie. `adaptatif_courant` atteint 0,67 en agrégat, mais ne se sépare ni du hasard ni de
`adaptatif_v1` au seed apparié. Améliorer seulement le learner ne crée pas une stratégie là où le
monde n'en récompense pas clairement une.

Le danger localisé est choisi car il rend immédiatement certaines directions meilleures que
d'autres tout en réutilisant la faim, la vision générique, les campagnes appariées et les outils
d'oracle existants. Une nouvelle jauge de santé, les dangers mobiles et les ressources
hétérogènes sont écartés de cette première itération.

## Contrainte révélée par l'analyse

Le reward adaptatif actuel ne mesure pas la variation de faim : il crédite les cueillettes,
soustrait un coût temporel et applique une pénalité terminale. L'exposition au danger doit donc
être raccordée ultérieurement comme événement négatif explicite, avec test d'attribution du crédit
et nouveau schéma de table. Ce raccord est interdit tant que l'oracle fixe n'a pas validé la tâche.

## Conséquences

- Les environnements v1 et v2 restent gelés comme références historiques.
- Une nouvelle référence v3 n'est créée qu'après calibration sur seeds d'entraînement et
  confirmation sur seeds réservés.
- En cas d'échec de l'oracle réservé, l'axe apprentissage reste suspendu.
- En cas de succès, la roadmap v2 est amendée avec une Phase 3b de raccord danger, une nouvelle
  baseline, puis reprend à la Phase 4 ; sa Phase 6 reste conditionnelle.
