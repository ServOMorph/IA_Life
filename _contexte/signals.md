# Signals — ia_life (MAJ 2026-08-29)

## Actions ouvertes

- [P1|ouvert] Démarrer la Phase 1 de `roadmap_apprentissage.md` : squelette
  `scripts/adaptive_decider.gd` (3ᵉ valeur `"adaptatif"` de `decider_type`, dispatch dans
  `character.gd::_build_decider()`, variables `learning_rate`/`exploration_epsilon` au registre,
  ε-greedy seedé, pas encore de mise à jour), + tests dans `tools/run_manual_checks.gd`.
  fait quand: Phase 1 faite, tests verts, checkpoint `/compact` atteint.
  réf: roadmap_apprentissage.md (Phase 1), scripts/baseline_decider.gd, scripts/character.gd (L114, L210), scripts/variable_registry.gd (L39)
- [P3|ouvert] Supprimer le dossier vide `ROBERTO/com_telephone/voice-code-bridge/` (rmdir bloqué
  par un handle Windows pendant la session du 2026-08-28).
  fait quand: `rmdir` réussit (fermer l'IDE si besoin pour libérer le handle).
  réf: ROBERTO/com_telephone/.gitignore (commentaire)
- [P3|ouvert] `_docs/captures/` (captures d'écran envoyées depuis le téléphone) non tracké et
  non ignoré — décider gitignore ou purge.
  fait quand: entrée ajoutée au `.gitignore` racine, ou dossier vidé.
  réf: .gitignore racine

## Contexte chaud

- Axe d'évolution suivant retenu (2026-08-29) : **apprentissage individuel**, option 1B
  (« heuristiques apprises ») — le personnage apprend pendant sa vie quelle action de recherche
  de nourriture marche selon sa situation de faim, via une table `(situation, action) → score`.
  Options 1A (évolution/sélection) et 1C (RL formel) écartées pour l'instant. Plan :
  `roadmap_apprentissage.md`, Phase 1 non démarrée.
- Périmètre 1B figé : besoin = faim uniquement (seul besoin implémenté) ; situations S1 roncier
  visible / S2 en mémoire seulement / S3 rien de connu ; actions = goals `ronce_visible`,
  `ronce_memorisee`, `errance` ; ε-greedy seedé par perso ; MAJ en moyenne mobile ; un seul
  apprenant (perso 0) ; pas de persistance entre vies.
- Risque principal de 1B : si la discrétisation en 3 situations est trop grossière,
  l'apprentissage plafonnera bas — à réévaluer avant de conclure si le gate Phase 3 stagne.
- 2026-08-28 : le pont vocal `com_telephone` est hébergé par le projet Roberto
  (`D:\ServOMorph\Roberto\com_telephone\`). IA_Life en est un projet **raccordé** : `POST /send`
  exige `"project": "ia_life"` et un `"text"` non vide. Mise en écoute : commande `/roberto`
  (surveille `...\Roberto\...\logs\messages_ia_life.log`, verrou `_commands/monitor_ia_life.lock`).
  Détail : `D:\ServOMorph\Roberto\roadmap_com_telephone_hub.md`.
- Convention `!<commande>` et règle des deux canaux : dans `.claude/CLAUDE.md` (section
  "Bridge ROBERTO", chemins Roberto).
- Message "salut" reçu du log téléphone → répondre avec une phrase de
  `...\Roberto\...\server\salutations.json`, pas une formule générique (préférence utilisateur).
- Écart connu : `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) —
  reconfirmé le 2026-08-29 (neuvième fois).
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés ; non trackés, à nettoyer manuellement si souhaité.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) : non tracké, ne pas committer.
- `DOCUMENTATION/RL/report-source.md` : non tracké, à trier avec l'agent documentaire.
- Ollama tourne en arrière-plan (`gemma3:1b`, référence stable du décideur LLM).
- Simulation : Phases 1 à 8 du laboratoire closes ; `roadmap_experimentation.md` n'a plus de
  phase suivante — le prochain axe est `roadmap_apprentissage.md`.

## Dernière session (2026-08-29)

# Session du 2026-08-29

## Décisions prises
- Axe d'évolution du projet retenu : apprentissage individuel (option 1B, « heuristiques
  apprises »). Le personnage apprend pendant sa vie quelle action de recherche de nourriture
  marche selon sa situation de faim. Options 1A (évolution/sélection) et 1C (RL formel) écartées
  pour l'instant.
- Périmètre du premier chantier figé : besoin = faim uniquement, 3 situations, 3 actions (goals
  `ronce_visible` / `ronce_memorisee` / `errance`), ε-greedy seedé, MAJ en moyenne mobile, un
  seul apprenant (perso 0), pas de persistance entre vies.

## Livrables produits ou modifiés
- `roadmap_apprentissage.md` : créé (4 phases, Phase 1 [EN COURS] non démarrée, checkpoints /compact).
- `roadmap_experimentation.md` : section « Prochain sprint » renvoie vers `roadmap_apprentissage.md`.

## Hypothèses validées / invalidées
- EN ATTENTE : la discrétisation en 3 situations est-elle assez fine pour que l'apprentissage
  progresse (gate Phase 3) — risque principal identifié.

## Prochaine étape exacte
Lancer la Phase 1 de `roadmap_apprentissage.md` : squelette `adaptive_decider.gd` (dispatch,
variables au registre, ε-greedy seedé, pas de MAJ) + tests dans `tools/run_manual_checks.gd`.

## Question bloquante pour la session suivante
Aucune (roadmap validée dans son principe ; démarrage Phase 1 en attente de feu vert).

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
