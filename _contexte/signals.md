# Signals — ia_life (MAJ 2026-08-28)

## Actions ouvertes

- [P2|ouvert] Décider de la Phase 9 (aucune définie à ce stade) ou d'un autre axe de travail.
  fait quand: nouvelle phase ajoutée à roadmap_experimentation.md et démarrée, ou décision
  explicite de ne pas en ajouter pour l'instant.
  réf: roadmap_experimentation.md (section "Prochain sprint recommandé")
- [P3|ouvert] Supprimer le dossier vide `ROBERTO/com_telephone/voice-code-bridge/` (rmdir bloqué
  par un handle Windows pendant la session du 2026-08-28).
  fait quand: `rmdir` réussit (fermer l'IDE si besoin pour libérer le handle).
  réf: ROBERTO/com_telephone/.gitignore (commentaire)
- [P3|ouvert] `_docs/captures/` (captures d'écran envoyées depuis le téléphone) non tracké et
  non ignoré — décider gitignore ou purge.
  fait quand: entrée ajoutée au `.gitignore` racine, ou dossier vidé.
  réf: .gitignore racine, ROBERTO/com_telephone/README.md (route user.image côté pont Roberto)

## Contexte chaud

- 2026-08-28 : le pont vocal `com_telephone` est désormais **hébergé par le projet Roberto**
  (`D:\ServOMorph\Roberto\com_telephone\`). IA_Life en est un projet **raccordé** : plus de
  serveur ici, juste `ROBERTO/com_telephone/README.md` + la commande `/roberto` (surveille
  `...\Roberto\...\logs\messages_ia_life.log`, verrou `_commands/monitor_ia_life.lock`).
  `POST /send` exige `"project": "ia_life"` et un `"text"` non vide (sinon HTTP 400).
  Détail migration : `D:\ServOMorph\Roberto\roadmap_com_telephone_hub.md`.
- Convention `!<commande>` (commande à distance depuis le téléphone, git compris) et règle des
  deux canaux : toujours dans `.claude/CLAUDE.md` (section "Bridge ROBERTO") — section réécrite
  le 2026-08-28 (chemins Roberto).
- Quand un message "salut"/salutation arrive depuis le log téléphone, répondre avec une phrase
  piochée dans `...\Roberto\...\server\salutations.json` plutôt qu'une formule générique —
  préférence explicite de l'utilisateur.
- Écart connu : `scripts/check_kit.py` toujours absent (étape 10 de `/close` non exécutable) —
  reconfirmé le 2026-08-28 (huitième fois).
- `.tmp_gdrl_smoke/`, `.tmp_native_rl_smoke/`, `.rl_godot_pid` : résidus des bridges RL tiers
  abandonnés (GDRL, godot-native-rl) ; non trackés, à nettoyer manuellement si souhaité.
- `_docs/Analyse du projet/` (dossier vide daté 2026-08-17) reste non tracké, origine non
  éclaircie : ne pas committer.
- `DOCUMENTATION/RL/report-source.md` : non tracké, à trier avec l'agent documentaire.
- Ollama tourne en arrière-plan (`gemma3:1b` référence stable pour le décideur LLM, y compris
  avec le prompt étendu par la Phase 8).
- Simulation : Phases 1 à 8 du laboratoire closes, aucune Phase 9 définie.

## Dernière session (2026-08-28)

# Session du 2026-08-28

## Décisions prises
- Le pont `com_telephone` est migré vers le projet Roberto (hôte du serveur + template de
  référence unique). IA_Life devient un projet raccordé : plus de serveur, README de
  raccordement + commande `/roberto`.
- `.env` d'IA_Life réutilisé tel quel sur Roberto → lien appli et abonnements push préservés.
- Reste de `ROBERTO/com_telephone/` : serveur/PWA/com_manager retirés du dépôt, reliquats
  gitignorés → clôt l'action ouverte [P2] sur l'inclusion git du bridge.

## Livrables produits ou modifiés
- `ROBERTO/com_telephone/README.md` : réécrit (raccordement au pont Roberto).
- `.claude/commands/roberto.md` : créé. `.claude/CLAUDE.md` : section « Bridge ROBERTO » réécrite.
- `ROBERTO/com_telephone/.gitignore`, `_commands/.gitignore` : créés / mis à jour.
- Serveur + PWA + `com_manager` retirés (`git rm --cached` + suppression disque, sauf 1 dossier vide).
- Commits : `866a48c`, `852e4a2`.

## Hypothèses validées / invalidées
- VALIDE : bascule du pont vers Roberto sans changement de lien appli ni perte des push.
- EN ATTENTE : tests manuels téléphone (aller-retour vocal par projet) — `Roberto/tests_manuels.md`.

## Prochaine étape exacte
Côté IA_Life : rien de bloquant (Phase 9 non définie). Hors zone : finir les tests manuels du
pont depuis le téléphone, supprimer le dossier vide `voice-code-bridge/`.

## Question bloquante pour la session suivante
Aucune.

<!-- Écrasé intégralement par /close. Synthèse < 25 lignes. -->
