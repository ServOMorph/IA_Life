## v0.28 — 2026-09-01

### Ajouté
- `roadmap_environnement_apprenable_v3.md` : plan en six phases pour introduire des zones
  dangereuses localisées, prouver leur valeur stratégique par un oracle fixe, calibrer sur
  12 seeds et confirmer sur 12 seeds réservés avant toute reprise de l'apprentissage.
- Décision `_docs/decisions/2026-09-01_environnement-apprenable-v3-zones-dangereuses.md` et entrée
  d'index : la v2 reste suspendue tant que le gate réservé v3 n'est pas franchi.

### Modifié
- `roadmap_apprentissage_v2.md` : chemin de déblocage documenté (Phase 3b danger, baseline v3,
  reprise à la Phase 4 seulement après validation de l'environnement).
- `roadmap_apprentissage.md` close déplacée dans `_docs/archives/` ; résidus temporaires de la
  racine supprimés et action correspondante close.

## v0.27 — 2026-09-01

### Modifié
- **Axe apprentissage individuel suspendu** (branche « Échec » de `roadmap_apprentissage_v2.md`).
  Après Phases 2-3 et enrichissement de l'environnement, `adaptatif_courant` ne se sépare pas de
  la sélection aléatoire ni du bras gelé `adaptatif_v1` au seed apparié (M1 v2 : survie 4-3/12,
  mûres 4-6/12 vs `aleatoire`). Une table `(situation, action)` discrète ne bat pas le hasard
  sur cette tâche. Phases 4-6 non engagées, code Phases 2-3 conservé.

### Ajouté
- Phase 2 — `scripts/adaptive_decider.gd` : récompense événementielle (`PICK_REWARD` +1 par
  cueillette, `survival_cost_rate` −c·Δt, `TERMINAL_REWARD` −1) et amorçage par différence
  temporelle (`cible = r + td_discount_gamma·maxQ(s',·)`, γ 0,9) en remplacement de la moyenne
  mobile de variation de faim. `TABLE_SCHEMA_VERSION`, `available_count` dans `apprentissage_decision`.
- Phase 3 — S3 (inconnu) passe de 1 à 5 actions (`errance`, `cap_maintenu`, `demi_tour`,
  `zone_inconnue`, `zone_connue`), S2 gagne `souvenir_ancien`. `fixed_policy_s3` pour
  `politique_fixe`. `character.gd` : directions candidates (`old_memory_direction`,
  `unknown_zone_direction`, `known_zone_direction`) dans l'observation.
- `experiments/apprentissage_env_ref_v2.json` : environnement de référence GELÉ v2
  (`eat_hunger_threshold` 90 — retrait du tampon de digestion différée, `hunger_depletion_rate`
  0,9). Rupture de comparaison M0 v1 → Mf v1 assumée.
- `tools/benchmark_report.py` : part multi-action réelle via `available_count` ; sign tests
  appariés ; non-régression bras gelés vs baseline.
- Campagnes : `p3_oracle`, `p3b_env_probe`, `benchmark_apprentissage_m0_v2`,
  `benchmark_apprentissage_m1_v2` ; selftests `p2_adaptive_selftest`, `p3_adaptive_selftest`.
- `_docs/decisions/2026-09-01_phase2-signal-recompense-td.md` (validé),
  `_docs/decisions/2026-09-01_phase3-bifurcation-suspension-axe-apprentissage.md` (validé) + INDEX.

## v0.26 — 2026-09-01

### Ajouté
- `scripts/fixed_policy_decider.gd` : `FixedPolicyDecider` (extends `AdaptiveDecider`) —
  politique déterministe figée sur l'espace d'action courant, aucune mise à jour de score.
  `decider_type: politique_fixe`, variables `fixed_policy_s1` / `fixed_policy_s2`.
- `scripts/adaptive_decider_v1.gd` : bras gelé « avant » du benchmark (`decider_type:
  adaptatif_v1`), copie verrouillée de l'état 2026-08-30 du décideur adaptatif.
- `tools/run_campaign.py` : parallélisme (`--jobs`, `--retries`, `--warmup`, isolation des
  fichiers de sortie, reproduction bit à bit du séquentiel) et bras nommés (`"arms"` :
  jeux d'overrides appliqués par-dessus la base, `metadata.arm`).
- `tools/oracle_report.py` : évaluateur du gate Phase 1 (survie / vie médiane / mûres par bras
  et environnement, meilleure vs pire politique fixe, test des signes apparié au seed).
- `tools/check_fixed_policy.py`, `tools/check_campaign_parallelism.py`,
  `tools/check_adaptive_v1_equivalence.py` : gates de non-régression.
- `experiments/apprentissage_env_ref.json` : environnement de référence GELÉ de
  `roadmap_apprentissage_v2` (`vision_range` 15, `hunger_depletion_rate` 0,7, `ronce_count` 30).
- `experiments/campaigns/benchmark_apprentissage.json` : 9 bras, 12 seeds d'entraînement +
  12 seeds réservés énumérés. Mesure M0 « avant » prise.
- `_docs/decisions/2026-08-31_calibrage-environnement-oracle.md` + `INDEX.md` : Phase 1 v2,
  gate franchi (`pf_er_rm` 0,83 vs `pf_er_er` 0,17), bit apprenable = décision S2.

### Modifié
- `roadmap_apprentissage_v2.md` : Phases 0 et 1 passées à [FAIT] ; note de travail
  « manger au contact » (Variante C, conditionnelle à un échec de gate) en Phase 1.
- `scripts/variable_registry.gd`, `scripts/character.gd` : `decider_type` gagne
  `adaptatif_v1` et `politique_fixe` ; dispatch et hooks de fin de vie associés.
- `tools/aggregate_results.py` : `arm` intégré à la clé de regroupement et au CSV.
- `.claude/memory.md` : note `game_speed` x1/x4 diverge sur le décideur adaptatif (limite
  connue, campagnes de la roadmap à `game_speed` 1,0).

## v0.25 — 2026-08-30

### Ajouté
- `roadmap_apprentissage_v2.md` : succède à `roadmap_apprentissage.md`. Diagnostic en 5 défauts
  structurels de l'apprentissage intra-vie (≈ 1 bit apprenable par vie, récompense quasi
  constante hors repas, aucune propagation du crédit, S3 sans choix sur 63 % des décisions,
  gate posé sur le `reward` interne). 7 phases : débit expérimental (parallélisme reproductible),
  calibrage de l'environnement + oracle de politiques fixes, récompense événementielle +
  amorçage TD, élargissement de l'espace d'action, persistance de table entre vies, protocole
  statistique verrouillé, approximation de fonction conditionnelle. Section benchmark
  avant/après : 6 bras figés, 12 seeds d'entraînement + 12 réservés, mesures M0 à Mf, critère
  de succès écrit à l'avance, budget ≈ 2000 runs.

### Modifié
- `roadmap_apprentissage.md` : bandeau de renvoi vers la v2 (roadmap close).
- `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md` + `INDEX.md` : statut `invalidé`,
  section « Suite » pointant vers `roadmap_apprentissage_v2.md`.
- `roadmap_roberto_multiprojet.md` -> `_docs/archives/2026-08-28_roadmap_roberto_multiprojet.md`
  (pont assistant vocal migré vers le projet Roberto le 2026-08-28).
- `roadmap_experimentation.md` -> `_docs/archives/2026-08-29_roadmap_experimentation.md`
  (Phases 0-8 closes ; points d'attention orphelins repris dans la roadmap v2).

## v0.24 — 2026-08-30

### Ajouté
- `roadmap_apprentissage.md` Phase 2 : récompense sur la fenêtre d'engagement (variation de
  faim normalisée, bornée `[-1, 1]`), mise à jour en ligne `score += lr × (reward − score)`,
  pénalité terminale unique à la mort de faim, logs `apprentissage_decision` /
  `apprentissage_maj` / `apprentissage_table`. Hooks fin de vie dans `character.gd` et
  `main.gd`. 2 tests dans `tools/run_manual_checks.gd`.
- `tools/aggregate_results.py --learning-curve` : courbe d'apprentissage du décideur
  adaptatif à partir des `.jsonl` (taux de décisions de faim réussies et `reward` moyen en
  fenêtre glissante, pentes, volatilité fenêtre-à-fenêtre, `reward` 1re vs 2e moitié de vie,
  test d'égalité stricte des suites de récompense par bras de campagne).
- `tools/plot_learning_curve.py` : courbes SVG sans dépendance (taux de réussite et `reward`
  moyen vs temps simulé, une ligne par bras).
- `experiments/apprentissage_faim_v1.json` + `campaigns/apprentissage_faim_v1.json` (Phase 3,
  learner vs contrôle aléatoire au même seed) ; `experiments/apprentissage_faim_v2.json` +
  `campaigns/apprentissage_faim_v2_sweep.json` (Phase 4, balayage `learning_rate` ×
  `exploration_epsilon` sur 2 seeds).
- `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md` (Phases 3-4) + ligne INDEX.

### Modifié
- `roadmap_apprentissage.md` : Phases 2, 3, 4 passées à [FAIT] ; roadmap terminée côté code.
  Phase 3 gate recalibré (bras de contrôle `exploration_epsilon` 1,0, `vision_range` 15) :
  franchi sur le seed testé. Phase 4 : l'avantage intra-vie ne généralise pas sur 2 seeds,
  `learning_rate` sans effet mesurable — bifurcation d'axe à trancher (`signals.md`).
- `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md` : tableau
  `llm_vs_automate_v1` rejoué post-correction (15 runs, Ollama réel) — pas de régression.
- `experiments/README.md` : section « Courbe d'apprentissage du décideur adaptatif ».

## v0.23 — 2026-08-30

### Ajouté
- `scripts/adaptive_decider.gd` : Phase 1 de `roadmap_apprentissage.md` close — décideur
  adaptatif (discrétisation S1/S2/S3, table ε-greedy, engagement sur l'action choisie via
  `adaptive_decision_interval_seconds` plutôt qu'une décision à chaque frame physique). 15
  vérifications ajoutées à `tools/run_manual_checks.gd`.

### Corrigé
- `scripts/baseline_decider.gd`, `scripts/llm_decider.gd` : seuil de recherche de nourriture
  inversé (`hunger > pickup_hunger_threshold` au lieu de `<=`) — l'automate de référence ne
  cherchait jamais sa nourriture en ayant faim.
- `scripts/ronce.gd`, `scripts/character.gd` : aucune condition ne faisait sortir un agent d'un
  objectif de cueillette atteint (récolte déclenchée une seule fois à l'entrée en zone, pas de
  vérification d'inventaire plein dans les décideurs) — cueillette rendue continue tant que
  l'agent est au contact, `max_berries_carried` ajouté à l'observation. Six campagnes de
  référence rejouées à seeds identiques pour validation — détail :
  `_docs/decisions/2026-08-29_correction-seuil-recherche-nourriture.md`.

## v0.22 — 2026-08-29

### Ajouté
- `roadmap_apprentissage.md` : axe d'évolution suivant retenu — apprentissage individuel
  (option 1B, « heuristiques apprises »). Un décideur `adaptive_decider.gd` (3ᵉ valeur de
  `decider_type`) apprend en une vie, via une table `(situation, action) → score` en moyenne
  mobile, quelle action de recherche de nourriture marche selon la situation de faim. Périmètre
  fixé : faim uniquement, 3 situations, 3 actions (goals `ronce_visible` / `ronce_memorisee` /
  `errance`), ε-greedy seedé, un seul apprenant (perso 0), pas de persistance entre vies.
  4 phases avec checkpoints ; Phase 1 non démarrée. Options 1A (évolution/sélection) et 1C
  (RL formel) écartées pour l'instant.

### Modifié
- `roadmap_experimentation.md` : la section « Prochain sprint » renvoie vers
  `roadmap_apprentissage.md` (plus de Phase 9 dans cette roadmap).

## v0.21 — 2026-08-28

### Modifié
- Assistant vocal `com_telephone` : le pont (serveur Node + STT + TTS + tunnel + PWA) a été migré
  vers le projet Roberto, qui en devient l'hôte et le template de référence. IA_Life est
  désormais un projet **raccordé** : `ROBERTO/com_telephone/` réduit à un README de raccordement,
  la commande `/roberto` (surveille `messages_ia_life.log` chez Roberto) et une section
  « Bridge ROBERTO » réécrite dans `.claude/CLAUDE.md`.
- Serveur, PWA et `com_manager` retirés du dépôt IA_Life (`git rm --cached` + suppression disque) ;
  reliquats restants gitignorés.

### Corrigé
- Clôt l'action ouverte sur l'inclusion git de `ROBERTO/com_telephone` : le bridge n'est plus
  versionné dans IA_Life (il l'est dans Roberto).

## v0.20 — 2026-08-27

### Ajouté
- Phase 8 (vision et perception générique) : contrat de perceptibilité générique, fonction de
  vision (portée, angle, occlusion), 3 nouvelles variables au registre (`vision_range`,
  `vision_angle_degrees`, `vision_blocked_by_terrain`), mémorisation et priorité "visible >
  mémorisé" sur l'automate et le LLM. `social_radius` absorbé comme cas particulier de la
  vision (code partagé `Character._perceive`), équivalence stricte démontrée sur les 3
  scénarios sociaux Phase 6.
- Métriques de perception (`vision_detections_total`, `ronces_discovered_by_vision_total`,
  délai vision→contact) dans le résumé de run et `tools/aggregate_results.py`.
- 6 tests unitaires vision dans `tools/run_manual_checks.gd` ; 4 scénarios comparatifs
  portée/angle/occlusion et une campagne multi-seeds `vision_range` dans `experiments/`.

### Corrigé
- Bug de mémorisation par vision : déclenchée à chaque frame, elle bouclait indéfiniment
  quand plus d'entités étaient visibles simultanément que `memory_capacity`. Corrigée
  (déclenchement une fois par apparition, pas par frame).

## v0.19 — 2026-08-26

### Ajouté
- Roadmap : Phase 8 (Vision et perception générique de l'environnement) ajoutée en [TODO] —
  remplace la découverte de ressources par contact physique seul, généralise la perception à
  distance à n'importe quelle entité (ronciers, agents, objets futurs), prévoit l'absorption de
  `social_radius` sous condition d'équivalence démontrée.

### Corrigé
- `scripts/variable_registry.gd` : défaut `llm_model` corrigé (`gemma3:4b` -> `gemma3:1b`),
  désaligné de la décision Phase 7 (modèle de référence stable retenu après effondrement de
  `gemma3:4b`).

## v0.18 — 2026-08-26

### Ajouté
- ROBERTO (`com_telephone`) : convention `!<commande>` — un message envoyé depuis le téléphone
  préfixé par `!` (ex. `!close`) déclenche directement la procédure Claude Code correspondante,
  actions git comprises. Documentée dans `ROBERTO/com_telephone/README.md` et inlinée dans
  `CLAUDE.md` (section "Bridge ROBERTO").

### Corrigé
- ROBERTO : cause racine du bug d'injoignabilité du téléphone identifiée et corrigée — la
  constante `VAPID_PUBLIC_KEY` codée en dur côté client ne correspondait pas à `VAPID_PUBLIC`
  du serveur (pas un problème de cache navigateur). Reconnexion WebSocket automatique au retour
  au premier plan, détection ping/pong des connexions mortes côté serveur, purge automatique
  des souscriptions push obsolètes. Notification push et reconnexion validées en conditions
  réelles (écran verrouillé).

## v0.17 — 2026-08-26

### Ajouté
- Phase 7 close : décideur de personnage interchangeable (`automate`/`llm`/`llm_mock`) via
  `scripts/llm_decider.gd`, backend Ollama local, repli automatique sur l'automate en cas de
  timeout/erreur/indisponibilité réseau. L'intention "manger" route via `memory_direction`
  (même précision de visée que l'automate). Logging complet prompt/réponse.
- `VariableRegistry` : support des types `enum`/`string` (nouvelles variables `decider_type`,
  `llm_model`, `llm_decision_interval_seconds`, `llm_timeout_seconds`).
- Scénarios et campagne comparative : `experiments/llm_mock_smoke_v1.json`,
  `experiments/llm_vs_automate_v1.json`, `experiments/campaigns/llm_vs_automate_v1.json`.

### Modifié
- `tools/aggregate_results.py` : métriques LLM agrégées (appels, taux d'erreur, latence).
- `scripts/ui_manager.gd` : correctif d'affichage de l'Inspecteur pour les types texte.

### Corrigé
- `HTTPRequest` threadé restait bloqué jusqu'au timeout dans la scène complète (contention du
  `WorkerThreadPool` de Godot) — corrigé par `use_threads = false`.
- Modèle `gemma3:4b` écarté après effondrement sur une réponse fixe indépendante du contexte ;
  `gemma3:1b` retenu comme référence (voir `_docs/decisions/2026-08-26_decideurs-interchangeables-llm.md`).

## v0.16 — 2026-08-25

### Ajouté
- Phase 6 close : trois mécaniques sociales avancées — communication (partage inconditionnel
  d'une position de roncier mémorisée), coopération (partage de nourriture si faim critique de
  l'autre) et agressivité (répulsion imposée), chacune avec sa variable dans `VariableRegistry`.
- Scénarios de validation dédiés : `experiments/social_communication_smoke_v1.json`,
  `social_cooperation_smoke_v1.json`, `social_aggression_smoke_v1.json`.

### Modifié
- `scripts/main.gd`, `tools/aggregate_results.py` : nouvelles métriques sociales exportées et
  agrégées (partages, réceptions, incidents d'agressivité).
- Roadmap : Phase 6 marquée [FAIT], Phase 7 (LLM) débloquée.

### Corrigé
- ROBERTO (`voice-code-bridge`) : la demande de permission de notification push n'était
  déclenchée que par le bouton micro, jamais par l'envoi de texte — corrigé. Ajout d'un
  système de choix rapide par boutons dans l'appli mobile.

## v0.15 — 2026-08-25

### Ajouté
- Trois campagnes de référence (`memory_capacity`, `resource_scarcity`, `contrasted_profiles`)
  et `tools/plot_campaign.py` (graphiques SVG sans dépendance externe) — clôture de la Phase 4.
- Inspecteur générique dans l'UI, piloté par `VariableRegistry` (sélecteur agent/catégorie,
  tags live/dynamique/nécessite-relancer) — clôture de la Phase 5.

### Modifié
- `tools/aggregate_results.py` : métriques `mean_memorized_ronces`, `mean_berries_picked`,
  `mean_berries_eaten` ajoutées.
- Panneaux de coin allégés (Vitesse, Vieillissement, Capacité à se nourrir, Mémoire déplacés
  vers l'Inspecteur) ; confirmation ajoutée avant "Relancer".

### Corrigé
- ROBERTO (`voice-code-bridge`) : script de salutation automatique retiré, le message "salut"
  remonte désormais normalement vers l'agent ; bouton copier ajouté sur les réponses de
  l'appli mobile.

## v0.14 — 2026-08-25

### Corrigé
- `ROBERTO/com_telephone/_commands/com_manager.md` : libération du port 5000 avant tout
  démarrage/redémarrage de `node`, pour éviter l'échec EADDRINUSE causé par un process
  orphelin non tracké.

## v0.13 — 2026-08-24

### Ajouté
- Contrôles automatisés de reproductibilité et de cohérence entre télémétrie JSONL et summary.
- Scénarios de comparaison pour `goal_persistence`, `known_zone_preference` et `curiosity`.

### Modifié
- Les expériences sont bornées par `max_simulation_seconds` ; `max_wall_seconds` reste un alias de migration.
- Configuration fixe et état initial dynamique sont distingués dans `ExperimentConfig`.

## v0.12 — 2026-08-24

### Ajouté
- Launcher `run_rl.py` pour le mode RL (`IA_LIFE_RL_MODE`) ; premier épisode complet validé
  via `rl/client_random.py`.
- Tests automatisés `ExperimentConfig` (défauts, overrides, validation) dans
  `tools/run_manual_checks.gd`.

### Modifié
- `VariableRegistry` enrichi (libellé, description, portée, catégorie, défaut, dynamique,
  live_editable) ; `GameConfig` et `Character` lisent leurs valeurs par défaut depuis le
  registre.
- `DESIGN/roadmap_graphisme.md` et son contexte réconciliés avec l'état réel (Phases 2-5
  closes).

### Décidé
- Cadre non historique (île isolée) retenu pour l'identité du jeu — voir
  `DOCUMENTATION/orientation_contexte.md`.

## v0.11 — 2026-08-23

### Ajouté
- Contrat d'expérience versionné, validation des variables, événements environnementaux,
  campagnes reproductibles, logs JSONL, résumés et agrégation de résultats.
- Perception sociale, suivi et évitement paramétrables avec métriques dédiées.
- Dossier DOCUMENTATION et commande `python tools/run_smoke_tests.py`.

### Modifié
- Le rig Blender est officiellement réservé au personnage de développement.

## v0.9 — 2026-08-22

### Modifié
- Ronces refondues visuellement : buisson vert réaliste (7 lobes, couleur fixe qui ne
  change plus quand le roncier est vide) + mûres noires visibles sur le buisson (une
  sphère par mûre restante), retrait visuel d'une mûre à chaque cueillette ; suppression
  de la bascule plein/vide par matériaux.
- Sliders "Capacité à se nourrir" / "Mémoire" dans le panneau "Personnage de test" (mode
  dev) et détail de test scrollable dans la checklist.

### Validé
- Test manuel 5 ("Capacité à se nourrir" : gain de PV proportionnel au slider) confirmé
  en jeu et retiré de `tests_manuels.md` — restent les items 6, 8-12.

## v0.8 — 2026-08-18

### Ajouté
- Personnage riggé (Phase 5 graphisme) : armature + animations Idle/Walk/Death générées via
  Blender headless (`tools/blender/build_character.py` -> `assets/models/character.glb`),
  intégré uniquement sur le personnage de test (mode dev).
- Blender installé localement (`D:\blender`) pour régénérer le modèle sans dépendance
  externe.
- Touche K (mode dev) : tue le personnage de test à la demande (vérifie l'animation Death).
- Touche G (mode dev) : force la faim haute (déclenche la cueillette). Shift+F1-F4 :
  téléporte un personnage au contact de la ronce la plus proche (F1-F4 seul téléporte
  désormais au centre de la map).
- Persistance des réglages du jeu sur disque (`GameConfig`, `logs/game_config.json`) et
  nouveau réglage "Intensité lumineuse".

### Modifié
- Checklist en jeu (Phase 3 mode dev) : sélection individuelle par test (panneau détail
  Valide/Invalide/Fermer) au lieu d'un formulaire global, état persisté par test
  (`logs/dev_checklist_state.json`), masquage automatique des tests déjà validés.
- Caméra orbite (personnage de test) : correctif du pitch inversé, clamp au-dessus du
  terrain.

### Corrigé
- Items 1-4 de `tests_manuels.md` (bascule ronce, animation procédurale des 4 personnages,
  cueillette/consommation de base) validés et retirés après confirmation en jeu.

## v0.7 — 2026-08-18

### Ajouté
- Phase 3 du mode dev : checklist de tests manuels en jeu (touche T), sauvegarde des
  résultats dans `logs/dev_session_<horodatage>.json`.
- Personnage de test contrôlable manuellement (mode dev) : touche F5, déplacement ZQSD
  relatif à une caméra en orbite 3e personne pilotée à la souris, immortel. Remplace la
  dépendance à la téléportation F1-F4 seule pour observer cueillette/collision en direct.
  Panneau "Personnage de test" (mûres portées/ramassées, faim) en bas d'écran.
- Suivi caméra automatique lors d'une téléportation F1-F4.
- Aplanissement léger du terrain autour du spawn central (personnage de test).

### Modifié
- Touches dev réaffectées : H = forcer faim basse (repas), E = réservée à une future
  action du personnage de test (aucun effet pour l'instant).
- Luminosité ambiante réduite de 10%.

### Corrigé
- Propriété invalide `directional_shadow_normal_bias` (Godot 4.5) -> `shadow_normal_bias`.

## v0.6 — 2026-08-17

### Ajouté
- Mode dev (`run_dev.py`, `IA_LIFE_DEV_MODE`) : raccourcis clavier de déclenchement
  contrôlé (geler/reprendre la simulation, avancer d'une frame, forcer la faim,
  téléporter un personnage au contact d'une ronce), bandeau UX "MODE DEV" et indicateur
  "Temps gelé" — pour tester les mécaniques bloquées en observation directe.

### Corrigé
- Scène qui apparaissait comme une scène de nuit malgré la luminosité augmentée en
  session précédente : ciel, lumière directionnelle et exposition retravaillés (vérifié
  par capture d'écran automatisée avant/après).

### Validé
- Terrain, relief, cuvettes de spawn, faim/vieillissement/mort, vitesse de simulation et
  absence de clignotement de texture d'herbe — confirmés manuellement en jeu.

## v0.5 — 2026-08-17

### Ajouté
- Capture d'écran automatisée (`run_screenshot.py`) : lance le jeu en fenêtre réelle,
  sauvegarde le viewport en PNG après un délai, permet une vérification visuelle sans
  intervention manuelle.
- Relief procédural rendu plus escarpé (amplitude 1.2 -> 5.0) et cuvettes de spawn
  (dépression douce) autour des 4 points d'apparition des personnages.
- Skill `synthese-projet` : génère un état des lieux complet du projet (personnages,
  variables du monde, carte, UX, outillage) dans `_docs/`, avec archivage automatique
  des synthèses précédentes.

### Corrigé
- Bug de rendu majeur : le terrain était invisible depuis le dessus (winding de mesh
  inversé, culling par défaut de Godot), diagnostiqué à tort au premier abord comme un
  problème de texture puis d'auto-ombrage. Corrigé par `render_mode cull_disabled` sur
  le shader triplanar.

### Modifié
- Luminosité de la scène augmentée (énergie de la lumière directionnelle, exposition du
  tonemap) — non validée visuellement de façon décisive.

## v0.4 — 2026-08-17

### Ajouté
- Matériaux PBR CC0 (Poly Haven) via shader triplanar pour le sol et les murs ; ronces
  remodelées en buisson (cluster de sphères).
- Animation procédurale des personnages : orientation vers la direction de déplacement,
  bobbing de marche, animation de mort progressive (tween).
- Cycle caméra 3 clics sur le nom d'un personnage : 3e personne, 1re personne ("yeux",
  regard souris contraint à ~±90° de lacet / ~±63° de tangage relatif au corps), retour
  exact à la caméra précédente.
- Terrain à relief procédural (bruit simplex + `HeightMapShape3D`, aplani en bordure de
  map) et décor procédural (rochers, arbres), en remplacement du sol plat — choisi plutôt
  que le plugin Terrain3D pour rester cohérent avec l'approche "tout par code" du projet.

### Connu
- Clignotement occasionnel de la texture d'herbe non résolu (aliasing spéculaire probable).

## v0.3 — 2026-08-17

### Ajouté
- Cueillette de mûres (ronces) : cueillette/consommation automatiques selon seuils de
  faim, capacité à se nourrir par personnage, modale "Données du jeu" configurable en
  direct (`GameConfig`).
- Mode headless (`run_headless.py`) + skills `analyse-partie`/`experimentation-headless`
  pour tester des réglages sans interface.
- Logging complet de session (`GameLogger`), archivé dans `logs/`.
- Mémoire spatiale des ronciers par personnage (capacité 0-10, renforcement/oubli
  progressif), avec retour ciblé vers le roncier mémorisé le plus proche en cas de faim.
- Collision physique des ronces (`StaticBody3D`), en complément de la détection.

### Modifié
- Vitesse de simulation étendue jusqu'à x50 (plafond headless recommandé x80).
- Caméra : suivi continu d'un personnage + zoom molette, bouton "Large" pour revenir au
  plan d'ensemble.
- Panneaux perso toujours visibles avec sections repliables ; distribution équitable des
  ronces par quadrant de map.

## v0.2 — 2026-08-17

### Ajouté
- Analyse du rendu graphique actuel et pistes d'amélioration gratuites (DESIGN/pistes_graphisme.md).
- Roadmap graphisme en 6 phases (DESIGN/roadmap_graphisme.md).

### Modifié
- Contrainte "personnages sans animation" levée — animation (marche/idle) intégrée au plan.

## v0.1 — 2026-08-17

### Ajouté
- Scaffold Godot programmatique : map 160x160, 4 personnages lowpoly, murs, caméra libre
  ZQSD, `run.py`.
- Déplacement aléatoire avec rebond aux collisions, zone de déplacement par personnage.
- Menu bas d'écran : panneaux de stats/édition par personnage (coins), focus caméra au
  clic, slider de vitesse de simulation globale, bouton de reset complet.
- Système de faim/vieillissement/mort par personnage.
- Archive des décisions d'évolution (`_docs/decisions/`).
## v0.10 — 2026-08-23

### Ajouté
- Suite automatisée `tools/run_manual_checks.py` pour les tests de paramètres et de mémoire
  (6, 8, 9, 10 et 11).
- Touche E du personnage de test : ramasse une mûre proche en mode dev.

### Corrigé
- Retrait du log de diagnostic temporaire du déplacement ; enfoncement visuel des personnages
  et rendu des ronces/mûres validés.

### Modifié
- Roadmap du mode dev clôturée et archivée dans `_docs/archives/2026-08-23_roadmap_mode-dev.md`.
## v0.12 — 2026-08-24

### Ajouté
- Documentation de la voie RL rapide et premier bridge TCP/JSONL avec client random.

### Modifié
- Le personnage Rouge peut recevoir une action RL `Discrete(7)` en mode `IA_LIFE_RL_MODE`.

### Corrigé
- Contrat RL : pas de décision de 0,25 s simulée et récompense de survie à +0,005/s.
