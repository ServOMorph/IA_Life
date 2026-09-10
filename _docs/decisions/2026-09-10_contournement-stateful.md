# Contournement stateful — calibration Phase 3 v3

Date : 2026-09-10. Statut : en cours — candidat v2 invalidé, v3 non mesuré.

## Hypothèse verrouillée avant campagne

Mémoriser la ressource choisie par la politique alimentaire et conserver le côté de passage
jusqu'à dégager le segment vers elle doit réduire le coût de danger sans supprimer la cueillette.
Pas de modification du learner. Les quatre critères de la Phase 3 v3 restent inchangés.

## Mécanisme v1

Option `danger_navigation_mode=contournement`, défaut historique `rectiligne` conservé.
Navigation locale à partir des zones visibles à portée de réaction ou physiquement subies.
Cible et obstacle copiés au déclenchement, suivi tangent avec correction radiale, puis reprise
directe vers la cible mémorisée. Annulation sur ressource perçue vide, arrivée, sortie de faim,
contrôle manuel ou durée de blocage de 30 secondes. Aucun tirage aléatoire pour choisir le côté.
Le bras aléatoire utilise la même primitive lorsqu'il tire `eviter`, conserve son intervalle
de choix et annule le détour lorsqu'il choisit `viser`.

Campagne préenregistrée : `experiments/campaigns/danger_zone_detour_v1.json`, point unique
hérité 12 zones, marge 3, rayon 6, coût 0,8, réaction 8 ; quatre bras + contrôle zéro danger,
12 seeds de calibration, 300 secondes, vitesse 1. Aucun run réservé autorisé avant succès.

## Correction de l'évaluateur

Lecture du code : `REQUIRED_ARMS` énumère eviter, ignorer, viser, aleatoire mais l'affectation
locale déstructurait eviter, viser, ignorer, aleatoire. Les critères 1 et 2 comparaient donc
à tort à ignorer. Correction par accès nommés, test dissociant explicitement ignorer et viser.
Les anciens rapports restent historiques ; les recalculs sont écrits dans des rapports séparés.

## Résultats

Tests automatisés Python de l'évaluateur : 2/2 passent. Suite Godot complète réussie, incluant
trajet autour d'un disque à 30 et 60 Hz, côté et cible stables sans visibilité, arrivée,
ressource vide, blocage borné, centre de zone, intégration au décideur, contrôle manuel et
égalité de la primitive entre eviter et le choix eviter du bras aléatoire.

Les recalculs `results/_danger_zone_approach_probe_v2/gate_report_corrected.json` et
`results/_danger_zone_approach_reaction_range_probe_v1/gate_report_corrected.json` donnent
respectivement 0/4 et 0/3 points admis. Leur critère contre aleatoire ne change pas. Au point
12 zones / marge 3, les critères corrigés coût/résultat contre viser valent 8/12 et 8/12
(ancien rapport résultat : 5/12). Ces nombres corrigent l'interprétation historique.

Calibration v1 lancée (60 runs, 8 processus, retries 2). Résultat en attente.
Commande de reprise si interruption :
`python tools/run_campaign.py experiments/campaigns/danger_zone_detour_v1.json --jobs 8 --retries 2 --resume`.

Reproductibilité préenregistrée sur 2 seeds de calibration et deux bras à 60 secondes :
`python tools/check_campaign_parallelism.py experiments/campaigns/danger_zone_detour_repro_v1.json --jobs 2`.
Ce contrôle exige désormais tous les runs comparables ; un run manquant ne peut plus être toléré.

## Exclusion anticipée de la marge 3

La lecture des summaries historiques du bras viser au point 12 zones / marge 3 montre un coût
nul sur les seeds 20260925, 20260928, 20260930 et 20261002. Le bras viser est inchangé par le
contournement : le critère 1 ne peut dépasser 8/12. La campagne v1 a donc été interrompue après
8 runs terminés, conservés dans `results/_danger_zone_detour_v1` ; aucune conclusion de gate
n'est tirée de ces résultats partiels. Arrêt du groupe de processus et absence de descendants
de campagne constatés. Les runs interrompus ne doivent pas être repris pour valider ce point.

Leur diagnostic provisoire donne 16 déclenchements de détour, 4 reprises directes et 7 timeouts.
Le retour sur la cible existe, mais la robustesse en géométrie réelle reste à évaluer.

## Candidat v2 préenregistré

`experiments/campaigns/danger_zone_detour_v2.json` reprend le point déjà mesuré 12 zones / marge 1
(les autres paramètres sont identiques). Sur ce point, viser subit un coût sur 10/12 seeds ;
la survie historique d'eviter est 0,42. Hypothèse : le contournement doit restaurer cette survie
tout en conservant la séparation causale. Ce choix répond à la couverture nécessaire du critère 1,
sans balayage supplémentaire ni changement des seuils. Résultat en attente.

## Débit à pas physique inchangé

Option opt-in `IA_LIFE_HEADLESS_FIXED_FPS=60` dans le lanceur : Godot `--fixed-fps 60` désactive
uniquement la synchronisation au temps réel, sans modifier `game_speed`. Un premier rejeu complet
du seed 20260921 donne un summary strictement identique hors session_id en 22,4 secondes.
Vérification sur l'ensemble des runs v1 archivés en cours via `tools/check_headless_unsynced.py`.
L'usage pour la calibration v2 reste conditionné à ce contrôle ; défaut du lanceur inchangé.

Contrôle terminé : 8/8 summaries complets identiques hors session_id
(`results/_danger_zone_detour_v1/unsynced_comparison.json`). Le contrôle séquentiel/parallèle
donne également 4/4 identiques. Le selftest historique de politique fixe passe les trois
conditions : déterminisme, absence de mises à jour, sensibilité aux actions fixes.

Calibration v2 lancée après ces contrôles. Commande exacte (PowerShell) :
```powershell
$env:IA_LIFE_HEADLESS_FIXED_FPS = '60'
python tools/run_campaign.py experiments/campaigns/danger_zone_detour_v2.json --jobs 8 --retries 2 --resume
```
Après achèvement :
```powershell
python tools/check_danger_calibration.py results/_danger_zone_detour_v2 --json results/_danger_zone_detour_v2/gate_report.json
python tools/report_danger_navigation.py results/_danger_zone_detour_v2 --json results/_danger_zone_detour_v2/navigation_report.json
```
La télémétrie de déclenchement contient maintenant les coordonnées de la cible et du disque
pour diagnostiquer les timeouts sans inférer leur cause à partir des agrégats.

## Échec du candidat v2

Les quatre bras causaux sont complets (12 seeds chacun). Critères 1/2/3 : 10/12, 10/12, 5/12.
Survies eviter/ignorer/viser/aleatoire : 0,417 / 0,417 / 0 / 0,333. Critères 3 et 4 échoués.
Coût moyen eviter nul, mais 7 timeouts pour 20 déclenchements et une seule reprise directe
journalisée. Les 7 séquences montrent une distance à la cible devenue constante jusqu'au
timeout (exemples : 13,34 m seed 20260922 ; 5,70 m seed 20260923 ; 10,71 m seed 20260925).
La position échantillonnée ne progresse plus : hypothèse d'un blocage physique par le décor.
Le contournement géométrique seul ne suffit pas en présence des collisions de la scène.

## Hypothèse suivante, avant mesure

Conserver la cible et le côté tant que le personnage progresse ; autoriser un unique changement
de côté par obstacle après deux secondes sans déplacement significatif. Cela doit supprimer
les longues immobilisations observées, sans oscillation ni tirage aléatoire. Aucun changement
d'environnement ni de gate. La campagne v3 rejouera le même point que v2 après tests.
