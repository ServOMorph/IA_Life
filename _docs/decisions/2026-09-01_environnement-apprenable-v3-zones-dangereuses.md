# Environnement apprenable v3 — zones dangereuses comme préalable

Date : 2026-09-01
Statut : validé pour planification. Phases 0-1 closes le 2026-09-06 (mécanique de zones
dangereuses implémentée, télémétrie et coût de faim validés headless + fenêtré). Phase 2 close le
2026-09-07 (perception du danger raccordée à `_perceive`, oracle `fixed_policy_danger` en
surcouche, gate causal franchi sur scénario scripté : eviter < ignorer < viser, reproductible).
Phase 3 (calibration) engagée le 2026-09-08, gate causal jamais franchi, voir section dédiée.
Roadmap : `roadmap_environnement_apprenable_v3.md`

## Phase 3 — calibration, diagnostic en cascade (2026-09-08)

Quatre campagnes de diagnostic sur les 12 seeds de calibration (jamais les seeds réservés), gate
appliqué par `tools/check_danger_calibration.py` (4 critères écrits en Phase 3 de la roadmap) :

1. Grille initiale (384 runs) : 0/8 points. Bug trouvé : `FixedPolicyDecider.decide()` est
   rappelé à chaque frame physique (`character.gd::_physics_process`), pas une fois par fenêtre
   de décision. Le bras `aleatoire` retirait eviter/viser à chaque frame (~60×/s) : la direction
   s'annule en moyenne, reproduisant exactement les statistiques du bras `eviter` (coût et
   exposition nuls sur 96 runs). Corrigé : le tirage est tenu pendant
   `decision_interval_seconds`, même mécanique que `_engagement_timer` de `AdaptiveDecider`
   (`fixed_policy_decider.gd`). Le bras `pf_rm_er` (contrôle sans danger) a aussi été sorti de
   `danger_zone_oracle_v3.json` : un override de bras sur `danger_zone_count` est toujours
   écrasé par la grille (`run_campaign.py` applique les overrides de bras avant la grille, qui
   l'emporte sur un chemin commun) — isolé dans `danger_zone_oracle_v3_control.json`.
2. Bug rejoué (384 runs) : gate toujours 0/8. Découverte : `eviter` supprime bien le coût de
   danger (0,00 confirmé, 0 entrée en zone) mais reste le pire bras en survie (0,19 vs 0,32 pour
   `ignorer`) — la surcouche remplace la politique alimentaire dès qu'une zone est visible
   n'importe où dans le champ de vision (15 m), pas seulement sur le chemin vers la nourriture.
   Corrigé : nouveau paramètre `danger_reaction_range` (CHARACTER, décision, défaut 250,0 = pas
   de filtrage), sous lequel seul un danger *visible* (pas physiquement subi) déclenche la
   surcouche ; un danger subi reste toujours prioritaire, sans condition de distance.
3. Diagnostic `danger_reaction_range` (3/5/8 m, 144 runs) : `eviter` remonte à 0,33 au meilleur
   point (8 m) mais gate toujours en échec. Découverte parallèle : le contrôle sans danger
   (`pf_rm_er`, 0 zone) ne survit lui-même qu'à 0,25 sur ces 12 seeds, contre 0,58 mesuré sur
   d'autres seeds lors du calibrage de `roadmap_apprentissage_v2.md` — variance inter-seed déjà
   documentée comme risque connu de l'environnement v2, pas une erreur de configuration (les deux
   fichiers de base vérifiés cohérents). Diagnostic ciblé `hunger_depletion_rate` (0,70 à 0,90,
   60 runs, `pf_rm_er` seul) : 0,70 remonte la survie à 0,75 ; 0,75/0,80 restent à 0,42 (fonction
   très sensible dans cette plage). Base amendée : `experiments/danger_zone_oracle_base_v2.json`
   (`hunger_depletion_rate` 0,70), `danger_zone_oracle_base_v1.json` conservé intact comme trace
   historique.
4. Diagnostic `reaction_range` rejoué sur la base v2 (144 runs) : critère 4 du gate satisfait
   (meilleure survie 0,67, pire 0,33, dans la plage [0,50, 0,90]/≤0,40 exigée) mais
   `eviter`/`ignorer`/`aleatoire` produisent des résultats strictement identiques sur la majorité
   des 12 seeds — avec 6 zones et `danger_zone_safety_radius` 12 m autour de 30 ronciers (carte
   160×160), le danger n'est presque jamais sur la trajectoire naturelle de l'agent, la réponse
   n'a donc pas l'occasion de s'exercer (0,00-0,08 entrée en zone/vie pour eviter/aleatoire).
   Diagnostic densité (10/15/20 zones, 144 runs, aucun échec de placement même à 20) : tendance
   **monotone claire** — à 20 zones, `eviter` devient la meilleure politique (0,58, devant
   `ignorer` 0,50) ; les 3 critères d'accord par seed progressent 6→7/12, 3→6/12, 2→5/12, mais
   restent sous les seuils requis (9-10/12).

Session arrêtée sur ce palier (décision utilisateur, à reprendre en priorité la session
suivante) : pousser le probe de densité à 25/30/40 zones sur le même point fixe (rayon 6,0 /
coût 0,6 / `danger_reaction_range` 8,0 / base v2) pour voir si la tendance monotone franchit les
seuils du gate ou plafonne — auquel cas trancher entre enrichir davantage la mécanique et
abandonner l'axe danger (branche Échec de la roadmap).

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
