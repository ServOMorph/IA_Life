# Signals — ia_life (MAJ 2026-09-08)

## Actions ouvertes

- [P1|ouvert] Poursuivre le probe de densité de zones dangereuses (Phase 3 de
  `roadmap_environnement_apprenable_v3.md`) au-delà de 20 zones (25/30/40), sur le point fixe
  rayon 6.0 / coût 0.6 / `danger_reaction_range` 8.0, base `danger_zone_oracle_base_v2.json`
  (`hunger_depletion_rate` 0.70), mêmes 12 seeds de calibration.
  fait quand: un point de densité franchit les 4 critères du gate causal Phase 3
  (`tools/check_danger_calibration.py`), ou la tendance monotone plafonne sans les atteindre
  (documenter alors comme limite du mécanisme avant de trancher enrichir/abandonner).
  réf: `roadmap_environnement_apprenable_v3.md` (Phase 3), `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md` (section 2026-09-08), `experiments/campaigns/danger_zone_density_probe_v1.json`.
- [P3|dormant] Axe apprentissage v2 toujours suspendu pendant la validation de l'environnement v3.
  fait quand: Phases 0-5 v3 [FAIT], gate réservé Phase 4 passé, puis bandeau v2 amendé.
  réf: `roadmap_environnement_apprenable_v3.md` (condition de déblocage),
  `roadmap_apprentissage_v2.md` (bandeau en tête).

## Contexte chaud

- Phase 3 engagée le 2026-09-08, gate causal jamais franchi mais 3 causes d'échec identifiées et
  corrigées/amendées en cascade, chacune vérifiée par un diagnostic resserré (12 seeds de
  calibration, pas les seeds réservés) :
  1. **Bug tirage `aleatoire`** : `FixedPolicyDecider.decide()` est appelé à chaque frame physique
     (`character.gd::_physics_process`) ; un premier correctif retirait eviter/viser à chaque
     frame, la direction oscillait ~60×/s et s'annulait en moyenne (le bras `aleatoire`
     reproduisait exactement les stats du bras `eviter`, 0.00 coût/exposition sur 96 runs).
     Corrigé : le tirage est tenu pendant `decision_interval_seconds`, même mécanique que
     `_engagement_timer` de `AdaptiveDecider`. `aleatoire` ajouté à l'enum `fixed_policy_danger`
     (`ignorer|eviter|viser|aleatoire`).
  2. **Surcouche danger trop invasive** : elle remplaçait la politique alimentaire dès qu'une zone
     est visible n'importe où dans le champ de vision (15 m), pas seulement sur le chemin —
     `eviter` supprimait bien le coût de danger (0.00) mais restait le pire bras en survie (0.19
     vs 0.32 pour `ignorer`). Corrigé : nouveau paramètre `danger_reaction_range` (CHARACTER,
     décision, défaut 250.0 = pas de filtrage), sous lequel seul un danger *visible* (pas subi)
     déclenche la surcouche ; un danger physiquement subi reste toujours prioritaire.
  3. **Plafond de survie sous 0.50 y compris sans danger** : `pf_rm_er` (contrôle, 0 zone)
     survivait à 0.25 sur les 12 seeds de calibration Phase 3, contre 0.58 mesuré sur d'autres
     seeds lors du calibrage de `roadmap_apprentissage_v2.md` — variance inter-seed déjà
     documentée comme risque connu de l'environnement v2. Amendé : `hunger_depletion_rate` 0.9 →
     0.70 dans une nouvelle base `experiments/danger_zone_oracle_base_v2.json` (survie `pf_rm_er`
     remonte à 0.75) ; `danger_zone_oracle_base_v1.json` conservé intact comme trace historique.
  4. **Danger trop rare pour produire un signal** : avec 6 zones et `danger_zone_safety_radius`
     12 m autour de 30 ronciers (carte 160×160), `eviter`/`ignorer`/`aleatoire` produisaient des
     résultats strictement identiques sur la majorité des seeds (le danger n'est presque jamais
     sur la trajectoire naturelle). Diagnostic densité (10/15/20 zones, aucun échec de placement
     même à 20) : tendance **monotone claire** — à 20 zones `eviter` devient la meilleure
     politique (0.58, devant `ignorer` 0.50), critères du gate progressent 6→7/12, 3→6/12,
     2→5/12 — mais toujours sous les seuils requis (9-10/12). Session arrêtée ici sur décision
     utilisateur ; prochaine étape = pousser 25/30/40 zones (action P1 ci-dessus).
- Nouvel outil `tools/check_danger_calibration.py` : implémente les 4 critères du gate causal
  Phase 3 (coût eviter<viser ≥10/12, résultat eviter>viser ≥9/12, résultat eviter>aleatoire
  ≥9/12, survie meilleure politique ∈[0.50,0.90] et pire ≤0.40) sur un dossier de campagne,
  groupe par point de grille, classe les candidats. Réutilisable pour la suite de la Phase 3 et
  la Phase 4 (seeds réservés).
- `experiments/campaigns/danger_zone_oracle_v3.json` amendé : le bras `pf_rm_er` (contrôle sans
  danger) en a été retiré — un override de bras sur `danger_zone_count` est toujours écrasé par
  la grille (`run_campaign.py` applique bras puis grille, la grille l'emporte sur un chemin
  commun). Sorti dans `danger_zone_oracle_v3_control.json` (grille vide, 1 seul point).
  Campagnes créées cette session, toutes sur les 12 seeds de calibration uniquement :
  `danger_zone_reaction_range_probe_v1.json` (base v1, obsolète), `_v2.json` (base v2),
  `danger_zone_base_recalibration_probe_v1.json` (balayage `hunger_depletion_rate`),
  `danger_zone_density_probe_v1.json` (10/15/20 zones). Tous les `results/_danger_zone_*`
  associés existent en local (gitignorés, non committés) avec leur `gate_report.json`.
- `roadmap_apprentissage_v2.md` : Phases 0-3 [FAIT], Phases 4-6 [NON ENGAGÉE]. Bandeau
  « AXE SUSPENDU » en tête. Ne pas relancer M2 v2 / M3 / Phases 4-6 avant le gate v3 réservé.
- `politique_fixe_max_v1` dépend de l'environnement : `pf_er_rm` sur v1 (0,83), `pf_rm_er` sur
  v2 (0,58 sur les seeds de calibration v2 d'origine — 0,25 puis 0,75 selon `hunger_depletion_rate`
  sur les 12 seeds de calibration v3, cf. point 3 ci-dessus : variance inter-seed forte, à garder
  en tête pour toute mesure future sur un nouveau jeu de seeds).
- Vie médiane inutilisable comme métrique de résultat sur v2 : saturée à 300 dès que
  survie ≥ 0,5. Seules survie et mûres mangées discriminent.
- `results/` gitignoré. `pf_er_er` crashe Godot sporadiquement sous forte charge (jobs 6+) —
  contourné par `--retries`.
- `game_speed` x1/x4 : divergence sur le décideur adaptatif documentée (`.claude/memory.md`).
- Ollama : ne pas supposer qu'il tourne. `D:\Ollama\ollama.exe`, `gemma3:1b`, `ollama serve`.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 18e confirmation.
- `scripts/adaptive_decider_v1.gd` : ne pas supprimer tant que la suspension n'est pas définitive.
- `AGENTS.md` / `GEMINI.md` : modifiés hors session (réalignement `.claude/CLAUDE.md`), toujours en
  résidus non commités — à revoir/committer à part, hors périmètre de cette session.

## Dernière session (2026-09-08)

# Session du 2026-09-08

## Décisions prises
- Phase 3 de `roadmap_environnement_apprenable_v3.md` engagée : gate causal jamais franchi, mais
  3 causes d'échec en cascade diagnostiquées et corrigées/amendées (bug tirage `aleatoire`,
  surcouche danger trop invasive, plafond de survie sous 0,50 hors danger, densité insuffisante).
- Amendement du contrat de base Phase 0 : `danger_zone_oracle_base_v2.json` créé
  (`hunger_depletion_rate` 0,70), v1 conservé intact. Décision actée avec l'utilisateur.

## Livrables produits ou modifiés
- Modifiés : `scripts/variable_registry.gd` (`aleatoire`, `danger_reaction_range`),
  `scripts/fixed_policy_decider.gd` (tirage tenu sur intervalle), `scripts/character.gd`
  (`danger_reaction_range`, filtre dans `_danger_response_direction`, rng_seed transmis),
  `tools/run_manual_checks.gd` (13 tests ajoutés), `experiments/campaigns/danger_zone_oracle_v3.json`
  (bras `pf_rm_er` retiré).
- Créés : `tools/check_danger_calibration.py`, `experiments/danger_zone_oracle_base_v2.json`,
  `experiments/campaigns/danger_zone_oracle_v3_control.json`,
  `danger_zone_reaction_range_probe_v1.json`/`_v2.json`,
  `danger_zone_base_recalibration_probe_v1.json`, `danger_zone_density_probe_v1.json`.

## Hypothèses validées / invalidées
- INVALIDE : le mécanisme de danger calibré en Phases 0-2 passe le gate causal Phase 3 tel quel.
- VALIDE : les 3 corrections identifiées (reaction_range, hunger_depletion_rate, densité) vont
  chacune dans le bon sens, avec une tendance monotone claire sur la densité (10→15→20 zones).
- EN ATTENTE : aucun point testé ne franchit encore les 4 critères du gate.

## Prochaine étape exacte
Pousser le probe de densité à 25/30/40 zones (même point fixe par ailleurs) pour voir si la
tendance monotone franchit les seuils du gate causal, ou plafonne.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
