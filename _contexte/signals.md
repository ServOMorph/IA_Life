# Signals — ia_life (MAJ 2026-08-30)

## Actions ouvertes

- [P1|ouvert] Exécuter `roadmap_apprentissage_v2.md`, en commençant par la Phase 0 (débit
  expérimental : parallélisme reproductible de `tools/run_campaign.py` + gel du bras
  `adaptatif_v1`). La bifurcation d'axe est tranchée : approche par étapes (calibrage
  environnement + oracle de politiques fixes, refonte du signal avec amorçage TD, élargissement
  de l'espace d'action, persistance de table entre vies, protocole statistique), chaque phase
  gatée sur une métrique de résultat, benchmark avant/après à bras figés (M0 en fin de Phase 1,
  Mf en fin de Phase 5).
  fait quand: Mf pris et verdict M0 -> Mf prononcé (succès / succès partiel / échec).
  réf: roadmap_apprentissage_v2.md
- [P2|ouvert] Divergence `game_speed` x4 vs x1 : simulations différentes à config et seed
  identiques (séries de récompense divergentes, spans différents) sur le chemin du décideur
  adaptatif. Sortie du chemin critique de la v2 (la Phase 0 vise le débit par le parallélisme,
  pas par l'accélération), mais reste à solder : contredit la note mémoire
  `2026-08-17 — Vitesse de jeu = accélérateur de temps pur`.
  fait quand: divergence documentée comme limite connue (via /create_memory) ou corrigée.
  réf: `.claude/memory.md` (note 2026-08-17), roadmap_apprentissage_v2.md (Phase 0),
  scripts/character.gd::_physics_process, scripts/main.gd, scripts/game_speed.gd

## Contexte chaud

- `roadmap_apprentissage_v2.md` : nouvelle roadmap, toutes phases [TODO], Phase 0 à démarrer.
  7 phases (0 à 6, la 6 conditionnelle). Section benchmark : 6 bras (`automate`, `adaptatif_v1`
  gelé, `aleatoire`, `politique_fixe_max_v1`, `politique_fixe_max`, `adaptatif_courant`),
  12 seeds d'entraînement + 12 réservés, budget ~2000 runs.
- `roadmap_apprentissage.md` : close (4 phases [FAIT]), supersedée par la v2. Bandeau de renvoi
  ajouté en tête. Archivable dans `_docs/archives/` quand souhaité — laissée à la racine pour
  l'instant.
- 2 roadmaps archivées cette session : `_docs/archives/2026-08-28_roadmap_roberto_multiprojet.md`
  (pont migré chez Roberto), `_docs/archives/2026-08-29_roadmap_experimentation.md` (Phases 0-8
  closes ; points d'attention orphelins repris dans la v2).
- Ollama : ne pas supposer qu'il tourne (le `com_manager.py status` de Roberto ne le couvre pas).
  Binaire `D:\Ollama\ollama.exe`, `gemma3:1b` présent, `ollama serve` si besoin.
- `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) — 12e confirmation.
- `results/` (gitignoré) : `apprentissage_faim_v1/` et `apprentissage_faim_v2_sweep/` conservés.
  Dossiers `__pre_correction` / `__seuil_seul` + `llm_vs_automate_v1/` purgeables (revalidation
  close).
- Résidus non trackés à nettoyer manuellement : `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`,
  `.rl_godot_pid` (bridges RL abandonnés), `_docs/Analyse du projet/` (dossier vide daté),
  `DOCUMENTATION/RL/report-source.md` (à trier avec l'agent documentaire).

## Dernière session (2026-08-30)

# Session du 2026-08-30

## Décisions prises
- Bifurcation d'axe P1 tranchée : ni « affiner la discrétisation » seul, ni bascule 1C immédiate.
  Approche par étapes + benchmark avant/après verrouillé -> `roadmap_apprentissage_v2.md`.
- 2 roadmaps archivées : `roadmap_roberto_multiprojet.md` (pont migré chez Roberto),
  `roadmap_experimentation.md` (Phases 0-8 closes) -> `_docs/archives/`.

## Livrables produits ou modifiés
- `roadmap_apprentissage_v2.md` : créé — diagnostic 5 défauts, 7 phases, benchmark avant/après
  (6 bras, 24 seeds, M0 -> Mf), budget ~2000 runs.
- `roadmap_apprentissage.md` : bandeau de renvoi vers la v2 (roadmap close).
- `_docs/decisions/2026-08-30_apprentissage-intra-vie-faim.md` + INDEX : statut `invalidé`,
  note « Suite -> v2 ».

## Hypothèses validées / invalidées
- INVALIDE (diagnostic racine) : « 1B apprend de façon fiable en une vie ». ~1 bit apprenable/vie,
  récompense quasi constante (−0,32 hors repas), pas de propagation du crédit, S3 sans choix
  (63 % des décisions), gate posé sur le `reward` interne — défauts structurels, pas un réglage.
- EN ATTENTE : la tâche est-elle apprenable dans un environnement calibré ? -> Phase 1 de la v2.

## Prochaine étape exacte
Phase 0 de la v2 : parallélisme reproductible de `tools/run_campaign.py` + gel du bras
`adaptatif_v1` (`scripts/adaptive_decider_v1.gd`). `game_speed`/P2 hors chemin critique.

## Question bloquante pour la session suivante
Aucune — roadmap v2 validée, Phase 0 prête.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
