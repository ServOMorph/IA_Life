# Calibrage de l'environnement et oracle de politiques fixes (Phase 1 v2)

Date : 2026-08-31
Statut : proposé — gate franchi à n=12, environnement de référence gelé, mesure M0 prise.

> Phase 1 de `roadmap_apprentissage_v2.md`. Question fusionnée « la tâche est-elle
> apprenable ? » + « l'environnement discrimine-t-il ? ». Réponse : **oui**, il existe un
> environnement viable où les politiques fixes se séparent proprement, et le contraste
> apprenable est identifié (une décision, en S2).

## Ce qui a été construit

- `scripts/fixed_policy_decider.gd` : `FixedPolicyDecider extends AdaptiveDecider`. Choix
  d'action fixe par situation (S1 : 3 options, S2 : 2 options — S3 n'offre que l'errance),
  aucune mise à jour de score (`_apply_online_reward`, `on_terminal_starvation`,
  `_commit_reward`, `log_table` neutralisés), comportement déterministe. Réutilise toute la
  machinerie de classification / fenêtre d'engagement / ciblage de `AdaptiveDecider`.
- `variable_registry.gd` : `decider_type` gagne `politique_fixe` ; variables
  `fixed_policy_s1` (`ronce_visible` / `ronce_memorisee` / `errance`), `fixed_policy_s2`
  (`ronce_memorisee` / `errance`).
- `tools/run_campaign.py` : support `"arms"` — jeux d'overrides nommés appliqués par-dessus
  la base, produit bras × grille × seeds ; `metadata.arm`. Sert les mesures M0..Mf du
  benchmark (bras appariés au seed). Fix : `warmup_import()` ajoute la racine projet à
  `sys.path`.
- `tools/aggregate_results.py` : `arm` intégré à la clé de regroupement (`comparison_group`)
  et au CSV.
- `tools/oracle_report.py` : évaluateur du gate — survie / vie médiane / mûres par bras et
  par environnement, meilleure vs pire politique fixe, test des signes apparié au seed sur
  la durée de vie, seuils meilleure ≥ 0,70 / pire ≤ 0,30 / accord ≥ 9 sur 12.
- `tools/check_fixed_policy.py` : gate de non-régression du décideur (déterminisme à seed
  fixe, aucune mise à jour de score, sensibilité à la politique — S1/S2 exercées).
- `experiments/apprentissage_env_ref.json` : environnement de référence **gelé**.
- `experiments/campaigns/benchmark_apprentissage.json` : 9 bras, 12 seeds d'entraînement +
  12 seeds réservés énumérés.

## Méthode

L'approche « grille grossière 8 environnements » de la roadmap a été précédée d'un probe de
calibrage (54 runs), qui a montré la grille initiale mal centrée : à `vision_range` 15 et
`ronce_count` 24, 100 % des décisions de faim de l'apprenant sont en S3 (choix unique), et
tous les environnements testés étaient trop durs (meilleure survie 33 %). Le probe a aussi
établi que `pf_rv_rm` (viser roncier visible / viser souvenir) est **strictement identique**
à `automate`, bit à bit.

Passe de faisabilité (`p1_oracle_feasibility.json`, 240 runs, 5 bras, grille
`vision_range` {15, 40} × `hunger_depletion_rate` {0,5, 0,7, 0,9}, `ronce_count` 30 fixe,
8 seeds) → un environnement franchit le gate. Confirmation à n=12 par la campagne M0
elle-même (`benchmark_apprentissage.json`, 108 runs, 9 bras, 12 seeds), qui **est** la
mesure « avant ».

Budget consommé : 54 + 240 + 108 = 402 runs (roadmap : ~670 pour la Phase 1).

## Environnement retenu (gelé)

`vision_range` 15 · `hunger_depletion_rate` 0,7 · `ronce_count` 30 · `berries_per_ronce` 4 ·
300 s simulées · arrêt à durée atteinte · Bleu/Vert/Jaune en `automate`, `vision_range` 40.

C'est le monde d'`apprentissage_faim_v2.json` avec une faim légèrement plus douce
(0,7 au lieu de 0,8). Autres points de la grille : `hunger` 0,5 saturé (tous survivent),
`hunger` 0,9 trop dur, `vision_range` 40 / `hunger` 0,7 limite (meilleure fixe 0,62).

## Mesure M0 « avant » (agent Rouge, 12 seeds d'entraînement)

| bras | survie | vie médiane (s) | mûres mangées (moy) |
|---|---|---|---|
| `aleatoire` (adaptatif_v1, ε 1,0) | **0,92** | 300,0 | 9,17 |
| `adaptatif_v1` (ε 0,2, lr 0,2) | 0,83 | 300,0 | 8,58 |
| `pf_er_rm` (S1 errance / S2 souvenir) = **`politique_fixe_max_v1`** | 0,83 | 300,0 | 7,83 |
| `pf_rm_er` (S1 souvenir / S2 errance) | 0,75 | 300,0 | 8,08 |
| `pf_rm_rm` (S1 souvenir / S2 souvenir) | 0,75 | 300,0 | 7,50 |
| `automate` | 0,50 | 269,1 | 5,17 |
| `pf_rv_rm` (S1 visible / S2 souvenir) | 0,50 | 269,1 | 5,17 |
| `pf_rv_er` (S1 visible / S2 errance) | 0,42 | 261,9 | 5,33 |
| `pf_er_er` (S1 errance / S2 errance) | 0,17 | 238,1 | 3,67 |

Gate : meilleure politique fixe `pf_er_rm` 0,83 (≥ 0,70 OK), pire `pf_er_er` 0,17
(≤ 0,30 OK), test des signes durée de vie 9-0 (3 égalités) → accord 9/12 (≥ 9 OK).
**GATE FRANCHI.**

Métrique « temps passé sous `pickup_hunger_threshold` » : non capturée dans le summary
(dérivable des événements `position` si nécessaire plus tard). Survie + durée de vie +
mûres suffisent au gate.

## Ce que le résultat dit

1. **Il y a un bit apprenable, et il est identifié.** `pf_er_rm` (0,83) et `pf_er_er`
   (0,17) ne diffèrent que par S2 : « pas de roncier visible mais un souvenir utilisable →
   viser le souvenir » vs « errer ». C'est le contraste que le gate mesure. Un seul bit,
   conforme au diagnostic (« ~1 bit apprenable par vie »).
2. **`pf_rv_rm` ≡ `automate`** (0,50 / 269,1 / 5,17, identiques bit à bit à n=12). Le
   décideur de référence code en dur « viser le roncier visible d'abord » ; c'est une
   *mauvaise* priorité dans cet environnement. `politique_fixe_max_v1` est `pf_er_rm`, pas
   `pf_rv_rm`.
3. **`aleatoire` (0,92) est le meilleur bras**, au-dessus d'`adaptatif_v1` et de toute
   politique fixe. Sélection uniforme sur {viser visible, viser souvenir, errer} par
   fenêtre de 2 s : le tirage tombe assez souvent sur les actions « souvenir » (les bonnes)
   pour battre l'automate, qui ne les prend jamais. Humbling mais cohérent.
4. `adaptatif_v1` (0,83) égale déjà `politique_fixe_max_v1` et bat `automate` — mais ne bat
   pas `aleatoire`. M0 n'est qu'un instantané ; le critère de succès se juge à Mf.

## Angles morts / limites

- **Plafond `aleatoire` à 0,92** : la bande utile pour le critère de succès Mf
  (« `adaptatif_courant` bat `adaptatif_v1` ET `automate` sur ≥ 9/12 ») est étroite en
  haut sur la métrique primaire (survie). Les métriques secondaires (mûres, vie médiane)
  devront probablement porter la comparaison. À surveiller dès M1.
- 10 cellules `pf_er_er` de la campagne de faisabilité (environnements **non retenus**,
  `hunger` 0,9 et `vision` 40) non rejouées : `pf_er_er` crashe Godot sporadiquement sous
  charge (mode d'échec documenté en Phase 0). Sans impact sur le point retenu, dont les
  12 seeds × 9 bras sont complets.
- L'oracle n'a balayé que `vision_range` × `hunger_depletion_rate` (grille 2×3),
  `ronce_count` figé à 30. Un balayage `ronce_count` pourrait trouver un point plus
  discriminant, mais le point retenu franchit le gate avec un écart de 0,67 : raffinement
  non jugé nécessaire.

## Note reportée

`roadmap_apprentissage_v2.md`, section Phase 1 : note de travail « manger au contact »
(retrait de la consommation différée). Le gate étant franchi, on garde le buffer et la
Phase 2 traitera le timing de récompense. Note parquée (ne se déclenchait qu'en cas
d'échec du gate).
